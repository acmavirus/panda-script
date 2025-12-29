package api

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/auth"
	"github.com/acmavirus/panda-script/v3/internal/database"
	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/docker"
	"github.com/acmavirus/panda-script/v3/internal/filemanager"
	"github.com/acmavirus/panda-script/v3/internal/logs"
	"github.com/acmavirus/panda-script/v3/internal/system"
	"github.com/acmavirus/panda-script/v3/internal/task"
	"github.com/acmavirus/panda-script/v3/internal/terminal"
	"github.com/acmavirus/panda-script/v3/internal/website"
	"github.com/gin-gonic/gin"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"golang.org/x/crypto/bcrypt"
)

func HealthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"version": "3.1.0",
		"time":    time.Now().Format(time.RFC3339),
	})
}

func GetSystemStats() gin.H {
	v, _ := mem.VirtualMemory()
	c_percent, _ := cpu.Percent(0, false)
	d, _ := disk.Usage("/")
	h, _ := host.Info()

	var cpuUsage float64
	if len(c_percent) > 0 {
		cpuUsage = c_percent[0]
	}

	return gin.H{
		"os":        h.OS,
		"platform":  h.Platform,
		"arch":      runtime.GOARCH,
		"cpus":      runtime.NumCPU(),
		"cpu_usage": cpuUsage,
		"memory": gin.H{
			"total":        v.Total,
			"used":         v.Used,
			"free":         v.Free,
			"used_percent": v.UsedPercent,
		},
		"disk": gin.H{
			"total":        d.Total,
			"used":         d.Used,
			"free":         d.Free,
			"used_percent": d.UsedPercent,
		},
		"uptime": h.Uptime,
	}
}

func SystemStatsHandler(c *gin.Context) {
	c.JSON(http.StatusOK, GetSystemStats())
}

func SystemStatsSSEHandler(c *gin.Context) {
	c.Writer.Header().Set("Content-Type", "text/event-stream")
	c.Writer.Header().Set("Cache-Control", "no-cache")
	c.Writer.Header().Set("Connection", "keep-alive")
	c.Writer.Header().Set("Access-Control-Allow-Origin", "*")

	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	// Notify when client disconnects
	clientGone := c.Writer.CloseNotify()

	for {
		select {
		case <-clientGone:
			return
		case <-ticker.C:
			stats := GetSystemStats()
			c.SSEvent("stats", stats)
			c.Writer.Flush()
		}
	}
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Auth Handlers

func LoginHandler(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	var user db.User
	if err := db.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	token, err := auth.GenerateToken(user.Username, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"token": token})
}

func ChangePasswordHandler(c *gin.Context) {
	var req struct {
		OldPassword string `json:"old_password" binding:"required"`
		NewPassword string `json:"new_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	username, _ := c.Get("username")
	var user db.User
	if err := db.DB.Where("username = ?", username).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.OldPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid old password"})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	user.Password = string(hashedPassword)
	if err := db.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
}

// Docker Handlers

func ListContainersHandler(c *gin.Context) {
	containers, err := docker.ListContainers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, containers)
}

func StartContainerHandler(c *gin.Context) {
	id := c.Param("id")
	if _, err := docker.StartContainer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Container started"})
}

func StopContainerHandler(c *gin.Context) {
	id := c.Param("id")
	if _, err := docker.StopContainer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Container stopped"})
}

func RestartContainerHandler(c *gin.Context) {
	id := c.Param("id")
	if _, err := docker.RestartContainer(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Container restarted"})
}

// File Manager Handlers

func ListFilesHandler(c *gin.Context) {
	path := c.Query("path")
	if path == "" {
		path = "/"
	}
	files, err := filemanager.ListDirectory(path)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, files)
}

func ReadFileHandler(c *gin.Context) {
	path := c.Query("path")
	content, err := filemanager.ReadFile(path)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"content": content})
}

func WriteFileHandler(c *gin.Context) {
	var req struct {
		Path    string `json:"path"`
		Content string `json:"content"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.WriteFile(req.Path, req.Content); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "File saved"})
}

