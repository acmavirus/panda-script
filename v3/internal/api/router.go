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
		protected.POST("/system/install-docker", InstallDockerHandler)
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
			fmGroup.POST("/chmod", ChmodHandler)
			fmGroup.POST("/copy", CopyFilesHandler)
			fmGroup.POST("/move", MoveFilesHandler)
			fmGroup.GET("/archive/list", ListArchiveHandler)
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
			webGroup.POST("/:domain/ssl", CreateWebsiteSSLHandler)
			webGroup.POST("/:domain/db", CreateWebsiteDBHandler)
			webGroup.POST("/:domain/fix-permissions", FixWebsitePermissionsHandler)
			webGroup.POST("/:domain/hot", ToggleWebsiteHotHandler)
			webGroup.POST("/:domain/php", UpdateWebsitePHPVersionHandler)
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
			logsGroup.GET("/access", GetAccessLogsHandler)
			logsGroup.GET("/security", GetSecurityLogsHandler)
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
			nginxGroup.POST("/start", NginxStartHandler)
			nginxGroup.POST("/stop", NginxStopHandler)
			nginxGroup.POST("/restart", NginxRestartHandler)
			nginxGroup.GET("/config", GetMainNginxConfigHandler)
			nginxGroup.POST("/config", SaveMainNginxConfigHandler)
			nginxGroup.GET("/vhosts/:domain/content", GetVhostContentHandler)
			nginxGroup.POST("/vhosts/content", SaveVhostContentHandler)
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

		// 2FA
		twoFAGroup := protected.Group("/2fa")
		{
			twoFAGroup.POST("/setup", Setup2FAHandler)
			twoFAGroup.POST("/verify", Verify2FASetupHandler)
			twoFAGroup.POST("/disable", Disable2FAHandler)
		}

		// Login Tokens
		protected.POST("/auth/login-token", GenerateLoginTokenHandler)

		// IP Whitelist
		whitelistGroup := protected.Group("/whitelist")
		{
			whitelistGroup.GET("/", ListIPWhitelistHandler)
			whitelistGroup.POST("/", AddIPWhitelistHandler)
			whitelistGroup.DELETE("/:id", DeleteIPWhitelistHandler)
			whitelistGroup.POST("/:id/toggle", ToggleIPWhitelistHandler)
		}

		// Notifications
		notifGroup := protected.Group("/notifications")
		{
			notifGroup.GET("/", GetNotificationsHandler)
			notifGroup.POST("/:id/read", MarkNotificationReadHandler)
			notifGroup.POST("/read-all", MarkAllNotificationsReadHandler)
			notifGroup.DELETE("/", ClearNotificationsHandler)
			notifGroup.GET("/config", GetNotificationConfigHandler)
			notifGroup.PUT("/config", UpdateNotificationConfigHandler)
			notifGroup.POST("/test/telegram", TestTelegramHandler)
			notifGroup.POST("/test/email", TestEmailHandler)
		}

		// Users (Multi-User)
		usersGroup := protected.Group("/users")
		{
			usersGroup.GET("/", ListUsersHandler)
			usersGroup.POST("/", CreateUserHandler)
			usersGroup.DELETE("/:id", DeleteUserHandler)
			usersGroup.PUT("/:id/role", UpdateUserRoleHandler)
		}

		// Processes
		processGroup := protected.Group("/processes")
		{
			processGroup.GET("/", ListProcessesHandler)
			processGroup.DELETE("/:pid", KillProcessHandler)
		}

		// App Store
		appsGroup := protected.Group("/apps")
		{
			appsGroup.GET("/", ListAppsHandler)
			appsGroup.POST("/:slug/install", InstallAppHandler)
			appsGroup.POST("/:slug/uninstall", UninstallAppHandler)
		}

		// Archive
		protected.POST("/files/compress", CompressFilesHandler)
		protected.POST("/files/extract", ExtractArchiveHandler)

		// Cache (Redis/Memcached)
		cacheGroup := protected.Group("/cache")
		{
			cacheGroup.POST("/redis/install", InstallRedisHandler)
			cacheGroup.POST("/memcached/install", InstallMemcachedHandler)
			cacheGroup.GET("/redis/info", GetRedisInfoHandler)
		}

		// Cloud Backup (Rclone)
		rcloneGroup := protected.Group("/rclone")
		{
			rcloneGroup.POST("/install", InstallRcloneHandler)
			rcloneGroup.GET("/remotes", ListRcloneRemotesHandler)
			rcloneGroup.POST("/sync", SyncToCloudHandler)
		}

		// Malware Scanner
		scanGroup := protected.Group("/scan")
		{
			scanGroup.POST("/clamav/install", InstallClamAVHandler)
			scanGroup.POST("/website", ScanWebsiteHandler)
		}

		// Dev Tools Status
		protected.GET("/tools/status", GetDevToolsStatusHandler)

		// PHP Extensions
		protected.GET("/php/extensions", ListPHPExtensionsHandler)
		protected.POST("/php/extensions/install", InstallPHPExtensionHandler)

		// Health Check
		protected.GET("/health/check", HealthCheckHandler)

		// Auto-Heal
		healGroup := protected.Group("/autoheal")
		{
			healGroup.GET("/config", GetAutoHealConfigHandler)
			healGroup.POST("/config", UpdateAutoHealConfigHandler)
			healGroup.POST("/run", RunAutoHealCheckHandler)
		}

		// Panel SSL
		protected.POST("/panel/ssl", EnablePanelSSLHandler)
		protected.GET("/panel/ssl/status", GetPanelSSLStatusHandler)

		// ============================================
		// NEW: Deployment Workflow Routes
		// ============================================
		deployGroup := protected.Group("/deploy")
		{
			deployGroup.GET("/", ListDeploymentsHandler)
			deployGroup.POST("/", CreateDeploymentHandler)
			deployGroup.POST("/:name/trigger", TriggerDeployHandler)
			deployGroup.GET("/:name/logs", GetDeployLogsHandler)
			deployGroup.DELETE("/:name", DeleteDeploymentHandler)
			deployGroup.POST("/:name/auto-deploy", EnableAutoDeployHandler)
		}

		// PM2
		pm2Group := protected.Group("/pm2")
		{
			pm2Group.GET("/", ListPM2ProcessesHandler)
			pm2Group.POST("/:name/:action", PM2ActionHandler)
			pm2Group.GET("/:name/logs", GetPM2LogsHandler)
		}

		// Cron
		cronGroup := protected.Group("/cron")
		{
			cronGroup.GET("/", ListCronsHandler)
			cronGroup.POST("/", CreateCronHandler)
			cronGroup.PUT("/:id", UpdateCronHandler)
			cronGroup.DELETE("/:id", DeleteCronHandler)
		}

	}

	// Public routes
	r.GET("/auth/verify-token", VerifyLoginTokenHandler)
	r.GET("/settings/theme", GetThemeHandler)
	r.POST("/settings/theme", SetThemeHandler)
}
