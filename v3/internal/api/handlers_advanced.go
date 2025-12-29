package api

import (
	"fmt"
	"net/http"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/auth"
	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/system"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// ============================================================================
// 2FA Handlers
// ============================================================================

func Setup2FAHandler(c *gin.Context) {
	username, _ := c.Get("username")

	var user db.User
	if err := db.DB.Where("username = ?", username).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if user.TwoFactorEnabled {
		c.JSON(http.StatusBadRequest, gin.H{"error": "2FA is already enabled"})
		return
	}

	key, err := auth.GenerateTOTPSecret(user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate 2FA secret"})
		return
	}

	// Save secret temporarily (not enabled yet)
	user.TwoFactorSecret = key.Secret()
	db.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{
		"secret": key.Secret(),
		"url":    key.URL(),
	})
}

func Verify2FASetupHandler(c *gin.Context) {
	username, _ := c.Get("username")
	var req struct {
		Code string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user db.User
	if err := db.DB.Where("username = ?", username).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if user.TwoFactorSecret == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "2FA not set up yet"})
		return
	}

	if !auth.ValidateTOTP(user.TwoFactorSecret, req.Code) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid 2FA code"})
		return
	}

	user.TwoFactorEnabled = true
	db.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{"message": "2FA enabled successfully"})
}

func Disable2FAHandler(c *gin.Context) {
	username, _ := c.Get("username")
	var req struct {
		Code     string `json:"code" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user db.User
	if err := db.DB.Where("username = ?", username).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid password"})
		return
	}

	if !auth.ValidateTOTP(user.TwoFactorSecret, req.Code) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid 2FA code"})
		return
	}

	user.TwoFactorEnabled = false
	user.TwoFactorSecret = ""
	db.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{"message": "2FA disabled successfully"})
}

// ============================================================================
// Login Token Handlers
// ============================================================================

func GenerateLoginTokenHandler(c *gin.Context) {
	username, _ := c.Get("username")

	var user db.User
	if err := db.DB.Where("username = ?", username).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	token, expiresAt, err := auth.GenerateLoginToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	loginToken := db.LoginToken{
		Token:     token,
		UserID:    user.ID,
		ExpiresAt: expiresAt,
		Used:      false,
	}
	db.DB.Create(&loginToken)

	c.JSON(http.StatusOK, gin.H{
		"token":      token,
		"expires_at": expiresAt,
		"url":        "/panda/login?token=" + token,
	})
}

func VerifyLoginTokenHandler(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Token required"})
		return
	}

	var loginToken db.LoginToken
	if err := db.DB.Where("token = ?", token).First(&loginToken).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Invalid token"})
		return
	}

	if loginToken.Used {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Token already used"})
		return
	}

	if time.Now().After(loginToken.ExpiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Token expired"})
		return
	}

	// Mark as used
	loginToken.Used = true
	db.DB.Save(&loginToken)

	// Get user
	var user db.User
	db.DB.First(&user, loginToken.UserID)

	// Generate JWT
	jwtToken, _ := auth.GenerateToken(user.Username, user.Role)

	c.JSON(http.StatusOK, gin.H{"token": jwtToken})
}

// ============================================================================
// IP Whitelist Handlers
// ============================================================================

func ListIPWhitelistHandler(c *gin.Context) {
	var ips []db.IPWhitelist
	db.DB.Find(&ips)
	c.JSON(http.StatusOK, ips)
}

func AddIPWhitelistHandler(c *gin.Context) {
	var req struct {
		IP          string `json:"ip" binding:"required"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ip := db.IPWhitelist{
		IP:          req.IP,
		Description: req.Description,
		Enabled:     true,
	}
	db.DB.Create(&ip)

	c.JSON(http.StatusOK, ip)
}

func DeleteIPWhitelistHandler(c *gin.Context) {
	id := c.Param("id")
	db.DB.Delete(&db.IPWhitelist{}, id)
	c.JSON(http.StatusOK, gin.H{"message": "IP removed from whitelist"})
}

func ToggleIPWhitelistHandler(c *gin.Context) {
	id := c.Param("id")
	var ip db.IPWhitelist
	if err := db.DB.First(&ip, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "IP not found"})
		return
	}
	ip.Enabled = !ip.Enabled
	db.DB.Save(&ip)
	c.JSON(http.StatusOK, ip)
}

