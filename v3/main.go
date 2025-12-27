package main

import (
	"embed"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/acmavirus/panda-script/v3/internal/api"
	"github.com/acmavirus/panda-script/v3/internal/db"
)

//go:embed web/dist/*
var frontendAssets embed.FS

func main() {
	// Initialize Database
	db.Init()

	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	r := gin.Default()

	// API Routes
	apiGroup := r.Group("/api")
	api.RegisterRoutes(apiGroup)

	// Serve Frontend
	// If the file exists in the embedded FS, serve it.
	// Otherwise, for SPA, serve index.html for unknown routes (optional)
	
	// Create a sub-filesystem for the dist folder
	distFS, err := fs.Sub(frontendAssets, "web/dist")
	if err != nil {
		fmt.Printf("Warning: Frontend assets not found or failed to load: %v\n", err)
	} else {
		// Serve static files from the embedded FS
		r.StaticFS("/panda", http.FS(distFS))
		
		// Redirect root /panda to /panda/ (if needed)
		r.GET("/panda", func(c *gin.Context) {
			c.Redirect(http.StatusMovedPermanently, "/panda/")
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
