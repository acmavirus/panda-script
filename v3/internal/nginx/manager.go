package nginx

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

const (
	SitesAvailable = "/etc/nginx/sites-available"
	SitesEnabled   = "/etc/nginx/sites-enabled"
	WebRoot        = "/var/www"
)

type VhostConfig struct {
	Domain     string `json:"domain"`
	Root       string `json:"root"`
	PHPVersion string `json:"php_version"`
	SSLEnabled bool   `json:"ssl_enabled"`
	CertPath   string `json:"cert_path,omitempty"`
	Port       int    `json:"port"`
}

func getSitesAvailable() string {
	if runtime.GOOS == "windows" {
		return "nginx/sites-available"
	}
	return SitesAvailable
}

func getSitesEnabled() string {
	if runtime.GOOS == "windows" {
		return "nginx/sites-enabled"
	}
	return SitesEnabled
}

func getWebRoot() string {
	if runtime.GOOS == "windows" {
		return "www"
	}
	return WebRoot
}

func init() {
	os.MkdirAll(getSitesAvailable(), 0755)
	os.MkdirAll(getSitesEnabled(), 0755)
}

const vhostTemplate = `server {
    listen {{.Port}};
    listen [::]:{{.Port}};
    
    server_name {{.Domain}} www.{{.Domain}};
    root {{.Root}};
    index index.php index.html;
    
    access_log /var/www/{{.Domain}}/logs/access.log;
    error_log /var/www/{{.Domain}}/logs/error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php{{.PHPVersion}}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\. {
        deny all;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
`

const vhostSSLTemplate = `server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name {{.Domain}} www.{{.Domain}};
    root {{.Root}};
    index index.php index.html;
    
    ssl_certificate {{.CertPath}}/fullchain.pem;
    ssl_certificate_key {{.CertPath}}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php{{.PHPVersion}}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

server {
    listen 80;
    server_name {{.Domain}} www.{{.Domain}};
    return 301 https://$server_name$request_uri;
}
`

// CreateVhost creates a new nginx virtual host
func CreateVhost(config VhostConfig) error {
	if config.PHPVersion == "" {
		config.PHPVersion = "8.3"
	}
	if config.Port == 0 {
		config.Port = 80
	}
	if config.Root == "" {
		config.Root = filepath.Join(getWebRoot(), config.Domain, "public")
	}

	// Create directories
	webDir := filepath.Join(getWebRoot(), config.Domain)
	os.MkdirAll(config.Root, 0755)
	os.MkdirAll(filepath.Join(webDir, "logs"), 0755)

	// Choose template
	tmplString := vhostTemplate
	if config.SSLEnabled && config.CertPath != "" {
		tmplString = vhostSSLTemplate
	}

	tmpl, err := template.New("vhost").Parse(tmplString)
	if err != nil {
		return fmt.Errorf("template parse error: %v", err)
	}

	// Create config file
	configPath := filepath.Join(getSitesAvailable(), config.Domain)
	f, err := os.Create(configPath)
	if err != nil {
		return fmt.Errorf("failed to create config file: %v", err)
	}
	defer f.Close()

	if err := tmpl.Execute(f, config); err != nil {
		return fmt.Errorf("template execute error: %v", err)
	}

	// Enable site (symlink)
	enabledPath := filepath.Join(getSitesEnabled(), config.Domain)
	os.Remove(enabledPath) // Remove existing if any
	if runtime.GOOS != "windows" {
		os.Symlink(configPath, enabledPath)
	} else {
		// On Windows, copy the file
		content, _ := os.ReadFile(configPath)
		os.WriteFile(enabledPath, content, 0644)
	}

	// Test and reload nginx
	if err := TestConfig(); err != nil {
		// Rollback
		os.Remove(configPath)
		os.Remove(enabledPath)
		return fmt.Errorf("nginx config test failed: %v", err)
	}

	Reload()

	// Create default index.php
	indexPath := filepath.Join(config.Root, "index.php")
	if _, err := os.Stat(indexPath); os.IsNotExist(err) {
		os.WriteFile(indexPath, []byte("<?php phpinfo();"), 0644)
	}

	// Set permissions on Linux
	if runtime.GOOS != "windows" {
		system.Execute(fmt.Sprintf("chown -R www-data:www-data %s", webDir))
	}

	return nil
}

// DeleteVhost removes a virtual host
func DeleteVhost(domain string) error {
	configPath := filepath.Join(getSitesAvailable(), domain)
	enabledPath := filepath.Join(getSitesEnabled(), domain)

	os.Remove(enabledPath)
	os.Remove(configPath)

	// Also remove SSL version if exists
	os.Remove(filepath.Join(getSitesEnabled(), domain+"-ssl"))
	os.Remove(filepath.Join(getSitesAvailable(), domain+"-ssl"))

	Reload()
	return nil
}