func DeleteFileHandler(c *gin.Context) {
	path := c.Query("path")
	if err := filemanager.DeleteFile(path); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "File deleted"})
}

func CreateDirHandler(c *gin.Context) {
	var req struct {
		Path string `json:"path"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.CreateDirectory(req.Path); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Directory created"})
}

func RenameFileHandler(c *gin.Context) {
	var req struct {
		OldPath string `json:"old_path"`
		NewPath string `json:"new_path"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.RenameFile(req.OldPath, req.NewPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "File renamed successfully"})
}

func UploadFileHandler(c *gin.Context) {
	// Multipart form
	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid form data"})
		return
	}

	path := c.PostForm("path")
	if path == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is required"})
		return
	}

	files := form.File["files"]
	for _, file := range files {
		dst := filepath.Join(path, file.Filename)
		if err := c.SaveUploadedFile(file, dst); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to upload %s: %s", file.Filename, err.Error())})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("%d files uploaded successfully", len(files))})
}

func RemoteDownloadHandler(c *gin.Context) {
	var req struct {
		URL  string `json:"url"`
		Path string `json:"path"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := filemanager.DownloadRemoteFile(req.URL, req.Path); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "File downloaded successfully"})
}

// Task Handlers

func GetTaskHandler(c *gin.Context) {
	id := c.Param("id")
	t, ok := task.GetTask(id)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}
	c.JSON(http.StatusOK, t)
}

// Terminal Handlers

func TerminalHandler(c *gin.Context) {
	terminal.HandleWebsocket(c)
}

func UpdateSystemHandler(c *gin.Context) {
	var req struct {
		Version string `json:"version"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	if err := system.UpdateSystem(req.Version); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Update started"})
}

// Website Handlers

func ListWebsitesHandler(c *gin.Context) {
	sites, err := website.ListWebsites()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, sites)
}

func CreateWebsiteHandler(c *gin.Context) {
	var req website.Website
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := website.CreateWebsite(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Website created"})
}

func DeleteWebsiteHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := website.DeleteWebsite(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Website deleted"})
}

func CreateWebsiteSSLHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := website.CreateSSL(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "SSL certificate created successfully for " + domain})
}

func CreateWebsiteDBHandler(c *gin.Context) {
	domain := c.Param("domain")
	// Sanitize domain for DB name and User (e.g. example.com -> example_com)
	nameBase := strings.ReplaceAll(domain, ".", "_")
	nameBase = strings.ReplaceAll(nameBase, "-", "_")

	dbName := nameBase
	dbUser := nameBase
	dbPass := generateRandomPassword(16)

	// 1. Create MySQL database
	if _, err := database.ExecuteQuery("", "mysql", fmt.Sprintf("CREATE DATABASE IF NOT EXISTS %s;", dbName)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create database: " + err.Error()})
		return
	}

	// 2. Create User and Grant Privileges
	// We use multiple queries for better compatibility with different MySQL versions
	queries := []string{
		fmt.Sprintf("CREATE USER IF NOT EXISTS '%s'@'localhost' IDENTIFIED BY '%s';", dbUser, dbPass),
		fmt.Sprintf("GRANT ALL PRIVILEGES ON %s.* TO '%s'@'localhost';", dbName, dbUser),
		"FLUSH PRIVILEGES;",
	}

	for _, q := range queries {
		if _, err := database.ExecuteQuery("", "mysql", q); err != nil {
			// Some older versions might fail on IF NOT EXISTS for users, or have different GRANT syntax
			// We continue to next query to ensure we try our best
			continue
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Database and User created successfully",
		"db_name":     dbName,
		"db_user":     dbUser,
		"db_password": dbPass,
		"db_host":     "localhost",
	})
}

