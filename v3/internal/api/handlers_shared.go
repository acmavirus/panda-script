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
		"export HOME=\"/root\" && export GIT_SSH_COMMAND=\"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/id_rsa -i /root/.ssh/id_ed25519 2>/dev/null\" && source /opt/panda/modules/deploy/workflow.sh && deploy_by_name %s",
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
