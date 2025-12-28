package api

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

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

	// Run CLI installer
	cmd := exec.Command("bash", "-c", fmt.Sprintf(
		"source /opt/panda/modules/website/cms_installer.sh && install_cms %s <<< '%s'",
		req.CMSType, req.Domain,
	))
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

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
	projectsDir := "/opt/python-apps"

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

		// Parse config
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

		// Get status
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
	projectDir := filepath.Join("/opt/python-apps", name)

	// Stop service
	exec.Command("systemctl", "stop", fmt.Sprintf("python-%s", name)).Run()
	exec.Command("systemctl", "disable", fmt.Sprintf("python-%s", name)).Run()

	// Remove service file
	os.Remove(fmt.Sprintf("/etc/systemd/system/python-%s.service", name))
	exec.Command("systemctl", "daemon-reload").Run()

	// Remove project directory
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
	projectsDir := "/opt/java-apps"

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
cd /opt/java-apps 2>/dev/null || mkdir -p /opt/java-apps
source /opt/panda/modules/project/java.sh
create_java_project_noninteractive "%s" "%s" %d
`, req.Name, req.Domain, req.Port)

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

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
		req.DeployPath = "/var/www"
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
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

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

	// Get last 100 lines
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
	os.Remove(fmt.Sprintf("/var/www/webhooks/%s-webhook.php", name))

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

	// Read secret from config
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

// CloneFromGitHubHandler - Clone project from GitHub
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
		req.ProjectType = "nodejs"
	}
	if req.Port == 0 {
		req.Port = 3000
	}

	var script string
	switch req.ProjectType {
	case "nodejs":
		script = fmt.Sprintf(`
source /opt/panda/modules/project/nodejs.sh
clone_nodejs_api "%s" "%s" %d "%s"
`, req.RepoURL, req.ProjectName, req.Port, req.Domain)
	case "python":
		script = fmt.Sprintf(`
source /opt/panda/modules/project/python.sh
clone_python_api "%s" "%s" %d "%s"
`, req.RepoURL, req.ProjectName, req.Port, req.Domain)
	case "java":
		script = fmt.Sprintf(`
source /opt/panda/modules/project/java.sh
clone_java_api "%s" "%s" %d
`, req.RepoURL, req.ProjectName, req.Port)
	default:
		c.JSON(400, gin.H{"error": "Invalid project type"})
		return
	}

	cmd := exec.Command("bash", "-c", script)
	output, err := cmd.CombinedOutput()

	if err != nil {
		c.JSON(500, gin.H{"error": string(output)})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": fmt.Sprintf("%s project cloned successfully", req.ProjectType),
	})
}

// GetProjectStatsHandler - Get stats for all project types
func GetProjectStatsHandler(c *gin.Context) {
	stats := map[string]int{
		"nodejs_projects": 0,
		"python_projects": 0,
		"java_projects":   0,
		"deployments":     0,
	}

	// Count Node.js
	if entries, err := os.ReadDir("/opt/nodejs-apps"); err == nil {
		stats["nodejs_projects"] = len(entries)
	}

	// Count Python
	if entries, err := os.ReadDir("/opt/python-apps"); err == nil {
		stats["python_projects"] = len(entries)
	}

	// Count Java
	if entries, err := os.ReadDir("/opt/java-apps"); err == nil {
		stats["java_projects"] = len(entries)
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
