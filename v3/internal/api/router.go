package api

import (
	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	// Health
	r.GET("/health", HealthHandler)

	// Auth
	r.POST("/auth/login", LoginHandler)

	// Protected Routes
	protected := r.Group("/")
	protected.Use(AuthMiddleware())
	{
		protected.GET("/system/stats", SystemStatsHandler)
		protected.POST("/system/update", UpdateSystemHandler)
		protected.POST("/user/password", ChangePasswordHandler)

		// Docker
		dockerGroup := protected.Group("/docker")
		{
			dockerGroup.GET("/containers", ListContainersHandler)
			dockerGroup.POST("/containers/:id/start", StartContainerHandler)
			dockerGroup.POST("/containers/:id/stop", StopContainerHandler)
			dockerGroup.POST("/containers/:id/restart", RestartContainerHandler)
		}

		// File Manager
		fmGroup := protected.Group("/files")
		{
			fmGroup.GET("/list", ListFilesHandler)
			fmGroup.GET("/read", ReadFileHandler)
			fmGroup.POST("/write", WriteFileHandler)
			fmGroup.POST("/delete", DeleteFileHandler)
			fmGroup.POST("/mkdir", CreateDirHandler)
			fmGroup.POST("/rename", RenameFileHandler)
			fmGroup.POST("/upload", UploadFileHandler)
			fmGroup.POST("/download", RemoteDownloadHandler)
		}

		// Tasks
		protected.GET("/tasks/:id", GetTaskHandler)

		// Terminal
		protected.GET("/terminal/ws", TerminalHandler)

		// Websites
		webGroup := protected.Group("/websites")
		{
			webGroup.GET("/", ListWebsitesHandler)
			webGroup.POST("/", CreateWebsiteHandler)
			webGroup.DELETE("/:domain", DeleteWebsiteHandler)
		}

		// Databases
		dbGroup := protected.Group("/databases")
		{
			dbGroup.GET("/", ListDatabasesHandler)
			dbGroup.POST("/", CreateDatabaseHandler)
			dbGroup.DELETE("/", DeleteDatabaseHandler)
			dbGroup.POST("/query", ExecuteQueryHandler)
			dbGroup.POST("/:name/backup", BackupDatabaseHandler)
			dbGroup.POST("/:name/restore", RestoreDatabaseHandler)
			dbGroup.GET("/:name/backups", ListBackupsHandler)
		}

		// Logs
		logsGroup := protected.Group("/logs")
		{
			logsGroup.GET("/", ListLogsHandler)
			logsGroup.GET("/read", ReadLogHandler)
		}

		// Backup
		backupGroup := protected.Group("/backup")
		{
			backupGroup.GET("/", ListBackupsAPIHandler)
			backupGroup.POST("/website/:domain", BackupWebsiteHandler)
			backupGroup.POST("/database/:name", BackupDatabaseAPIHandler)
			backupGroup.POST("/full", BackupAllHandler)
			backupGroup.POST("/restore", RestoreBackupHandler)
			backupGroup.DELETE("/cleanup", CleanupBackupsHandler)
		}

		// SSL
		sslGroup := protected.Group("/ssl")
		{
			sslGroup.GET("/", ListCertificatesHandler)
			sslGroup.POST("/obtain", ObtainCertificateHandler)
			sslGroup.POST("/renew/:domain", RenewCertificateHandler)
			sslGroup.POST("/renew-all", RenewAllCertificatesHandler)
			sslGroup.GET("/check/:domain", CheckCertExpiryHandler)
			sslGroup.DELETE("/:domain", RevokeCertificateHandler)
		}

		// PHP
		phpGroup := protected.Group("/php")
		{
			phpGroup.GET("/versions", ListPHPVersionsHandler)
			phpGroup.POST("/install", InstallPHPHandler)
			phpGroup.POST("/switch", SwitchPHPHandler)
			phpGroup.GET("/config/:version", GetPHPConfigHandler)
			phpGroup.PUT("/config/:version", UpdatePHPConfigHandler)
			phpGroup.POST("/restart/:version", RestartPHPFPMHandler)
		}

		// Nginx
		nginxGroup := protected.Group("/nginx")
		{
			nginxGroup.GET("/vhosts", ListVhostsHandler)
			nginxGroup.POST("/vhosts", CreateVhostHandler)
			nginxGroup.GET("/vhosts/:domain", GetVhostHandler)
			nginxGroup.DELETE("/vhosts/:domain", DeleteVhostHandler)
			nginxGroup.POST("/ssl/:domain", EnableSSLVhostHandler)
			nginxGroup.DELETE("/ssl/:domain", DisableSSLVhostHandler)
			nginxGroup.POST("/test", TestNginxConfigHandler)
			nginxGroup.POST("/reload", ReloadNginxHandler)
			nginxGroup.GET("/status", NginxStatusHandler)
		}

		// Security
		securityGroup := protected.Group("/security")
		{
			securityGroup.GET("/firewall", GetFirewallStatusHandler)
			securityGroup.POST("/firewall/enable", EnableFirewallHandler)
			securityGroup.POST("/firewall/disable", DisableFirewallHandler)
			securityGroup.GET("/firewall/rules", ListFirewallRulesHandler)
			securityGroup.POST("/whitelist", WhitelistIPHandler)
			securityGroup.POST("/blacklist", BlacklistIPHandler)
			securityGroup.DELETE("/rule/:id", DeleteFirewallRuleHandler)
			securityGroup.GET("/ssh-port", GetSSHPortHandler)
			securityGroup.PUT("/ssh-port", ChangeSSHPortHandler)
		}

		// Services
		servicesGroup := protected.Group("/services")
		{
			servicesGroup.GET("/", ListServicesHandler)
			servicesGroup.GET("/:name", GetServiceStatusHandler)
			servicesGroup.POST("/:name/start", StartServiceHandler)
			servicesGroup.POST("/:name/stop", StopServiceHandler)
			servicesGroup.POST("/:name/restart", RestartServiceHandler)
			servicesGroup.POST("/:name/enable", EnableServiceHandler)
			servicesGroup.POST("/:name/disable", DisableServiceHandler)
			servicesGroup.GET("/:name/logs", GetServiceLogsHandler)
		}
	}
}
