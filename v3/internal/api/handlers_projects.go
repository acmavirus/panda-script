package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// ============================================
// CMS Installer Handlers
// ============================================

type CMSInstallRequest struct {
	Domain  string `json:"domain" binding:"required"`
	CMSType string `json:"cms_type" binding:"required"`
}

type CMSResponse struct {
	Success  bool   `json:"success"`
	Message  string `json:"message"`
	Domain   string `json:"domain,omitempty"`
	DBName   string `json:"db_name,omitempty"`
	DBUser   string `json:"db_user,omitempty"`
	DBPass   string `json:"db_pass,omitempty"`
	AdminURL string `json:"admin_url,omitempty"`
}

// ListCMSHandler - List available CMS
func ListCMSHandler(c *gin.Context) {
	cmsList := []map[string]string{
		{"slug": "wordpress", "name": "WordPress", "icon": "📝", "description": "Most popular CMS"},
		{"slug": "woocommerce", "name": "WooCommerce", "icon": "🛒", "description": "E-commerce for WordPress"},
		{"slug": "joomla", "name": "Joomla", "icon": "🎨", "description": "Flexible CMS"},
		{"slug": "drupal", "name": "Drupal", "icon": "💧", "description": "Enterprise CMS"},
		{"slug": "prestashop", "name": "PrestaShop", "icon": "🛍️", "description": "E-commerce platform"},
		{"slug": "opencart", "name": "OpenCart", "icon": "🎯", "description": "E-commerce solution"},
		{"slug": "mediawiki", "name": "MediaWiki", "icon": "📚", "description": "Wiki platform"},
		{"slug": "phpbb", "name": "phpBB", "icon": "💬", "description": "Forum software"},
		{"slug": "phpmyadmin", "name": "phpMyAdmin", "icon": "🗃️", "description": "MySQL management"},
	}
	c.JSON(200, gin.H{"cms": cmsList})
}

// InstallCMSHandler - Install CMS
func InstallCMSHandler(c *gin.Context) {
	var req CMSInstallRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Run CLI installer with /home path
	cmd := exec.Command("bash", "-c", fmt.Sprintf(
		"source /opt/panda/modules/website/cms_installer.sh && install_cms %s <<< '%s'",
		req.CMSType, req.Domain,
	))
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	// Send notification
	SendNotification("CMS Installed", fmt.Sprintf("%s installed on %s", req.CMSType, req.Domain), "success")

	c.JSON(200, CMSResponse{
		Success:  true,
		Message:  fmt.Sprintf("%s installed successfully", req.CMSType),
		Domain:   req.Domain,
		AdminURL: fmt.Sprintf("http://%s", req.Domain),
	})
}

// ============================================
// Python Project Handlers
// ============================================

type ProjectRequest struct {
	Name      string `json:"name" binding:"required"`
	Domain    string `json:"domain"`
	Port      int    `json:"port"`
	Framework string `json:"framework"`
	RepoURL   string `json:"repo_url"`
}

type ProjectResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Project interface{} `json:"project,omitempty"`
}

type PythonProject struct {
	Name      string `json:"name"`
	Framework string `json:"framework"`
	Port      int    `json:"port"`
	Domain    string `json:"domain"`
	Status    string `json:"status"`
	Path      string `json:"path"`
	Created   string `json:"created"`
}

// ListPythonProjectsHandler - List all Python projects
func ListPythonProjectsHandler(c *gin.Context) {
	projects := []PythonProject{}
	projectsDir := "/home/python-apps"

	entries, err := os.ReadDir(projectsDir)
	if err != nil {
		c.JSON(200, gin.H{"projects": projects})
		return
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		configPath := filepath.Join(projectsDir, entry.Name(), ".panda-project")
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			continue
		}

		project := PythonProject{
			Name: entry.Name(),
			Path: filepath.Join(projectsDir, entry.Name()),
		}

		configData, _ := os.ReadFile(configPath)
		for _, line := range strings.Split(string(configData), "\n") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}
			switch parts[0] {
			case "FRAMEWORK":
				project.Framework = parts[1]
			case "PORT":
				fmt.Sscanf(parts[1], "%d", &project.Port)
			case "DOMAIN":
				project.Domain = parts[1]
			case "CREATED":
				project.Created = parts[1]
			}
		}

		cmd := exec.Command("systemctl", "is-active", fmt.Sprintf("python-%s", entry.Name()))
		output, _ := cmd.Output()
		project.Status = strings.TrimSpace(string(output))
		if project.Status == "" {
			project.Status = "stopped"
		}

		projects = append(projects, project)
	}

	c.JSON(200, gin.H{"projects": projects})
}

