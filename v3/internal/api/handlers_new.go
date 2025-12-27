package api

import (
	"net/http"
	"strconv"

	"github.com/acmavirus/panda-script/v3/internal/backup"
	"github.com/acmavirus/panda-script/v3/internal/nginx"
	"github.com/acmavirus/panda-script/v3/internal/php"
	"github.com/acmavirus/panda-script/v3/internal/security"
	"github.com/acmavirus/panda-script/v3/internal/services"
	"github.com/acmavirus/panda-script/v3/internal/ssl"
	"github.com/gin-gonic/gin"
)

// ============================================================================
// Backup Handlers
// ============================================================================

func ListBackupsAPIHandler(c *gin.Context) {
	backups, err := backup.ListBackups()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, backups)
}

func BackupWebsiteHandler(c *gin.Context) {
	domain := c.Param("domain")
	info, err := backup.BackupWebsite(domain)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, info)
}

func BackupDatabaseAPIHandler(c *gin.Context) {
	name := c.Param("name")
	info, err := backup.BackupDatabase(name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, info)
}

func BackupAllHandler(c *gin.Context) {
	info, err := backup.BackupAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, info)
}

func RestoreBackupHandler(c *gin.Context) {
	var req struct {
		Path string `json:"path" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := backup.RestoreBackup(req.Path); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Backup restored successfully"})
}

func CleanupBackupsHandler(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "7")
	days, _ := strconv.Atoi(daysStr)
	if days <= 0 {
		days = 7
	}
	deleted, err := backup.CleanupOldBackups(days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Cleanup complete", "deleted": deleted})
}

// ============================================================================
// SSL Handlers
// ============================================================================

func ListCertificatesHandler(c *gin.Context) {
	certs, err := ssl.ListCertificates()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, certs)
}

func ObtainCertificateHandler(c *gin.Context) {
	var req struct {
		Domain string `json:"domain" binding:"required"`
		Email  string `json:"email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := ssl.ObtainCertificate(req.Domain, req.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Certificate obtained successfully"})
}

func RenewCertificateHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := ssl.RenewCertificate(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Certificate renewed successfully"})
}

func RenewAllCertificatesHandler(c *gin.Context) {
	if err := ssl.RenewAll(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "All certificates renewed"})
}

func CheckCertExpiryHandler(c *gin.Context) {
	domain := c.Param("domain")
	info, err := ssl.CheckExpiry(domain)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, info)
}

func RevokeCertificateHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := ssl.RevokeCertificate(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Certificate revoked"})
}

// ============================================================================
// PHP Handlers
// ============================================================================

func ListPHPVersionsHandler(c *gin.Context) {
	versions, err := php.ListVersions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, versions)
}

func InstallPHPHandler(c *gin.Context) {
	var req struct {
		Version string `json:"version" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := php.InstallVersion(req.Version); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "PHP " + req.Version + " installed successfully"})
}

func SwitchPHPHandler(c *gin.Context) {
	var req struct {
		Version string `json:"version" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := php.SwitchVersion(req.Version); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Switched to PHP " + req.Version})
}

func GetPHPConfigHandler(c *gin.Context) {
	version := c.Param("version")
	config, err := php.GetConfig(version)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, config)
}

func UpdatePHPConfigHandler(c *gin.Context) {
	version := c.Param("version")
	var config php.PHPConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := php.UpdateConfig(version, config); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "PHP configuration updated"})
}

func RestartPHPFPMHandler(c *gin.Context) {
	version := c.Param("version")
	if err := php.RestartFPM(version); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "PHP-FPM restarted"})
}

// ============================================================================
// Nginx Handlers
// ============================================================================

func ListVhostsHandler(c *gin.Context) {
	vhosts, err := nginx.ListVhosts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vhosts)
}

func CreateVhostHandler(c *gin.Context) {
	var config nginx.VhostConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := nginx.CreateVhost(config); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Virtual host created"})
}

func GetVhostHandler(c *gin.Context) {
	domain := c.Param("domain")
	vhost, err := nginx.GetVhost(domain)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vhost)
}

func DeleteVhostHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := nginx.DeleteVhost(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Virtual host deleted"})
}

func EnableSSLVhostHandler(c *gin.Context) {
	domain := c.Param("domain")
	var req struct {
		CertPath string `json:"cert_path"`
	}
	c.ShouldBindJSON(&req)
	if err := nginx.EnableSSL(domain, req.CertPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "SSL enabled for " + domain})
}

func DisableSSLVhostHandler(c *gin.Context) {
	domain := c.Param("domain")
	if err := nginx.DisableSSL(domain); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "SSL disabled for " + domain})
}

func TestNginxConfigHandler(c *gin.Context) {
	if err := nginx.TestConfig(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nginx configuration is valid"})
}

func ReloadNginxHandler(c *gin.Context) {
	if err := nginx.Reload(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nginx reloaded"})
}

func NginxStatusHandler(c *gin.Context) {
	status, err := nginx.GetStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": status})
}

// ============================================================================
// Security Handlers
// ============================================================================

func GetFirewallStatusHandler(c *gin.Context) {
	status, err := security.GetStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}

func EnableFirewallHandler(c *gin.Context) {
	if err := security.EnableFirewall(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Firewall enabled"})
}

func DisableFirewallHandler(c *gin.Context) {
	if err := security.DisableFirewall(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Firewall disabled"})
}

func ListFirewallRulesHandler(c *gin.Context) {
	rules, err := security.ListRules()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rules)
}

func WhitelistIPHandler(c *gin.Context) {
	var req struct {
		IP   string `json:"ip" binding:"required"`
		Port int    `json:"port"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := security.WhitelistIP(req.IP, req.Port); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "IP whitelisted"})
}

func BlacklistIPHandler(c *gin.Context) {
	var req struct {
		IP string `json:"ip" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := security.BlacklistIP(req.IP); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "IP blacklisted"})
}

func DeleteFirewallRuleHandler(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}
	if err := security.DeleteRule(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Rule deleted"})
}

func GetSSHPortHandler(c *gin.Context) {
	port, err := security.GetSSHPort()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"port": port})
}

func ChangeSSHPortHandler(c *gin.Context) {
	var req struct {
		Port int `json:"port" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := security.ChangeSSHPort(req.Port); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "SSH port changed", "port": req.Port})
}

// ============================================================================
// Services Handlers
// ============================================================================

func ListServicesHandler(c *gin.Context) {
	svcs, err := services.ListServices()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, svcs)
}

func GetServiceStatusHandler(c *gin.Context) {
	name := c.Param("name")
	svc, err := services.GetStatus(name)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, svc)
}

func StartServiceHandler(c *gin.Context) {
	name := c.Param("name")
	if err := services.StartService(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": name + " started"})
}

func StopServiceHandler(c *gin.Context) {
	name := c.Param("name")
	if err := services.StopService(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": name + " stopped"})
}

func RestartServiceHandler(c *gin.Context) {
	name := c.Param("name")
	if err := services.RestartService(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": name + " restarted"})
}

func EnableServiceHandler(c *gin.Context) {
	name := c.Param("name")
	if err := services.EnableService(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": name + " enabled"})
}

func DisableServiceHandler(c *gin.Context) {
	name := c.Param("name")
	if err := services.DisableService(name); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": name + " disabled"})
}

func GetServiceLogsHandler(c *gin.Context) {
	name := c.Param("name")
	linesStr := c.DefaultQuery("lines", "50")
	lines, _ := strconv.Atoi(linesStr)

	logs, err := services.GetJournalLogs(name, lines)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"logs": logs})
}
