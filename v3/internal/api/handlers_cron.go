package api

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/gin-gonic/gin"
)

// SyncCronJobs updates the system cron configuration based on the database
func SyncCronJobs() error {
	if runtime.GOOS == "windows" {
		return nil
	}

	var crons []db.Cron
	db.DB.Find(&crons)

	var sb strings.Builder
	sb.WriteString("# Panda Panel Managed Cron Jobs - DO NOT EDIT MANUALLY\n")
	sb.WriteString("# Generated at " + time.Now().Format("2006-01-02 15:04:05") + "\n\n")

	for _, cron := range crons {
		if !cron.Enabled {
			continue
		}
		// Format: expression user command
		// We use root for now as the panel runs as root
		sb.WriteString(fmt.Sprintf("%s root %s # %s\n", cron.Expression, cron.Command, cron.Name))
	}

	cronPath := "/etc/cron.d/panda"
	// Check if directory exists
	if _, err := os.Stat("/etc/cron.d"); os.IsNotExist(err) {
		return fmt.Errorf("/etc/cron.d does not exist, cron synchronization aborted")
	}

	err := os.WriteFile(cronPath, []byte(sb.String()), 0644)
	if err != nil {
		return fmt.Errorf("failed to write cron file: %v", err)
	}

	return nil
}

func ListCronsHandler(c *gin.Context) {
	var crons []db.Cron
	db.DB.Find(&crons)
	c.JSON(http.StatusOK, crons)
}

func CreateCronHandler(c *gin.Context) {
	var req struct {
		Name        string `json:"name" binding:"required"`
		Expression  string `json:"expression" binding:"required"`
		Command     string `json:"command" binding:"required"`
		Description string `json:"description"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	cron := db.Cron{
		Name:        req.Name,
		Expression:  req.Expression,
		Command:     req.Command,
		Description: req.Description,
		Enabled:     true,
	}

	if err := db.DB.Create(&cron).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create cron job"})
		return
	}

	SyncCronJobs()
	c.JSON(http.StatusCreated, cron)
}

func UpdateCronHandler(c *gin.Context) {
	id := c.Param("id")
	var cron db.Cron
	if err := db.DB.First(&cron, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Cron job not found"})
		return
	}

	var req struct {
		Name        string `json:"name"`
		Expression  string `json:"expression"`
		Command     string `json:"command"`
		Description string `json:"description"`
		Enabled     *bool  `json:"enabled"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		cron.Name = req.Name
	}
	if req.Expression != "" {
		cron.Expression = req.Expression
	}
	if req.Command != "" {
		cron.Command = req.Command
	}
	if req.Description != "" {
		cron.Description = req.Description
	}
	if req.Enabled != nil {
		cron.Enabled = *req.Enabled
	}

	db.DB.Save(&cron)
	SyncCronJobs()
	c.JSON(http.StatusOK, cron)
}

func DeleteCronHandler(c *gin.Context) {
	id := c.Param("id")
	if err := db.DB.Delete(&db.Cron{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete cron job"})
		return
	}

	SyncCronJobs()
	c.JSON(http.StatusOK, gin.H{"message": "Cron job deleted"})
}
