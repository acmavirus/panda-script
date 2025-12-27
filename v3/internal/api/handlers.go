package api

import (
	"fmt"
	"net/http"
	"path/filepath"
	"runtime"
	"strconv"
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
		"version": "3.0.0",
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