// CreatePythonProjectHandler - Create Python project
func CreatePythonProjectHandler(c *gin.Context) {
	var req ProjectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if req.Port == 0 {
		req.Port = 8000
	}
	if req.Framework == "" {
		req.Framework = "fastapi"
	}

	script := fmt.Sprintf(`
source /opt/panda/modules/project/python.sh
create_python_project_api "%s" "%s" %d "%s"
`, req.Name, req.Domain, req.Port, req.Framework)

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	SendNotification("Project Created", fmt.Sprintf("Python project %s created", req.Name), "success")

	c.JSON(200, ProjectResponse{
		Success: true,
		Message: "Python project created successfully",
	})
}

// ManagePythonProjectHandler - Start/Stop/Restart Python project
func ManagePythonProjectHandler(c *gin.Context) {
	name := c.Param("name")
	action := c.Param("action")

	if action != "start" && action != "stop" && action != "restart" {
		c.JSON(400, gin.H{"error": "Invalid action. Use start, stop, or restart"})
		return
	}

	cmd := exec.Command("systemctl", action, fmt.Sprintf("python-%s", name))
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	c.JSON(200, gin.H{"success": true, "message": fmt.Sprintf("Python project %s: %s", name, action)})
}

// DeletePythonProjectHandler - Delete Python project
func DeletePythonProjectHandler(c *gin.Context) {
	name := c.Param("name")
	projectDir := filepath.Join("/home/python-apps", name)

	exec.Command("systemctl", "stop", fmt.Sprintf("python-%s", name)).Run()
	exec.Command("systemctl", "disable", fmt.Sprintf("python-%s", name)).Run()
	os.Remove(fmt.Sprintf("/etc/systemd/system/python-%s.service", name))
	exec.Command("systemctl", "daemon-reload").Run()
	os.RemoveAll(projectDir)

	c.JSON(200, gin.H{"success": true, "message": "Project deleted"})
}

// ============================================
// Java Project Handlers
// ============================================

type JavaProject struct {
	Name    string `json:"name"`
	Type    string `json:"type"`
	Port    int    `json:"port"`
	Domain  string `json:"domain"`
	Status  string `json:"status"`
	Path    string `json:"path"`
	Created string `json:"created"`
}

// ListJavaProjectsHandler - List Java projects
func ListJavaProjectsHandler(c *gin.Context) {
	projects := []JavaProject{}
	projectsDir := "/home/java-apps"

	entries, err := os.ReadDir(projectsDir)
	if err != nil {
		c.JSON(200, gin.H{"projects": projects})
		return
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		configPath := filepath.Join(projectsDir, entry.Name(), ".panda-project")
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			continue
		}

		project := JavaProject{
			Name: entry.Name(),
			Path: filepath.Join(projectsDir, entry.Name()),
		}

		configData, _ := os.ReadFile(configPath)
		for _, line := range strings.Split(string(configData), "\n") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}
			switch parts[0] {
			case "TYPE":
				project.Type = parts[1]
			case "PORT":
				fmt.Sscanf(parts[1], "%d", &project.Port)
			case "DOMAIN":
				project.Domain = parts[1]
			case "CREATED":
				project.Created = parts[1]
			}
		}

		cmd := exec.Command("systemctl", "is-active", fmt.Sprintf("java-%s", entry.Name()))
		output, _ := cmd.Output()
		project.Status = strings.TrimSpace(string(output))
		if project.Status == "" {
			project.Status = "stopped"
		}

		projects = append(projects, project)
	}

	c.JSON(200, gin.H{"projects": projects})
}

// CreateJavaProjectHandler - Create Java project
func CreateJavaProjectHandler(c *gin.Context) {
	var req ProjectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if req.Port == 0 {
		req.Port = 8080
	}

	script := fmt.Sprintf(`
cd /home/java-apps 2>/dev/null || mkdir -p /home/java-apps
source /opt/panda/modules/project/java.sh
create_java_project_noninteractive "%s" "%s" %d
`, req.Name, req.Domain, req.Port)

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	SendNotification("Project Created", fmt.Sprintf("Java project %s created", req.Name), "success")

	c.JSON(200, ProjectResponse{
		Success: true,
		Message: "Java project created successfully",
	})
}

