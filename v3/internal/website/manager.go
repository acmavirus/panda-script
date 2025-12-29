package website

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"text/template"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

var sslMutex sync.Mutex

type Website struct {
	Domain     string `json:"domain"`
	Port       int    `json:"port"`
	Root       string `json:"root"`
	SSL        bool   `json:"ssl"`
	SSLExpiry  string `json:"ssl_expiry,omitempty"`
	PHPVer     string `json:"php_version"`
	Status     string `json:"status"`
	StatusCode int    `json:"status_code"`
	HasDB      bool   `json:"has_db"`
}

func ListWebsites() ([]Website, error) {
	enabledDir := "/etc/nginx/sites-enabled"
	if runtime.GOOS == "windows" {
		enabledDir = "nginx/sites-enabled"
		os.MkdirAll(enabledDir, 0755)
	}

	files, err := os.ReadDir(enabledDir)
	if err != nil {
		return []Website{}, nil
	}

	var sites []Website
	for _, f := range files {
		if f.IsDir() || f.Name() == "default" {
			continue
		}

		// Skip system app configs (not websites)
		if f.Name() == "phpmyadmin.conf" || f.Name() == "panda.conf" {
			continue
		}

		domain := strings.TrimSuffix(f.Name(), ".conf")
		root := "/home/" + domain

		// Check if directory exists
		status := "active"
		if _, err := os.Stat(root); os.IsNotExist(err) {
			status = "no_directory"
		}

		// Check SSL status
		hasSSL := false
		sslExpiry := ""
		if runtime.GOOS != "windows" {
			certPath := fmt.Sprintf("/etc/letsencrypt/live/%s/fullchain.pem", domain)
			if _, err := os.Stat(certPath); err == nil {
				hasSSL = true
				// Get expiry date
				out, _ := system.Execute(fmt.Sprintf("openssl x509 -enddate -noout -in %s 2>/dev/null | cut -d= -f2", certPath))
				sslExpiry = strings.TrimSpace(out)
			}
		}

		// Check for DB
		hasDB := false
		dbName := strings.ReplaceAll(domain, ".", "_")
		dbName = strings.ReplaceAll(dbName, "-", "_")
		if checkMySQLDatabaseExists(dbName) {
			hasDB = true
		}

		sites = append(sites, Website{
			Domain:    domain,
			Port:      80,
			Root:      root,
			SSL:       hasSSL,
			SSLExpiry: sslExpiry,
			Status:    status,
			HasDB:     hasDB,
		})
	}

	// Fetch status codes concurrently
	var wg sync.WaitGroup
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{
		Timeout:   5 * time.Second,
		Transport: tr,
		// Follow redirects to see the final destination status
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 5 {
				return fmt.Errorf("stopped after 5 redirects")
			}
			return nil
		},
	}

	for i := range sites {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()

			// Try HTTPS first if it has SSL, otherwise HTTP
			protocol := "http://"
			if sites[idx].SSL {
				protocol = "https://"
			}

			url := protocol + sites[idx].Domain
			resp, err := client.Get(url)
			if err != nil {
				// If HTTPS failed but we haven't tried HTTP yet, try HTTP
				if protocol == "https://" {
					resp, err = client.Get("http://" + sites[idx].Domain)
				}
			}

			if err == nil && resp != nil {
				sites[idx].StatusCode = resp.StatusCode
				resp.Body.Close()
			}
		}(i)
	}
	wg.Wait()

	return sites, nil
}

