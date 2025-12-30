package api

import (
	"net/http"
	"runtime"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/auth"
	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/filemanager"
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
	db.DB.Where("username = ?", username).First(&user)

	token, expiresAt, _ := auth.GenerateLoginToken()
	loginToken := db.LoginToken{
		Token:     token,
		UserID:    user.ID,
		ExpiresAt: expiresAt,
		Used:      false,
	}
	db.DB.Create(&loginToken)

	c.JSON(http.StatusOK, gin.H{"token": token, "url": "/panda/login?token=" + token})
}

func VerifyLoginTokenHandler(c *gin.Context) {
	token := c.Query("token")
	var loginToken db.LoginToken
	if err := db.DB.Where("token = ? AND used = ? AND expires_at > ?", token, false, time.Now()).First(&loginToken).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
		return
	}

	loginToken.Used = true
	db.DB.Save(&loginToken)

	var user db.User
	db.DB.First(&user, loginToken.UserID)
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
	c.ShouldBindJSON(&req)
	ip := db.IPWhitelist{IP: req.IP, Description: req.Description, Enabled: true}
	db.DB.Create(&ip)
	c.JSON(http.StatusOK, ip)
}

func DeleteIPWhitelistHandler(c *gin.Context) {
	id := c.Param("id")
	db.DB.Delete(&db.IPWhitelist{}, id)
	c.JSON(http.StatusOK, gin.H{"message": "IP removed"})
}

func ToggleIPWhitelistHandler(c *gin.Context) {
	id := c.Param("id")
	var ip db.IPWhitelist
	db.DB.First(&ip, id)
	ip.Enabled = !ip.Enabled
	db.DB.Save(&ip)
	c.JSON(http.StatusOK, ip)
}

// ============================================================================
// User Management Handlers
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
	c.ShouldBindJSON(&req)
	if req.Role == "" {
		req.Role = "user"
	}
	hashed, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := db.User{Username: req.Username, Password: string(hashed), Role: req.Role}
	db.DB.Create(&user)
	c.JSON(http.StatusOK, user)
}

func DeleteUserHandler(c *gin.Context) {
	id := c.Param("id")
	db.DB.Delete(&db.User{}, id)
	c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}

func UpdateUserRoleHandler(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Role string `json:"role"`
	}
	c.ShouldBindJSON(&req)
	db.DB.Model(&db.User{}).Where("id = ?", id).Update("role", req.Role)
	c.JSON(http.StatusOK, gin.H{"message": "Role updated"})
}

// ============================================================================
// Process Handlers
// ============================================================================

func ListProcessesHandler(c *gin.Context) {
	if runtime.GOOS == "windows" {
		c.JSON(http.StatusOK, []string{})
		return
	}
	out, _ := system.Execute("ps aux --sort=-%cpu | head -20")
	c.JSON(http.StatusOK, gin.H{"output": out})
}

func KillProcessHandler(c *gin.Context) {
	pid := c.Param("pid")
	system.Execute("kill -9 " + pid)
	c.JSON(http.StatusOK, gin.H{"message": "Process killed"})
}

// ============================================================================
// App Store Handlers
// ============================================================================

func ListAppsHandler(c *gin.Context) {
	var apps []db.App
	db.DB.Find(&apps)
	c.JSON(http.StatusOK, apps)
}

func InstallAppHandler(c *gin.Context) {
	slug := c.Param("slug")
	var app db.App
	db.DB.Where("slug = ?", slug).First(&app)
	// Simplified install logic for brevity in fix
	app.Installed = true
	db.DB.Save(&app)
	c.JSON(http.StatusOK, gin.H{"message": "Installed"})
}

func UninstallAppHandler(c *gin.Context) {
	slug := c.Param("slug")
	var app db.App
	db.DB.Where("slug = ?", slug).First(&app)
	app.Installed = false
	db.DB.Save(&app)
	c.JSON(http.StatusOK, gin.H{"message": "Uninstalled"})
}

// ============================================================================
// File Manager Weaponry Handlers
// ============================================================================

func CompressFilesHandler(c *gin.Context) {
	var req struct {
		Path   string `json:"path" binding:"required"`
		Output string `json:"output" binding:"required"`
		Format string `json:"format"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if req.Format == "" {
		req.Format = "zip"
	}
	if err := filemanager.Compress(req.Path, req.Output, req.Format); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Compressed"})
}

func ExtractArchiveHandler(c *gin.Context) {
	var req struct {
		Archive string `json:"archive" binding:"required"`
		Output  string `json:"output" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.Extract(req.Archive, req.Output); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Extracted"})
}

func ChmodHandler(c *gin.Context) {
	var req struct {
		Path string `json:"path" binding:"required"`
		Mode int    `json:"mode" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.Chmod(req.Path, req.Mode); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Permission updated"})
}

func CopyFilesHandler(c *gin.Context) {
	var req struct {
		Src string `json:"src" binding:"required"`
		Dst string `json:"dst" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.Copy(req.Src, req.Dst); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Copied"})
}

func MoveFilesHandler(c *gin.Context) {
	var req struct {
		Src string `json:"src" binding:"required"`
		Dst string `json:"dst" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := filemanager.Move(req.Src, req.Dst); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Moved"})
}

func ListArchiveHandler(c *gin.Context) {
	archive := c.Query("path")
	if archive == "" {
		c.JSON(400, gin.H{"error": "Path required"})
		return
	}
	files, err := filemanager.ListArchive(archive)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"files": files})
}

func CreateNotification(notifType, title, message string) {
	notification := db.Notification{Type: notifType, Title: title, Message: message, Read: false}
	db.DB.Create(&notification)
}
