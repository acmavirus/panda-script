package website

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"text/template"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type Website struct {
	Domain string `json:"domain"`
	Port   int    `json:"port"`
	Root   string `json:"root"`
	SSL    bool   `json:"ssl"`
	PHPVer string `json:"php_version"`
	Status string `json:"status"`
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

		domain := strings.TrimSuffix(f.Name(), ".conf")
		root := "/home/" + domain

		// Check if directory exists
		status := "active"
		if _, err := os.Stat(root); os.IsNotExist(err) {
			status = "no_directory"
		}

		sites = append(sites, Website{
			Domain: domain,
			Port:   80,
			Root:   root,
			SSL:    false,
			Status: status,
		})
	}
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
	enabledFile := filepath.Join(enabledDir, site.Domain+".conf")

	// Remove existing symlink if any
	os.Remove(enabledFile)

	if err := os.Symlink(configFile, enabledFile); err != nil {
		return fmt.Errorf("failed to enable site: %v", err)
	}

	// 5. Set permissions
	system.Execute(fmt.Sprintf("chown -R www-data:www-data %s", site.Root))
	system.Execute(fmt.Sprintf("chmod -R 755 %s", site.Root))

	// 6. Test and reload nginx
	if out, err := system.Execute("nginx -t"); err != nil {
		return fmt.Errorf("nginx config test failed: %s", out)
	}

	if _, err := system.Execute("systemctl reload nginx"); err != nil {
		return fmt.Errorf("failed to reload nginx: %v", err)
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

	// NOTE: Web root is NOT deleted for safety
	return nil
}
