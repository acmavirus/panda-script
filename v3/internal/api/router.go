package api

import (
	"github.com/gin-gonic/gin"
)


func RegisterRoutes(r *gin.RouterGroup) {
	// Health & Stats
	r.GET("/health", HealthHandler)
	r.GET("/system/stats", SystemStatsHandler)
	
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
	}
}

