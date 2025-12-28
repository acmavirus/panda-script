package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/system"
	"github.com/gin-gonic/gin"
)

// ============================================================================
// WordPress Auto-Installer
// ============================================================================

func InstallWordPressHandler(c *gin.Context) {
	var req struct {
		Domain     string `json:"domain" binding:"required"`
		DbName     string `json:"db_name" binding:"required"`
		DbUser     string `json:"db_user" binding:"required"`
		DbPass     string `json:"db_pass" binding:"required"`
		SiteTitle  string `json:"site_title"`
		AdminUser  string `json:"admin_user"`
		AdminPass  string `json:"admin_pass"`
		AdminEmail string `json:"admin_email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "WordPress install requires Linux"})
		return
	}

	webRoot := "/home/" + req.Domain

	// Create directory
	system.Execute("mkdir -p " + webRoot)

	// Download WordPress
	_, err := system.Execute("cd " + webRoot + " && curl -sO https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to download WordPress"})
		return
	}

	// Create wp-config.php
	wpConfig := fmt.Sprintf(`<?php
define('DB_NAME', '%s');
define('DB_USER', '%s');
define('DB_PASSWORD', '%s');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( ! defined( 'ABSPATH' ) ) { define( 'ABSPATH', __DIR__ . '/' ); }
require_once ABSPATH . 'wp-settings.php';
`, req.DbName, req.DbUser, req.DbPass)

	os.WriteFile(webRoot+"/wp-config.php", []byte(wpConfig), 0644)

	// Set permissions
	system.Execute("chown -R www-data:www-data " + webRoot)
	system.Execute("chmod -R 755 " + webRoot)

	// Create database
	system.Execute(fmt.Sprintf("mysql -e \"CREATE DATABASE IF NOT EXISTS %s; CREATE USER IF NOT EXISTS '%s'@'localhost' IDENTIFIED BY '%s'; GRANT ALL ON %s.* TO '%s'@'localhost'; FLUSH PRIVILEGES;\"",
		req.DbName, req.DbUser, req.DbPass, req.DbName, req.DbUser))

	CreateNotification("success", "WordPress Installed", "WordPress installed for "+req.Domain)

	c.JSON(http.StatusOK, gin.H{"message": "WordPress installed successfully", "path": webRoot})
}

// ============================================================================
// WP-CLI Integration
// ============================================================================

func InstallWPCLIHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "WP-CLI requires Linux"})
		return
	}

	// Check if already installed
	if _, err := system.Execute("which wp"); err == nil {
		c.JSON(http.StatusOK, gin.H{"message": "WP-CLI already installed"})
		return
	}

	// Install WP-CLI
	cmds := []string{
		"curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar",
		"chmod +x wp-cli.phar",
		"mv wp-cli.phar /usr/local/bin/wp",
	}
	for _, cmd := range cmds {
		if _, err := system.Execute(cmd); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed: " + cmd})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "WP-CLI installed successfully"})
}

func ExecuteWPCLIHandler(c *gin.Context) {
	var req struct {
		Path    string `json:"path" binding:"required"`
		Command string `json:"command" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, gin.H{"output": "WP-CLI mock output"})
		return
	}

	cmd := fmt.Sprintf("cd %s && wp %s --allow-root", req.Path, req.Command)
	out, err := system.Execute(cmd)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error(), "output": out})
		return
	}

	c.JSON(http.StatusOK, gin.H{"output": out})
}

// ============================================================================
// Website Cloning
// ============================================================================