// ManageJavaProjectHandler - Manage Java project
func ManageJavaProjectHandler(c *gin.Context) {
	name := c.Param("name")
	action := c.Param("action")

	cmd := exec.Command("systemctl", action, fmt.Sprintf("java-%s", name))
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	c.JSON(200, gin.H{"success": true, "message": fmt.Sprintf("Java project %s: %s", name, action)})
}

// ============================================
// Deployment Workflow Handlers
// ============================================

type Deployment struct {
	Name        string `json:"name"`
	RepoURL     string `json:"repo_url"`
	Branch      string `json:"branch"`
	DeployPath  string `json:"deploy_path"`
	ProjectType string `json:"project_type"`
	AutoDeploy  bool   `json:"auto_deploy"`
	Secret      string `json:"secret,omitempty"`
	Created     string `json:"created"`
}

type DeploymentRequest struct {
	Name        string `json:"name" binding:"required"`
	RepoURL     string `json:"repo_url" binding:"required"`
	Branch      string `json:"branch"`
	DeployPath  string `json:"deploy_path"`
	ProjectType string `json:"project_type"`
}

// ListDeploymentsHandler - List deployments
func ListDeploymentsHandler(c *gin.Context) {
	deployments := []Deployment{}
	configDir := "/etc/panda/deployments"

	entries, err := os.ReadDir(configDir)
	if err != nil {
		c.JSON(200, gin.H{"deployments": deployments})
		return
	}

	for _, entry := range entries {
		if !strings.HasSuffix(entry.Name(), ".conf") {
			continue
		}

		configPath := filepath.Join(configDir, entry.Name())
		configData, err := os.ReadFile(configPath)
		if err != nil {
			continue
		}

		deployment := Deployment{}
		for _, line := range strings.Split(string(configData), "\n") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}
			switch parts[0] {
			case "DEPLOY_NAME":
				deployment.Name = parts[1]
			case "REPO_URL":
				deployment.RepoURL = parts[1]
			case "BRANCH":
				deployment.Branch = parts[1]
			case "DEPLOY_PATH":
				deployment.DeployPath = parts[1]
			case "PROJECT_TYPE":
				deployment.ProjectType = parts[1]
			case "AUTO_DEPLOY":
				deployment.AutoDeploy = parts[1] == "true"
			case "CREATED":
				deployment.Created = parts[1]
			}
		}

		deployments = append(deployments, deployment)
	}

	c.JSON(200, gin.H{"deployments": deployments})
}

// CreateDeploymentHandler - Setup new deployment
func CreateDeploymentHandler(c *gin.Context) {
	var req DeploymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if req.Branch == "" {
		req.Branch = "main"
	}
	if req.DeployPath == "" {
		req.DeployPath = "/home"
	}
	if req.ProjectType == "" {
		req.ProjectType = "php"
	}

	script := fmt.Sprintf(`
source /opt/panda/modules/deploy/workflow.sh
setup_deployment_api "%s" "%s" "%s" "%s" "%s"
`, req.Name, req.RepoURL, req.Branch, req.DeployPath, req.ProjectType)

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	SendNotification("Deployment Created", fmt.Sprintf("Deployment %s configured", req.Name), "info")

	c.JSON(200, gin.H{
		"success": true,
		"message": "Deployment configured successfully",
	})
}