func CreateWebsite(site Website) error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("website creation requires Linux")
	}

	// Default values
	if site.Port == 0 {
		site.Port = 80
	}
	if site.Root == "" {
		site.Root = "/home/" + site.Domain
	}

	// 1. Create web root directory
	if err := os.MkdirAll(site.Root, 0755); err != nil {
		return fmt.Errorf("failed to create web root: %v", err)
	}

	// 2. Create default index.html
	indexContent := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
    <title>Welcome to %s</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; }
        .container { text-align: center; }
        h1 { font-size: 3em; margin-bottom: 0.5em; }
        p { font-size: 1.2em; opacity: 0.9; }
        .logo { font-size: 5em; margin-bottom: 0.3em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🐼</div>
        <h1>%s</h1>
        <p>Your website is ready! Managed by Panda Panel.</p>
    </div>
</body>
</html>`, site.Domain, site.Domain)

	indexPath := filepath.Join(site.Root, "index.html")
	if err := os.WriteFile(indexPath, []byte(indexContent), 0644); err != nil {
		return fmt.Errorf("failed to create index.html: %v", err)
	}

	// 3. Create Nginx config
	const configTmpl = `server {
    listen 80;
    listen [::]:80;
    server_name {{.Domain}} www.{{.Domain}};
    root {{.Root}};
    index index.php index.html index.htm;

    access_log /var/log/nginx/{{.Domain}}.access.log;
    error_log /var/log/nginx/{{.Domain}}.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
`
	t, err := template.New("nginx").Parse(configTmpl)
	if err != nil {
		return err
	}

	configDir := "/etc/nginx/sites-available"
	configFile := filepath.Join(configDir, site.Domain+".conf")

	f, err := os.Create(configFile)
	if err != nil {
		return fmt.Errorf("failed to create nginx config: %v", err)
	}
	defer f.Close()

	if err := t.Execute(f, site); err != nil {
		return fmt.Errorf("failed to write nginx config: %v", err)
	}

	// 4. Enable site (create symlink)
	enabledDir := "/etc/nginx/sites-enabled"
	symlink := filepath.Join(enabledDir, site.Domain+".conf")
	os.Remove(symlink) // Remove if exists
	if err := os.Symlink(configFile, symlink); err != nil {
		return fmt.Errorf("failed to enable site: %v", err)
	}

	// 5. Reload nginx
	if _, err := system.Execute("systemctl reload nginx"); err != nil {
		return fmt.Errorf("failed to reload nginx: %v", err)
	}

	// 6. Create index.php if it doesn't exist
	phpPath := filepath.Join(site.Root, "index.php")
	if _, err := os.Stat(phpPath); os.IsNotExist(err) {
		phpContent := fmt.Sprintf("<?php phpinfo(); ?>")
		os.WriteFile(phpPath, []byte(phpContent), 0644)
	}

	// 7. Create SSL if requested
	if site.SSL {
		if err := CreateSSL(site.Domain); err != nil {
			// SSL creation failed but website is created
			// Log error but don't fail the entire operation
			fmt.Printf("SSL creation failed for %s: %v\n", site.Domain, err)
		}
	}

	return nil
}

// CreateSSL creates/renews SSL certificate for a domain using Let's Encrypt
func CreateSSL(domain string) error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("SSL creation requires Linux")
	}

	sslMutex.Lock()
	defer sslMutex.Unlock()

	// Check if certbot is installed
	if _, err := system.Execute("which certbot"); err != nil {
		// Install certbot
		if _, err := system.Execute("apt-get update && apt-get install -y certbot python3-certbot-nginx"); err != nil {
			return fmt.Errorf("failed to install certbot: %v", err)
		}
	}

	// Run certbot
	cmd := fmt.Sprintf("certbot --nginx -d %s -d www.%s --non-interactive --agree-tos --email admin@%s --redirect", domain, domain, domain)
	out, err := system.Execute(cmd)
	if err != nil {
		return fmt.Errorf("certbot failed: %s - %v", out, err)
	}

	return nil
}

// RenewSSL renews all SSL certificates
func RenewSSL() error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("SSL renewal requires Linux")
	}

	sslMutex.Lock()
	defer sslMutex.Unlock()

	out, err := system.Execute("certbot renew --quiet")
	if err != nil {
		return fmt.Errorf("certbot renew failed: %s - %v", out, err)
	}

	return nil
}

func DeleteWebsite(domain string) error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("website deletion requires Linux")
	}

	// Remove symlink (enabled site)
	os.Remove(filepath.Join("/etc/nginx/sites-enabled", domain+".conf"))
	os.Remove(filepath.Join("/etc/nginx/sites-enabled", domain))

	// Remove config file
	os.Remove(filepath.Join("/etc/nginx/sites-available", domain+".conf"))
	os.Remove(filepath.Join("/etc/nginx/sites-available", domain))

	// Reload nginx
	system.Execute("systemctl reload nginx")

	// NOTE: Web root and SSL certs are NOT deleted for safety
	return nil
}
func checkMySQLDatabaseExists(name string) bool {
	// We need to use mysql command
	cmd := fmt.Sprintf("mysql -uroot -e \"SHOW DATABASES LIKE '%s';\" -N", name)
	out, err := system.Execute(cmd)
	if err == nil && strings.TrimSpace(out) == name {
		return true
	}

	// Try docker if native failed
	cmd = fmt.Sprintf("docker exec panda-mysql mysql -uroot -proot -e \"SHOW DATABASES LIKE '%s';\" -N", name)
	out, err = system.Execute(cmd)
	if err == nil && strings.TrimSpace(out) == name {
		return true
	}

	return false
}