// ListVhosts returns all configured virtual hosts
func ListVhosts() ([]VhostConfig, error) {
	sitesDir := getSitesAvailable()

	files, err := os.ReadDir(sitesDir)
	if err != nil {
		return []VhostConfig{}, nil
	}

	var vhosts []VhostConfig
	for _, file := range files {
		if file.IsDir() || file.Name() == "default" {
			continue
		}

		// Skip SSL duplicates
		if strings.HasSuffix(file.Name(), "-ssl") {
			continue
		}

		vhost := VhostConfig{
			Domain:     file.Name(),
			Root:       filepath.Join(getWebRoot(), file.Name(), "public"),
			PHPVersion: "8.3",
			Port:       80,
		}

		// Check if SSL is enabled
		sslPath := filepath.Join(getSitesEnabled(), file.Name()+"-ssl")
		if _, err := os.Stat(sslPath); err == nil {
			vhost.SSLEnabled = true
		}

		// Check if enabled
		enabledPath := filepath.Join(getSitesEnabled(), file.Name())
		if _, err := os.Stat(enabledPath); err != nil {
			continue // Not enabled
		}

		vhosts = append(vhosts, vhost)
	}

	return vhosts, nil
}

// GetVhost returns details of a specific virtual host
func GetVhost(domain string) (*VhostConfig, error) {
	configPath := filepath.Join(getSitesAvailable(), domain)

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("virtual host not found: %s", domain)
	}

	vhost := &VhostConfig{
		Domain:     domain,
		Root:       filepath.Join(getWebRoot(), domain, "public"),
		PHPVersion: "8.3",
		Port:       80,
	}

	// Check SSL
	sslPath := filepath.Join(getSitesEnabled(), domain+"-ssl")
	if _, err := os.Stat(sslPath); err == nil {
		vhost.SSLEnabled = true
		vhost.CertPath = fmt.Sprintf("/etc/letsencrypt/live/%s", domain)
	}

	return vhost, nil
}

// EnableSSL enables SSL for a virtual host
func EnableSSL(domain, certPath string) error {
	if certPath == "" {
		certPath = fmt.Sprintf("/etc/letsencrypt/live/%s", domain)
	}

	vhost, err := GetVhost(domain)
	if err != nil {
		return err
	}

	vhost.SSLEnabled = true
	vhost.CertPath = certPath

	// Create SSL config
	tmpl, err := template.New("vhost-ssl").Parse(vhostSSLTemplate)
	if err != nil {
		return err
	}

	sslConfigPath := filepath.Join(getSitesAvailable(), domain+"-ssl")
	f, err := os.Create(sslConfigPath)
	if err != nil {
		return err
	}
	defer f.Close()

	if err := tmpl.Execute(f, vhost); err != nil {
		return err
	}

	// Enable SSL config
	sslEnabledPath := filepath.Join(getSitesEnabled(), domain+"-ssl")
	os.Remove(sslEnabledPath)
	if runtime.GOOS != "windows" {
		os.Symlink(sslConfigPath, sslEnabledPath)
	} else {
		content, _ := os.ReadFile(sslConfigPath)
		os.WriteFile(sslEnabledPath, content, 0644)
	}

	return Reload()
}

// DisableSSL disables SSL for a virtual host
func DisableSSL(domain string) error {
	os.Remove(filepath.Join(getSitesEnabled(), domain+"-ssl"))
	os.Remove(filepath.Join(getSitesAvailable(), domain+"-ssl"))
	return Reload()
}

// TestConfig tests the nginx configuration
func TestConfig() error {
	if runtime.GOOS == "windows" {
		return nil // Skip on Windows
	}

	out, err := system.Execute("nginx -t 2>&1")
	if err != nil || !strings.Contains(out, "successful") {
		return fmt.Errorf("nginx config test failed: %s", out)
	}
	return nil
}

// Reload reloads nginx configuration
func Reload() error {
	if runtime.GOOS == "windows" {
		return nil
	}

	_, err := system.Execute("systemctl reload nginx")
	return err
}

// Restart restarts nginx service
func Restart() error {
	if runtime.GOOS == "windows" {
		return nil
	}

	_, err := system.Execute("systemctl restart nginx")
	return err
}

// GetStatus returns nginx service status
func GetStatus() (string, error) {
	if runtime.GOOS == "windows" {
		return "mock", nil
	}

	out, _ := system.Execute("systemctl is-active nginx")
	return strings.TrimSpace(out), nil
}