// TriggerDeployHandler - Trigger deployment
func TriggerDeployHandler(c *gin.Context) {
	name := c.Param("name")

	cmd := exec.Command("bash", "-c", fmt.Sprintf(
		"source /opt/panda/modules/deploy/workflow.sh && deploy_by_name %s",
		name,
	))
	output, err := cmd.CombinedOutput()

	if err != nil {
		SendNotification("Deployment Failed", fmt.Sprintf("Deployment %s failed", name), "error")
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	SendNotification("Deployment Success", fmt.Sprintf("Deployment %s completed", name), "success")

	c.JSON(200, gin.H{
		"success": true,
		"message": "Deployment triggered",
		"output":  string(output),
	})
}

// GetDeployLogsHandler - Get deployment logs
func GetDeployLogsHandler(c *gin.Context) {
	name := c.Param("name")
	logFile := fmt.Sprintf("/var/log/panda/deploy-%s.log", name)

	data, err := os.ReadFile(logFile)
	if err != nil {
		c.JSON(404, gin.H{"error": "No logs found"})
		return
	}

	lines := strings.Split(string(data), "\n")
	start := 0
	if len(lines) > 100 {
		start = len(lines) - 100
	}

	c.JSON(200, gin.H{
		"logs": strings.Join(lines[start:], "\n"),
	})
}

// DeleteDeploymentHandler - Remove deployment config
func DeleteDeploymentHandler(c *gin.Context) {
	name := c.Param("name")

	os.Remove(fmt.Sprintf("/etc/panda/deployments/%s.conf", name))
	os.Remove(fmt.Sprintf("/home/webhooks/%s-webhook.php", name))

	c.JSON(200, gin.H{"success": true, "message": "Deployment removed"})
}

// EnableAutoDeployHandler - Enable/configure webhook
func EnableAutoDeployHandler(c *gin.Context) {
	name := c.Param("name")

	cmd := exec.Command("bash", "-c", fmt.Sprintf(`
source /opt/panda/modules/deploy/workflow.sh
configure_auto_deploy_api "%s"
`, name))

	output, err := cmd.CombinedOutput()
	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	configPath := fmt.Sprintf("/etc/panda/deployments/%s.conf", name)
	configData, _ := os.ReadFile(configPath)
	secret := ""
	for _, line := range strings.Split(string(configData), "\n") {
		if strings.HasPrefix(line, "WEBHOOK_SECRET=") {
			secret = strings.TrimPrefix(line, "WEBHOOK_SECRET=")
			break
		}
	}

	c.JSON(200, gin.H{
		"success":     true,
		"webhook_url": fmt.Sprintf("/webhooks/%s-webhook.php", name),
		"secret":      secret,
	})
}

// CloneFromGitHubHandler - Clone project from GitHub (supports PHP, Node.js, Python, Java)
func CloneFromGitHubHandler(c *gin.Context) {
	var req struct {
		RepoURL     string `json:"repo_url" binding:"required"`
		ProjectName string `json:"project_name" binding:"required"`
		ProjectType string `json:"project_type"`
		Port        int    `json:"port"`
		Domain      string `json:"domain"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if req.ProjectType == "" {
		req.ProjectType = "php" // Default to PHP now
	}
	if req.Port == 0 {
		switch req.ProjectType {
		case "nodejs":
			req.Port = 3000
		case "python":
			req.Port = 8000
		case "java":
			req.Port = 8080
		default:
			req.Port = 80
		}
	}

	var script string
	var webRoot string

	switch req.ProjectType {
	case "php":
		// PHP project - clone to /home/{domain}
		if req.Domain == "" {
			req.Domain = req.ProjectName
		}
		webRoot = fmt.Sprintf("/home/%s", req.Domain)
		script = fmt.Sprintf(`
set -e
DOMAIN="%s"
REPO="%s"
WEB_ROOT="/home/%s"

# Create directory
mkdir -p "$WEB_ROOT"

# Clone repo
git clone --depth 1 "$REPO" "$WEB_ROOT" 2>&1 || { rm -rf "$WEB_ROOT"; git clone --depth 1 "$REPO" "$WEB_ROOT"; }

# Set permissions
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;

# Install composer if exists
if [ -f "$WEB_ROOT/composer.json" ]; then
    cd "$WEB_ROOT"
    composer install --no-dev --optimize-autoloader 2>/dev/null || true
fi

# Create Nginx config
source /opt/panda/modules/nginx/vhost.sh 2>/dev/null || true
cat > /etc/nginx/sites-available/$DOMAIN.conf << 'NGINX'
server {
    listen 80;
    server_name %s;
    root /home/%s;
    index index.php index.html;
    
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
NGINX

ln -sf /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "PHP project cloned successfully to $WEB_ROOT"
`, req.Domain, req.RepoURL, req.Domain, req.Domain, req.Domain)

	case "nodejs":
		webRoot = fmt.Sprintf("/home/nodejs-apps/%s", req.ProjectName)
		script = fmt.Sprintf(`
source /opt/panda/modules/project/nodejs.sh
clone_nodejs_api "%s" "%s" %d "%s"
`, req.RepoURL, req.ProjectName, req.Port, req.Domain)

	case "python":
		webRoot = fmt.Sprintf("/home/python-apps/%s", req.ProjectName)
		script = fmt.Sprintf(`
source /opt/panda/modules/project/python.sh
clone_python_api "%s" "%s" %d "%s"
`, req.RepoURL, req.ProjectName, req.Port, req.Domain)

	case "java":
		webRoot = fmt.Sprintf("/home/java-apps/%s", req.ProjectName)
		script = fmt.Sprintf(`
source /opt/panda/modules/project/java.sh
clone_java_api "%s" "%s" %d
`, req.RepoURL, req.ProjectName, req.Port)

	default:
		c.JSON(400, gin.H{"error": "Invalid project type. Supported: php, nodejs, python, java"})
		return
	}

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		SendNotification("Clone Failed", fmt.Sprintf("Failed to clone %s", req.RepoURL), "error")
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	SendNotification("Project Cloned", fmt.Sprintf("%s project %s cloned from GitHub", req.ProjectType, req.ProjectName), "success")

	c.JSON(200, gin.H{
		"success":  true,
		"message":  fmt.Sprintf("%s project cloned successfully", req.ProjectType),
		"web_root": webRoot,
	})
}

// GetProjectStatsHandler - Get stats for all project types
func GetProjectStatsHandler(c *gin.Context) {
	stats := map[string]int{
		"nodejs_projects": 0,
		"python_projects": 0,
		"java_projects":   0,
		"php_projects":    0,
		"deployments":     0,
	}

	// Count Node.js
	if entries, err := os.ReadDir("/home/nodejs-apps"); err == nil {
		stats["nodejs_projects"] = len(entries)
	}

	// Count Python
	if entries, err := os.ReadDir("/home/python-apps"); err == nil {
		stats["python_projects"] = len(entries)
	}

	// Count Java
	if entries, err := os.ReadDir("/home/java-apps"); err == nil {
		stats["java_projects"] = len(entries)
	}

	// Count PHP (websites in /home)
	if entries, err := os.ReadDir("/home"); err == nil {
		for _, e := range entries {
			if e.IsDir() && !strings.HasSuffix(e.Name(), "-apps") {
				// Check if it's a website
				indexPath := filepath.Join("/home", e.Name(), "index.php")
				if _, err := os.Stat(indexPath); err == nil {
					stats["php_projects"]++
				}
			}
		}
	}

	// Count deployments
	if entries, err := os.ReadDir("/etc/panda/deployments"); err == nil {
		for _, e := range entries {
			if strings.HasSuffix(e.Name(), ".conf") {
				stats["deployments"]++
			}
		}
	}

	c.JSON(200, stats)
}

// ============================================
// Notification System
// ============================================

type NotificationConfig struct {
	TelegramEnabled  bool   `json:"telegram_enabled"`
	TelegramBotToken string `json:"telegram_bot_token"`
	TelegramChatID   string `json:"telegram_chat_id"`
	EmailEnabled     bool   `json:"email_enabled"`
	EmailSMTP        string `json:"email_smtp"`
	EmailPort        int    `json:"email_port"`
	EmailUser        string `json:"email_user"`
	EmailPassword    string `json:"email_password"`
	EmailTo          string `json:"email_to"`
	PanelEnabled     bool   `json:"panel_enabled"`
}

type Notification struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	Message   string `json:"message"`
	Type      string `json:"type"` // success, error, warning, info
	Read      bool   `json:"read"`
	CreatedAt string `json:"created_at"`
}

var notifications []Notification
var notificationConfig NotificationConfig

func init() {
	notifications = []Notification{}
	notificationConfig = NotificationConfig{
		PanelEnabled: true,
	}
	loadNotificationConfig()
}

func loadNotificationConfig() {
	data, err := os.ReadFile("/etc/panda/notifications.json")
	if err == nil {
		json.Unmarshal(data, &notificationConfig)
	}
}

func saveNotificationConfig() {
	data, _ := json.MarshalIndent(notificationConfig, "", "  ")
	os.MkdirAll("/etc/panda", 0755)
	os.WriteFile("/etc/panda/notifications.json", data, 0644)
}

// SendNotification - Send notification to all configured channels
func SendNotification(title, message, notifType string) {
	// Panel notification
	if notificationConfig.PanelEnabled {
		notif := Notification{
			ID:        time.Now().UnixNano(),
			Title:     title,
			Message:   message,
			Type:      notifType,
			Read:      false,
			CreatedAt: time.Now().Format("2006-01-02 15:04:05"),
		}
		notifications = append([]Notification{notif}, notifications...)
		// Keep only last 100 notifications
		if len(notifications) > 100 {
			notifications = notifications[:100]
		}
	}

	// Telegram notification
	if notificationConfig.TelegramEnabled && notificationConfig.TelegramBotToken != "" {
		go sendTelegramNotification(title, message, notifType)
	}

	// Email notification
	if notificationConfig.EmailEnabled && notificationConfig.EmailSMTP != "" {
		go sendEmailNotification(title, message, notifType)
	}
}

func sendTelegramNotification(title, message, notifType string) {
	emoji := "ℹ️"
	switch notifType {
	case "success":
		emoji = "✅"
	case "error":
		emoji = "❌"
	case "warning":
		emoji = "⚠️"
	}

	text := fmt.Sprintf("%s *%s*\n\n%s", emoji, title, message)
	url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", notificationConfig.TelegramBotToken)

	payload := map[string]string{
		"chat_id":    notificationConfig.TelegramChatID,
		"text":       text,
		"parse_mode": "Markdown",
	}

	jsonData, _ := json.Marshal(payload)
	http.Post(url, "application/json", bytes.NewBuffer(jsonData))
}

func sendEmailNotification(title, message, notifType string) {
	// Use msmtp or sendmail for email
	script := fmt.Sprintf(`
echo -e "Subject: [Panda Panel] %s\n\n%s" | msmtp -a default %s 2>/dev/null || \
echo -e "Subject: [Panda Panel] %s\n\n%s" | sendmail %s 2>/dev/null || true
`, title, message, notificationConfig.EmailTo, title, message, notificationConfig.EmailTo)

	exec.Command("bash", "-c", script).Run()
}

// GetNotificationsHandler - Get panel notifications
func GetNotificationsHandler(c *gin.Context) {
	c.JSON(200, gin.H{"notifications": notifications})
}

// MarkNotificationReadHandler - Mark notification as read
func MarkNotificationReadHandler(c *gin.Context) {
	id := c.Param("id")
	var notifID int64
	fmt.Sscanf(id, "%d", &notifID)

	for i := range notifications {
		if notifications[i].ID == notifID {
			notifications[i].Read = true
			break
		}
	}

	c.JSON(200, gin.H{"success": true})
}

// MarkAllNotificationsReadHandler - Mark all notifications as read
func MarkAllNotificationsReadHandler(c *gin.Context) {
	for i := range notifications {
		notifications[i].Read = true
	}
	c.JSON(200, gin.H{"success": true})
}

// ClearNotificationsHandler - Clear all notifications
func ClearNotificationsHandler(c *gin.Context) {
	notifications = []Notification{}
	c.JSON(200, gin.H{"success": true})
}

// GetNotificationConfigHandler - Get notification settings
func GetNotificationConfigHandler(c *gin.Context) {
	// Don't expose passwords
	safeConfig := notificationConfig
	safeConfig.EmailPassword = ""
	c.JSON(200, safeConfig)
}

// UpdateNotificationConfigHandler - Update notification settings
func UpdateNotificationConfigHandler(c *gin.Context) {
	var req NotificationConfig
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Preserve password if not provided
	if req.EmailPassword == "" {
		req.EmailPassword = notificationConfig.EmailPassword
	}

	notificationConfig = req
	saveNotificationConfig()

	c.JSON(200, gin.H{"success": true, "message": "Settings saved"})
}

// TestTelegramHandler - Test Telegram notification
func TestTelegramHandler(c *gin.Context) {
	if !notificationConfig.TelegramEnabled || notificationConfig.TelegramBotToken == "" {
		c.JSON(400, gin.H{"error": "Telegram not configured"})
		return
	}

	sendTelegramNotification("Test Notification", "Panda Panel notification is working!", "info")
	c.JSON(200, gin.H{"success": true, "message": "Test notification sent"})
}

// TestEmailHandler - Test Email notification
func TestEmailHandler(c *gin.Context) {
	if !notificationConfig.EmailEnabled || notificationConfig.EmailSMTP == "" {
		c.JSON(400, gin.H{"error": "Email not configured"})
		return
	}

	sendEmailNotification("Test Notification", "Panda Panel email notification is working!", "info")
	c.JSON(200, gin.H{"success": true, "message": "Test email sent"})
}
