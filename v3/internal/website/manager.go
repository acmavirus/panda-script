package website

import (
	"os"
	"path/filepath"
	"runtime"
	"text/template"
)

type Website struct {
	Domain string `json:"domain"`
	Port   int    `json:"port"`
	Root   string `json:"root"`
	SSL    bool   `json:"ssl"`
}

func ListWebsites() ([]Website, error) {
	configDir := "/etc/nginx/sites-available"
	if runtime.GOOS == "windows" {
		configDir = "nginx/sites-available"
		os.MkdirAll(configDir, 0755)
	}

	files, err := os.ReadDir(configDir)
	if err != nil {
		return []Website{}, err
	}

	var sites []Website
	for _, f := range files {
		if !f.IsDir() {
			sites = append(sites, Website{
				Domain: f.Name(),
				Port:   80, // Default, as parsing might be complex
				Root:   "/var/www/html",
				SSL:    false,
			})
		}
	}
	return sites, nil
}

func CreateWebsite(site Website) error {
	const configTmpl = `
server {
    listen {{.Port}};
    server_name {{.Domain}};
    root {{.Root}};
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
}
`
	t, err := template.New("nginx").Parse(configTmpl)
	if err != nil {
		return err
	}

	configDir := "/etc/nginx/sites-available"
	if runtime.GOOS == "windows" {
		configDir = "nginx/sites-available"
		os.MkdirAll(configDir, 0755)
	}

	f, err := os.Create(filepath.Join(configDir, site.Domain))
	if err != nil {
		return err
	}
	defer f.Close()

	return t.Execute(f, site)
}

func DeleteWebsite(domain string) error {
	configDir := "/etc/nginx/sites-available"
	if runtime.GOOS == "windows" {
		configDir = "nginx/sites-available"
	}
	return os.Remove(filepath.Join(configDir, domain))
}