// ============================================================================
// Notification Helper (actual handlers in handlers_projects.go)
// ============================================================================

// CreateNotification is a helper function to create notifications in DB
func CreateNotification(notifType, title, message string) {
	notification := db.Notification{
		Type:    notifType,
		Title:   title,
		Message: message,
		Read:    false,
	}
	db.DB.Create(&notification)
}

// ============================================================================
// User Management Handlers (Multi-User)
// ============================================================================

func ListUsersHandler(c *gin.Context) {
	var users []db.User
	db.DB.Find(&users)
	c.JSON(http.StatusOK, users)
}

func CreateUserHandler(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
		Role     string `json:"role"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Role == "" {
		req.Role = "user"
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := db.User{
		Username: req.Username,
		Password: string(hashedPassword),
		Role:     req.Role,
	}

	if err := db.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username already exists"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func DeleteUserHandler(c *gin.Context) {
	id := c.Param("id")

	// Prevent deleting admin
	var user db.User
	if err := db.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if user.Username == "admin" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete admin user"})
		return
	}

	db.DB.Delete(&db.User{}, id)
	c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}

func UpdateUserRoleHandler(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Role string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db.DB.Model(&db.User{}).Where("id = ?", id).Update("role", req.Role)
	c.JSON(http.StatusOK, gin.H{"message": "Role updated"})
}

// ============================================================================
// Process Handlers (Top Processes)
// ============================================================================

type ProcessInfo struct {
	PID     int     `json:"pid"`
	Name    string  `json:"name"`
	CPU     float64 `json:"cpu"`
	Memory  float64 `json:"memory"`
	User    string  `json:"user"`
	Command string  `json:"command"`
}

func ListProcessesHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, []ProcessInfo{})
		return
	}

	out, err := system.Execute("ps aux --sort=-%cpu | head -20")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var processes []ProcessInfo
	lines := strings.Split(out, "\n")
	for i, line := range lines {
		if i == 0 || strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) < 11 {
			continue
		}

		pid, _ := strconv.Atoi(fields[1])
		cpu, _ := strconv.ParseFloat(fields[2], 64)
		mem, _ := strconv.ParseFloat(fields[3], 64)

		processes = append(processes, ProcessInfo{
			PID:     pid,
			User:    fields[0],
			CPU:     cpu,
			Memory:  mem,
			Name:    fields[10],
			Command: strings.Join(fields[10:], " "),
		})
	}

	c.JSON(http.StatusOK, processes)
}

func KillProcessHandler(c *gin.Context) {
	pid := c.Param("pid")

	if runtime.GOOS == "windows" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not supported on Windows"})
		return
	}

	_, err := system.Execute("kill -9 " + pid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Process killed"})
}

// ============================================================================
// App Store Handlers
// ============================================================================

var defaultApps = []db.App{
	// System Tools (not Docker)
	{Name: "Node.js + PM2", Slug: "nodejs", Description: "JavaScript runtime with PM2 process manager", Icon: "💚", DockerImage: "system", Port: 0},
	{Name: "MySQL Server", Slug: "mysql-native", Description: "MySQL database (native install)", Icon: "🐬", DockerImage: "system", Port: 3306},
	{Name: "MariaDB Server", Slug: "mariadb", Description: "MariaDB database (MySQL fork)", Icon: "🧊", DockerImage: "system", Port: 3306},
	// Docker Apps - Databases
	{Name: "MySQL (Docker)", Slug: "mysql", Description: "MySQL in Docker container", Icon: "🗄️", DockerImage: "mysql:8.0", Port: 3306},
	{Name: "Redis (Docker)", Slug: "redis", Description: "Redis in Docker container", Icon: "🔴", DockerImage: "redis:alpine", Port: 6379},
	{Name: "PostgreSQL (Docker)", Slug: "postgresql", Description: "PostgreSQL in Docker container", Icon: "🐘", DockerImage: "postgres:15", Port: 5432},
	{Name: "MongoDB (Docker)", Slug: "mongodb", Description: "MongoDB in Docker container", Icon: "🍃", DockerImage: "mongo:6", Port: 27017},
	// Docker Apps - Web
	{Name: "Nextcloud", Slug: "nextcloud", Description: "Self-hosted cloud storage", Icon: "☁️", DockerImage: "nextcloud:latest", Port: 8080},
	{Name: "WordPress", Slug: "wordpress", Description: "Popular CMS", Icon: "📝", DockerImage: "wordpress:latest", Port: 8081},
	{Name: "Ghost", Slug: "ghost", Description: "Publishing platform", Icon: "👻", DockerImage: "ghost:latest", Port: 8082},
	{Name: "n8n", Slug: "n8n", Description: "Workflow automation", Icon: "🔄", DockerImage: "n8nio/n8n:latest", Port: 5678},
	{Name: "Portainer", Slug: "portainer", Description: "Docker management", Icon: "🐳", DockerImage: "portainer/portainer-ce:latest", Port: 9000},
	{Name: "Uptime Kuma", Slug: "uptime-kuma", Description: "Uptime monitoring", Icon: "📊", DockerImage: "louislam/uptime-kuma:latest", Port: 3001},
	{Name: "phpMyAdmin", Slug: "phpmyadmin", Description: "MySQL web interface", Icon: "🗃️", DockerImage: "phpmyadmin/phpmyadmin", Port: 8081},
}

func ListAppsHandler(c *gin.Context) {
	var apps []db.App
	db.DB.Find(&apps)

	// Sync default apps to DB (add missing ones)
	for _, defaultApp := range defaultApps {
		exists := false
		for _, app := range apps {
			if app.Slug == defaultApp.Slug {
				exists = true
				break
			}
		}
		if !exists {
			db.DB.Create(&defaultApp)
		}
	}

	// Refresh apps list
	db.DB.Find(&apps)
	c.JSON(http.StatusOK, apps)
}

func InstallAppHandler(c *gin.Context) {
	slug := c.Param("slug")

	var app db.App
	if err := db.DB.Where("slug = ?", slug).First(&app).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "App not found"})
		return
	}

	if app.Installed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "App already installed"})
		return
	}

	// Build install command based on app type
	var cmd string
	var isSystemApp bool

	switch app.Slug {
	// System Tools (not Docker)
	case "nodejs":
		isSystemApp = true
		cmd = `curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs && npm install -g pm2 && pm2 startup && node -v && pm2 -v`
	case "mysql-native":
		isSystemApp = true
		cmd = `apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server && systemctl enable mysql && systemctl start mysql && mysql -V`
	case "mariadb":
		isSystemApp = true
		cmd = `apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server && systemctl enable mariadb && systemctl start mariadb && mysql -V`
	// Docker Apps - Databases
	case "mysql":
		cmd = "docker run -d --name panda-mysql --restart unless-stopped -e MYSQL_ROOT_PASSWORD=panda123 -p 3306:3306 -v panda-mysql-data:/var/lib/mysql mysql:8.0"
	case "redis":
		cmd = "docker run -d --name panda-redis --restart unless-stopped -p 6379:6379 -v panda-redis-data:/data redis:alpine"
	case "postgresql":
		cmd = "docker run -d --name panda-postgresql --restart unless-stopped -e POSTGRES_PASSWORD=panda123 -p 5432:5432 -v panda-postgres-data:/var/lib/postgresql/data postgres:15"
	case "mongodb":
		cmd = "docker run -d --name panda-mongodb --restart unless-stopped -p 27017:27017 -v panda-mongo-data:/data/db mongo:6"
	case "portainer":
		cmd = "docker run -d --name panda-portainer --restart unless-stopped -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v panda-portainer-data:/data portainer/portainer-ce:latest"
	case "phpmyadmin":
		// Check if mysql container exists
		mysqlHost := "172.17.0.1" // Docker host (native mysql)
		dockerCheck, _ := system.Execute("docker ps --filter name=panda-mysql --format '{{.Names}}'")
		if strings.TrimSpace(dockerCheck) == "panda-mysql" {
			mysqlHost = "panda-mysql"
		} else {
			dockerCheck, _ = system.Execute("docker ps --filter name=mysql --format '{{.Names}}'")
			if strings.TrimSpace(dockerCheck) == "mysql" {
				mysqlHost = "mysql"
			}
		}

		linkArg := ""
		if mysqlHost != "172.17.0.1" {
			linkArg = "--link " + mysqlHost + ":db"
		}

		cmd = fmt.Sprintf("docker run -d --name panda-phpmyadmin --restart unless-stopped %s -e PMA_HOST=%s -p 8081:80 phpmyadmin/phpmyadmin", linkArg, mysqlHost)
	default:
		// Generic docker apps - port mapping to container port 80
		cmd = "docker run -d --name panda-" + app.Slug + " --restart unless-stopped -p " + strconv.Itoa(app.Port) + ":80 " + app.DockerImage
	}

	// Ignore unused variable for now
	_ = isSystemApp

	out, err := system.Execute(cmd)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to install: " + err.Error() + " | Output: " + out})
		return
	}

	app.Installed = true
	app.ContainerID = strings.TrimSpace(out)
	db.DB.Save(&app)

	CreateNotification("success", "App Installed", app.Name+" has been installed successfully")

	c.JSON(http.StatusOK, gin.H{"message": app.Name + " installed successfully"})
}

func UninstallAppHandler(c *gin.Context) {
	slug := c.Param("slug")

	var app db.App
	if err := db.DB.Where("slug = ?", slug).First(&app).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "App not found"})
		return
	}

	if !app.Installed {
		c.JSON(http.StatusBadRequest, gin.H{"error": "App not installed"})
		return
	}

	// Stop and remove container
	system.Execute("docker stop panda-" + app.Slug)
	system.Execute("docker rm panda-" + app.Slug)

	app.Installed = false
	app.ContainerID = ""
	db.DB.Save(&app)

	c.JSON(http.StatusOK, gin.H{"message": app.Name + " uninstalled"})
}

// ============================================================================
// Archive Handlers (Compress/Extract)
// ============================================================================

func CompressFilesHandler(c *gin.Context) {
	var req struct {
		Path   string `json:"path" binding:"required"`
		Output string `json:"output" binding:"required"`
		Format string `json:"format"` // zip, tar.gz
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Format == "" {
		req.Format = "zip"
	}

	var cmd string
	switch req.Format {
	case "zip":
		cmd = "cd " + req.Path + " && zip -r " + req.Output + " ."
	case "tar.gz":
		cmd = "tar -czf " + req.Output + " -C " + req.Path + " ."
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Unsupported format"})
		return
	}

	if _, err := system.Execute(cmd); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Compressed successfully", "output": req.Output})
}

func ExtractArchiveHandler(c *gin.Context) {
	var req struct {
		Archive string `json:"archive" binding:"required"`
		Output  string `json:"output" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var cmd string
	if strings.HasSuffix(req.Archive, ".zip") {
		cmd = "unzip -o " + req.Archive + " -d " + req.Output
	} else if strings.HasSuffix(req.Archive, ".tar.gz") || strings.HasSuffix(req.Archive, ".tgz") {
		cmd = "tar -xzf " + req.Archive + " -C " + req.Output
	} else if strings.HasSuffix(req.Archive, ".tar.bz2") {
		cmd = "tar -xjf " + req.Archive + " -C " + req.Output
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Unsupported archive format"})
		return
	}

	if _, err := system.Execute(cmd); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Extracted successfully"})
}
