package main

import (
	"embed"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"

	"github.com/acmavirus/panda-script/v3/internal/api"
	"github.com/acmavirus/panda-script/v3/internal/cli"
	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/spf13/cobra"
)

//go:embed web/dist/*
var frontendAssets embed.FS

var rootCmd = &cobra.Command{
	Use:   "panda",
	Short: "🐼 Panda Script - Server Management Tool",
	Long:  "Panda Script v3.0 - A powerful server management tool with Web Dashboard and CLI",
	Run: func(cmd *cobra.Command, args []string) {
		startWebServer()
	},
}

var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Start the web dashboard server",
	Run: func(cmd *cobra.Command, args []string) {
		startWebServer()
	},
}

var menuCmd = &cobra.Command{
	Use:   "menu",
	Short: "Open interactive CLI menu",
	Run: func(cmd *cobra.Command, args []string) {
		cli.ShowMenu()
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🐼 Panda Script v3.0.0")
	},
}

func init() {
	rootCmd.AddCommand(serveCmd)
	rootCmd.AddCommand(menuCmd)
	rootCmd.AddCommand(versionCmd)

	// Add CLI command groups
	cli.RegisterWebsiteCommands(rootCmd)
	cli.RegisterDatabaseCommands(rootCmd)
	cli.RegisterBackupCommands(rootCmd)
	cli.RegisterSecurityCommands(rootCmd)
	cli.RegisterDoctorCommands(rootCmd)
	cli.RegisterPanelCommands(rootCmd)
}

func main() {
	// Initialize Database
	db.Init()

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func startWebServer() {
	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	r := gin.Default()

	// API Routes
	apiGroup := r.Group("/api")
	api.RegisterRoutes(apiGroup)

	// Serve Frontend
	distFS, err := fs.Sub(frontendAssets, "web/dist")
	if err != nil {
		fmt.Printf("Warning: Frontend assets not found: %v\n", err)
	} else {
		// Read index.html for SPA fallback
		indexHTML, _ := fs.ReadFile(distFS, "index.html")

		// Serve assets subfolder
		assetsFS, _ := fs.Sub(distFS, "assets")
		r.StaticFS("/panda/assets", http.FS(assetsFS))

		// Serve other static files (vite.svg, etc.)
		r.GET("/panda/vite.svg", func(c *gin.Context) {
			data, _ := fs.ReadFile(distFS, "vite.svg")
			c.Data(http.StatusOK, "image/svg+xml", data)
		})

		// Serve index.html for /panda/
		r.GET("/panda", func(c *gin.Context) {
			c.Redirect(http.StatusMovedPermanently, "/panda/")
		})

		r.GET("/panda/", func(c *gin.Context) {
			c.Data(http.StatusOK, "text/html; charset=utf-8", indexHTML)
		})

		// Catch-all for SPA routes
		r.NoRoute(func(c *gin.Context) {
			path := c.Request.URL.Path
			// If it's a /panda/* route (but not /api), serve index.html
			if len(path) >= 6 && path[:6] == "/panda" {
				c.Data(http.StatusOK, "text/html; charset=utf-8", indexHTML)
				return
			}
			c.JSON(http.StatusNotFound, gin.H{"error": "Not found"})
		})
	}

	port := os.Getenv("PANDA_PORT")
	if port == "" {
		port = "8888"
	}

	fmt.Printf("🐼 Panda Script v3.0.0 is starting...\n")
	fmt.Printf("🚀 Web Dashboard: http://localhost:%s/panda\n", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