func CloneWebsiteHandler(c *gin.Context) {
	var req struct {
		SourceDomain string `json:"source_domain" binding:"required"`
		TargetDomain string `json:"target_domain" binding:"required"`
		CloneDB      bool   `json:"clone_db"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cloning requires Linux"})
		return
	}

	sourcePath := "/home/" + req.SourceDomain
	targetPath := "/home/" + req.TargetDomain

	// Clone files
	_, err := system.Execute(fmt.Sprintf("cp -r %s %s", sourcePath, targetPath))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clone files"})
		return
	}

	// Clone database if WordPress
	if req.CloneDB {
		sourceDB := strings.ReplaceAll(req.SourceDomain, ".", "_")
		targetDB := strings.ReplaceAll(req.TargetDomain, ".", "_")

		system.Execute(fmt.Sprintf("mysql -e 'CREATE DATABASE IF NOT EXISTS %s'", targetDB))
		system.Execute(fmt.Sprintf("mysqldump %s | mysql %s", sourceDB, targetDB))

		// Update wp-config.php
		wpConfig := targetPath + "/wp-config.php"
		if _, err := os.Stat(wpConfig); err == nil {
			content, _ := os.ReadFile(wpConfig)
			newContent := strings.ReplaceAll(string(content), sourceDB, targetDB)
			os.WriteFile(wpConfig, []byte(newContent), 0644)
		}
	}

	// Set permissions
	system.Execute("chown -R www-data:www-data " + targetPath)

	CreateNotification("success", "Website Cloned", req.SourceDomain+" → "+req.TargetDomain)

	c.JSON(http.StatusOK, gin.H{"message": "Website cloned successfully"})
}

// ============================================================================
// Node.js / PM2 Support
// ============================================================================

func InstallNodeJSHandler(c *gin.Context) {
	var req struct {
		Version string `json:"version"` // e.g., "20", "18", "lts"
	}
	c.ShouldBindJSON(&req)
	if req.Version == "" {
		req.Version = "20"
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	// Sourcing NVM command helper
	sourceNVM := "export NVM_DIR=\"$HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\""

	// 1. Install NVM if not exists
	if _, err := os.Stat(os.Getenv("HOME") + "/.nvm/nvm.sh"); os.IsNotExist(err) {
		system.Execute("curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash")
	}

	// 2. Install Node inside sourced environment
	installCmd := fmt.Sprintf("%s && nvm install %s && nvm use %s", sourceNVM, req.Version, req.Version)
	system.Execute(installCmd)

	// 3. Install PM2 globally inside sourced environment
	pm2Cmd := fmt.Sprintf("%s && npm install -g pm2", sourceNVM)
	system.Execute(pm2Cmd)

	c.JSON(http.StatusOK, gin.H{"message": "Node.js " + req.Version + " and PM2 installed successfully"})
}

func GetDevToolsStatusHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, gin.H{
			"wpcli":  false,
			"nodejs": false,
			"rclone": false,
			"clamav": false,
		})
		return
	}

	status := make(map[string]bool)

	// WP-CLI
	_, err := system.Execute("which wp")
	status["wpcli"] = (err == nil)

	// Node.js (check via nvm or which node)
	sourceNVM := "export NVM_DIR=\"$HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\""
	_, err = system.Execute(sourceNVM + " && node -v")
	status["nodejs"] = (err == nil)

	// Rclone
	_, err = system.Execute("which rclone")
	status["rclone"] = (err == nil)

	// ClamAV
	_, err = system.Execute("which clamscan")
	status["clamav"] = (err == nil)

	c.JSON(http.StatusOK, status)
}

func ListPM2ProcessesHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, []map[string]interface{}{})
		return
	}

	out, _ := system.Execute("pm2 jlist 2>/dev/null")

	var processes []map[string]interface{}
	json.Unmarshal([]byte(out), &processes)

	c.JSON(http.StatusOK, processes)
}

func PM2ActionHandler(c *gin.Context) {
	action := c.Param("action") // start, stop, restart, delete
	name := c.Param("name")

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	out, err := system.Execute(fmt.Sprintf("pm2 %s %s", action, name))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"output": out})
}

// ============================================================================
// Redis / Memcached
// ============================================================================

func InstallRedisHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	_, err := system.Execute("apt-get install -y redis-server && systemctl enable redis-server && systemctl start redis-server")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Redis installed and started"})
}

func InstallMemcachedHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	_, err := system.Execute("apt-get install -y memcached && systemctl enable memcached && systemctl start memcached")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Memcached installed and started"})
}

func GetRedisInfoHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, gin.H{"status": "mock", "version": "7.0"})
		return
	}

	out, _ := system.Execute("redis-cli INFO server 2>/dev/null | head -20")
	c.JSON(http.StatusOK, gin.H{"info": out})
}

// ============================================================================
// Cloud Backup (Rclone)
// ============================================================================

func InstallRcloneHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	_, err := system.Execute("curl https://rclone.org/install.sh | bash")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to install rclone"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Rclone installed"})
}

func ListRcloneRemotesHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, []string{})
		return
	}

	out, _ := system.Execute("rclone listremotes 2>/dev/null")
	remotes := strings.Split(strings.TrimSpace(out), "\n")
	c.JSON(http.StatusOK, remotes)
}

func SyncToCloudHandler(c *gin.Context) {
	var req struct {
		LocalPath  string `json:"local_path" binding:"required"`
		RemotePath string `json:"remote_path" binding:"required"` // e.g., "gdrive:backups"
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	cmd := fmt.Sprintf("rclone sync %s %s --progress", req.LocalPath, req.RemotePath)
	out, err := system.Execute(cmd)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error(), "output": out})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Sync completed", "output": out})
}

// ============================================================================
// Malware Scanner (ClamAV)
// ============================================================================

func InstallClamAVHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	_, err := system.Execute("apt-get install -y clamav clamav-daemon && freshclam")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "ClamAV installed"})
}

type ScanResult struct {
	Path          string `json:"path"`
	InfectedFiles int    `json:"infected_files"`
	ScannedFiles  int    `json:"scanned_files"`
	Output        string `json:"output"`
}

func ScanWebsiteHandler(c *gin.Context) {
	var req struct {
		Path string `json:"path" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, ScanResult{Path: req.Path, InfectedFiles: 0, ScannedFiles: 100})
		return
	}

	out, _ := system.Execute(fmt.Sprintf("clamscan -r %s --infected --no-summary 2>/dev/null | tail -50", req.Path))
	summary, _ := system.Execute(fmt.Sprintf("clamscan -r %s 2>/dev/null | tail -5", req.Path))

	result := ScanResult{
		Path:   req.Path,
		Output: out + "\n" + summary,
	}

	c.JSON(http.StatusOK, result)
}

