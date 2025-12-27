package api

import (
	"net/http"
	"os"
	"runtime"

	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/system"
	"github.com/gin-gonic/gin"
)

// ============================================================================
// Panel SSL
// ============================================================================

func EnablePanelSSLHandler(c *gin.Context) {
	var req struct {
		Domain string `json:"domain" binding:"required"`
		Email  string `json:"email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Panel SSL requires Linux"})
		return
	}

	// Get SSL certificate using certbot
	certCmd := "certbot certonly --nginx -d " + req.Domain + " --non-interactive --agree-tos"
	if req.Email != "" {
		certCmd += " --email " + req.Email
	} else {
		certCmd += " --register-unsafely-without-email"
	}

	_, err := system.Execute(certCmd)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to obtain SSL: " + err.Error()})
		return
	}

	// Update Nginx config for panel
	nginxConf := `server {
    listen 80;
    server_name ` + req.Domain + `;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ` + req.Domain + `;
    
    ssl_certificate /etc/letsencrypt/live/` + req.Domain + `/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/` + req.Domain + `/privkey.pem;
    
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    location /panda {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
`
	configPath := "/etc/nginx/sites-available/panda-panel"
	os.WriteFile(configPath, []byte(nginxConf), 0644)

	// Enable and reload
	system.Execute("ln -sf " + configPath + " /etc/nginx/sites-enabled/panda-panel")
	system.Execute("nginx -t && systemctl reload nginx")

	// Save setting
	var setting db.Setting
	db.DB.Where("key = ?", "panel_ssl_domain").First(&setting)
	if setting.ID == 0 {
		db.DB.Create(&db.Setting{Key: "panel_ssl_domain", Value: req.Domain})
	} else {
		setting.Value = req.Domain
		db.DB.Save(&setting)
	}

	CreateNotification("success", "Panel SSL Enabled", "SSL certificate installed for "+req.Domain)

	c.JSON(http.StatusOK, gin.H{"message": "Panel SSL enabled", "domain": req.Domain})
}

func GetPanelSSLStatusHandler(c *gin.Context) {
	var setting db.Setting
	db.DB.Where("key = ?", "panel_ssl_domain").First(&setting)

	if setting.ID == 0 || setting.Value == "" {
		c.JSON(http.StatusOK, gin.H{"enabled": false})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"enabled": true,
		"domain":  setting.Value,
	})
}

// ============================================================================
// Theme Settings
// ============================================================================

func GetThemeHandler(c *gin.Context) {
	var setting db.Setting
	db.DB.Where("key = ?", "theme").First(&setting)

	theme := "dark" // default
	if setting.Value != "" {
		theme = setting.Value
	}

	c.JSON(http.StatusOK, gin.H{"theme": theme})
}

func SetThemeHandler(c *gin.Context) {
	var req struct {
		Theme string `json:"theme" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Theme != "dark" && req.Theme != "light" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Theme must be 'dark' or 'light'"})
		return
	}

	var setting db.Setting
	db.DB.Where("key = ?", "theme").First(&setting)
	if setting.ID == 0 {
		db.DB.Create(&db.Setting{Key: "theme", Value: req.Theme})
	} else {
		setting.Value = req.Theme
		db.DB.Save(&setting)
	}

	c.JSON(http.StatusOK, gin.H{"theme": req.Theme})
}