func generateRandomPassword(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
		time.Sleep(1 * time.Nanosecond) // Ensure different nano time
	}
	return string(b)
}

func FixWebsitePermissionsHandler(c *gin.Context) {
	domain := c.Param("domain")
	webRoot := "/home/" + domain

	// Check if directory exists
	if _, err := os.Stat(webRoot); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Website directory not found"})
		return
	}

	// Fix ownership: www-data:www-data
	if _, err := system.Execute(fmt.Sprintf("chown -R www-data:www-data %s", webRoot)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set ownership: " + err.Error()})
		return
	}

	// Fix permissions: 755 for directories, 644 for files
	if _, err := system.Execute(fmt.Sprintf("find %s -type d -exec chmod 755 {} \\;", webRoot)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set directory permissions: " + err.Error()})
		return
	}
	if _, err := system.Execute(fmt.Sprintf("find %s -type f -exec chmod 644 {} \\;", webRoot)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set file permissions: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Permissions fixed for " + domain})
}

// Database Handlers

func ListDatabasesHandler(c *gin.Context) {
	dbs, err := database.ListDatabases()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, dbs)
}

func CreateDatabaseHandler(c *gin.Context) {
	var req struct {
		Name string `json:"name"`
		Type string `json:"type"` // sqlite or mysql
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := database.CreateDatabase(req.Name, req.Type); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Database created"})
}

func DeleteDatabaseHandler(c *gin.Context) {
	name := c.Query("name")
	dbType := c.DefaultQuery("type", "sqlite")
	if err := database.DeleteDatabase(name, dbType); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Database deleted"})
}

func ExecuteQueryHandler(c *gin.Context) {
	var req struct {
		DBName string `json:"db_name"`
		Query  string `json:"query"`
		Type   string `json:"type"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	result, err := database.ExecuteQuery(req.DBName, req.Type, req.Query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

func BackupDatabaseHandler(c *gin.Context) {
	name := c.Param("name")
	if err := database.BackupDatabase(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Database backup created"})
}

func RestoreDatabaseHandler(c *gin.Context) {
	name := c.Param("name")
	var req struct {
		BackupFile string `json:"backup_file"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := database.RestoreDatabase(name, req.BackupFile); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Database restored"})
}

func ListBackupsHandler(c *gin.Context) {
	name := c.Param("name")
	backups, err := database.ListBackups(name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, backups)
}

// Logs Handlers
func ListLogsHandler(c *gin.Context) {
	c.JSON(http.StatusOK, logs.GetLogFiles())
}

func ReadLogHandler(c *gin.Context) {
	path := c.Query("path")
	if path == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is required"})
		return
	}

	linesStr := c.DefaultQuery("lines", "100")
	lines, err := strconv.Atoi(linesStr)
	if err != nil {
		lines = 100
	}

	content, err := logs.ReadLog(path, lines)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"path":    path,
		"content": content,
	})
}

func GetAccessLogsHandler(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "20")
	limit, _ := strconv.Atoi(limitStr)

	entries, err := logs.ParseAccessLogs(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, entries)
}

func GetSecurityLogsHandler(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "20")
	limit, _ := strconv.Atoi(limitStr)

	entries, err := logs.ParseSecurityLogs(limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, entries)
}

// InstallDockerHandler installs Docker on the server
func InstallDockerHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Docker installation requires Linux"})
		return
	}

	// Check if docker already exists
	_, err := exec.Command("which", "docker").Output()
	if err == nil {
		c.JSON(http.StatusOK, gin.H{"message": "Docker is already installed"})
		return
	}

	// Install Docker
	cmd := exec.Command("bash", "-c", "apt-get update && apt-get install -y docker.io && systemctl start docker && systemctl enable docker")
	output, err := cmd.CombinedOutput()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to install Docker: " + string(output)})
		return
	}

	CreateNotification("success", "Docker Installed", "Docker has been installed successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Docker installed successfully"})
}