// ============================================================================
// PHP Extension Manager
// ============================================================================

type PHPExtension struct {
	Name      string `json:"name"`
	Installed bool   `json:"installed"`
}

var commonExtensions = []string{
	"imagick", "gd", "intl", "zip", "bcmath", "soap", "xmlrpc",
	"opcache", "redis", "memcached", "apcu", "xdebug", "ioncube-loader",
}

func ListPHPExtensionsHandler(c *gin.Context) {
	version := c.Query("version")
	if version == "" {
		version = "8.3"
	}

	if runtime.GOOS == "windows" {
		var exts []PHPExtension
		for _, ext := range commonExtensions {
			exts = append(exts, PHPExtension{Name: ext, Installed: false})
		}
		c.JSON(http.StatusOK, exts)
		return
	}

	installed, _ := system.Execute(fmt.Sprintf("php%s -m 2>/dev/null", version))
	installedLower := strings.ToLower(installed)

	var exts []PHPExtension
	for _, ext := range commonExtensions {
		exts = append(exts, PHPExtension{
			Name:      ext,
			Installed: strings.Contains(installedLower, strings.ToLower(ext)),
		})
	}

	c.JSON(http.StatusOK, exts)
}

func InstallPHPExtensionHandler(c *gin.Context) {
	var req struct {
		Version   string `json:"version" binding:"required"`
		Extension string `json:"extension" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Requires Linux"})
		return
	}

	var cmd string
	if req.Extension == "ioncube-loader" {
		// Special handling for IonCube
		cmd = "cd /tmp && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xzf ioncube_loaders_lin_x86-64.tar.gz"
	} else {
		cmd = fmt.Sprintf("apt-get install -y php%s-%s", req.Version, req.Extension)
	}

	_, err := system.Execute(cmd)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Restart PHP-FPM
	system.Execute(fmt.Sprintf("systemctl restart php%s-fpm", req.Version))

	c.JSON(http.StatusOK, gin.H{"message": req.Extension + " installed for PHP " + req.Version})
}

// ============================================================================
// Panda Doctor (Health Check)
// ============================================================================

type HealthCheck struct {
	Category string `json:"category"`
	Name     string `json:"name"`
	Status   string `json:"status"` // ok, warning, critical
	Message  string `json:"message"`
	Value    string `json:"value"`
}

type HealthReport struct {
	Score       int           `json:"score"` // 0-100
	Checks      []HealthCheck `json:"checks"`
	GeneratedAt time.Time     `json:"generated_at"`
}

func HealthCheckHandler(c *gin.Context) {
	var checks []HealthCheck
	score := 100

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, HealthReport{Score: 100, Checks: checks, GeneratedAt: time.Now()})
		return
	}

	// 1. Disk Usage
	diskOut, _ := system.Execute("df -h / | tail -1 | awk '{print $5}'")
	diskUsage := strings.TrimSpace(strings.ReplaceAll(diskOut, "%", ""))
	diskPct, _ := strconv.Atoi(diskUsage)
	diskStatus := "ok"
	if diskPct > 90 {
		diskStatus = "critical"
		score -= 30
	} else if diskPct > 80 {
		diskStatus = "warning"
		score -= 10
	}
	checks = append(checks, HealthCheck{"Storage", "Disk Usage", diskStatus, "Root filesystem usage", diskUsage + "%"})

	// 2. Memory Usage
	memOut, _ := system.Execute("free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100}'")
	memPct, _ := strconv.Atoi(strings.TrimSpace(memOut))
	memStatus := "ok"
	if memPct > 95 {
		memStatus = "critical"
		score -= 20
	} else if memPct > 85 {
		memStatus = "warning"
		score -= 5
	}
	checks = append(checks, HealthCheck{"Memory", "RAM Usage", memStatus, "Memory utilization", strconv.Itoa(memPct) + "%"})

	// 3. Service Checks
	services := []string{"nginx", "mysql", "php8.3-fpm"}
	for _, svc := range services {
		out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", svc))
		status := strings.TrimSpace(out)
		checkStatus := "ok"
		if status != "active" {
			checkStatus = "critical"
			score -= 15
		}
		checks = append(checks, HealthCheck{"Services", svc, checkStatus, "Service status", status})
	}

	// 4. SSL Expiry (check first website)
	var websites []db.Website
	db.DB.Limit(1).Find(&websites)
	if len(websites) > 0 && websites[0].SSL {
		sslOut, _ := system.Execute(fmt.Sprintf("echo | openssl s_client -servername %s -connect %s:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2", websites[0].Domain, websites[0].Domain))
		if sslOut != "" {
			expiryDate, err := time.Parse("Jan _2 15:04:05 2006 MST", strings.TrimSpace(sslOut))
			if err == nil {
				daysLeft := int(expiryDate.Sub(time.Now()).Hours() / 24)
				sslStatus := "ok"
				if daysLeft < 7 {
					sslStatus = "critical"
					score -= 20
				} else if daysLeft < 30 {
					sslStatus = "warning"
					score -= 5
				}
				checks = append(checks, HealthCheck{"SSL", websites[0].Domain, sslStatus, "Days until expiry", strconv.Itoa(daysLeft) + " days"})
			}
		}
	}

	// 5. Port Exposure Check
	dangerousPorts := []string{"3306", "6379", "27017"}
	for _, port := range dangerousPorts {
		out, _ := system.Execute(fmt.Sprintf("ss -tlnp | grep ':%s ' | grep -v '127.0.0.1' | grep -v '::1'", port))
		if strings.TrimSpace(out) != "" {
			checks = append(checks, HealthCheck{"Security", "Port " + port, "warning", "Port exposed to internet", "open"})
			score -= 10
		}
	}

	if score < 0 {
		score = 0
	}

	c.JSON(http.StatusOK, HealthReport{
		Score:       score,
		Checks:      checks,
		GeneratedAt: time.Now(),
	})
}

// ============================================================================
// Auto-Heal Engine
// ============================================================================

type AutoHealConfig struct {
	Enabled       bool     `json:"enabled"`
	Services      []string `json:"services"`
	CheckInterval int      `json:"check_interval"` // seconds
	TelegramToken string   `json:"telegram_token"`
	TelegramChat  string   `json:"telegram_chat"`
}

func GetAutoHealConfigHandler(c *gin.Context) {
	var setting db.Setting
	db.DB.Where("key = ?", "autoheal_config").First(&setting)

	var config AutoHealConfig
	if setting.Value != "" {
		json.Unmarshal([]byte(setting.Value), &config)
	} else {
		config = AutoHealConfig{
			Enabled:       false,
			Services:      []string{"nginx", "mysql", "php8.3-fpm"},
			CheckInterval: 60,
		}
	}

	c.JSON(http.StatusOK, config)
}

func UpdateAutoHealConfigHandler(c *gin.Context) {
	var config AutoHealConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	configJSON, _ := json.Marshal(config)

	var setting db.Setting
	db.DB.Where("key = ?", "autoheal_config").First(&setting)
	if setting.ID == 0 {
		setting = db.Setting{Key: "autoheal_config", Value: string(configJSON)}
		db.DB.Create(&setting)
	} else {
		setting.Value = string(configJSON)
		db.DB.Save(&setting)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Auto-heal config saved"})
}

func RunAutoHealCheckHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, gin.H{"healed": []string{}})
		return
	}

	var setting db.Setting
	db.DB.Where("key = ?", "autoheal_config").First(&setting)

	var config AutoHealConfig
	json.Unmarshal([]byte(setting.Value), &config)

	var healed []string
	for _, svc := range config.Services {
		out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", svc))
		if strings.TrimSpace(out) != "active" {
			system.Execute(fmt.Sprintf("systemctl restart %s", svc))
			healed = append(healed, svc)

			CreateNotification("warning", "Service Auto-Healed", svc+" was down and has been restarted")

			// Send Telegram if configured
			if config.TelegramToken != "" && config.TelegramChat != "" {
				msg := fmt.Sprintf("🔧 Auto-Heal: %s was down and has been restarted", svc)
				system.Execute(fmt.Sprintf("curl -s -X POST 'https://api.telegram.org/bot%s/sendMessage' -d chat_id=%s -d text='%s'",
					config.TelegramToken, config.TelegramChat, msg))
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"healed": healed})
}

// Helper to get file size
func getFileSize(path string) int64 {
	info, err := os.Stat(path)
	if err != nil {
		return 0
	}
	return info.Size()
}

// Helper to get directory size
func getDirSize(path string) int64 {
	var size int64
	filepath.Walk(path, func(_ string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() {
			size += info.Size()
		}
		return nil
	})
	return size
}
