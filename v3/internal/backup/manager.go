package backup

import (
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

const (
	BackupDir = "/opt/panda/backups"
	WebRoot   = "/var/www"
)

type BackupInfo struct {
	Name      string    `json:"name"`
	Path      string    `json:"path"`
	Size      int64     `json:"size"`
	Type      string    `json:"type"` // website, database, full, config
	CreatedAt time.Time `json:"created_at"`
}

func getBackupDir() string {
	if runtime.GOOS == "windows" {
		return "backups"
	}
	return BackupDir
}

func getWebRoot() string {
	if runtime.GOOS == "windows" {
		return "www"
	}
	return WebRoot
}

func init() {
	os.MkdirAll(getBackupDir(), 0755)
}

// BackupWebsite creates a backup of a specific website
func BackupWebsite(domain string) (*BackupInfo, error) {
	timestamp := time.Now().Format("20060102_150405")
	backupName := fmt.Sprintf("%s_%s.tar.gz", domain, timestamp)
	backupPath := filepath.Join(getBackupDir(), backupName)

	websitePath := filepath.Join(getWebRoot(), domain)
	if _, err := os.Stat(websitePath); os.IsNotExist(err) {
		return nil, fmt.Errorf("website not found: %s", domain)
	}

	// Use tar command to create backup
	cmd := fmt.Sprintf("tar -czf %s -C %s %s", backupPath, getWebRoot(), domain)
	if _, err := system.Execute(cmd); err != nil {
		return nil, fmt.Errorf("backup failed: %v", err)
	}

	info, err := os.Stat(backupPath)
	if err != nil {
		return nil, err
	}

	return &BackupInfo{
		Name:      backupName,
		Path:      backupPath,
		Size:      info.Size(),
		Type:      "website",
		CreatedAt: time.Now(),
	}, nil
}

// BackupDatabase creates a backup of a MySQL database
func BackupDatabase(name string) (*BackupInfo, error) {
	if runtime.GOOS == "windows" {
		return nil, fmt.Errorf("database backup not supported on Windows")
	}

	timestamp := time.Now().Format("20060102_150405")
	backupName := fmt.Sprintf("%s_db_%s.sql.gz", name, timestamp)
	backupPath := filepath.Join(getBackupDir(), backupName)

	// Use mysqldump and gzip
	cmd := fmt.Sprintf("mysqldump %s 2>/dev/null | gzip > %s", name, backupPath)
	if _, err := system.Execute(cmd); err != nil {
		return nil, fmt.Errorf("database backup failed: %v", err)
	}

	info, err := os.Stat(backupPath)
	if err != nil {
		return nil, err
	}

	return &BackupInfo{
		Name:      backupName,
		Path:      backupPath,
		Size:      info.Size(),
		Type:      "database",
		CreatedAt: time.Now(),
	}, nil
}

// BackupAll creates a full system backup
func BackupAll() (*BackupInfo, error) {
	timestamp := time.Now().Format("20060102_150405")
	backupName := fmt.Sprintf("full_backup_%s.tar.gz", timestamp)
	backupPath := filepath.Join(getBackupDir(), backupName)

	// Backup websites
	cmd := fmt.Sprintf("tar -czf %s %s 2>/dev/null", backupPath, getWebRoot())
	if _, err := system.Execute(cmd); err != nil {
		return nil, fmt.Errorf("full backup failed: %v", err)
	}

	// Backup configs (nginx, php)
	configBackupName := fmt.Sprintf("config_backup_%s.tar.gz", timestamp)
	configBackupPath := filepath.Join(getBackupDir(), configBackupName)
	if runtime.GOOS != "windows" {
		system.Execute(fmt.Sprintf("tar -czf %s /etc/nginx /etc/php 2>/dev/null", configBackupPath))
	}

	// Backup all databases
	if runtime.GOOS != "windows" {
		out, _ := system.Execute("mysql -e 'SHOW DATABASES' 2>/dev/null | grep -vE '^(Database|information_schema|performance_schema|mysql|sys)$'")
		databases := strings.Split(strings.TrimSpace(out), "\n")
		for _, db := range databases {
			db = strings.TrimSpace(db)
			if db != "" {
				BackupDatabase(db)
			}
		}
	}

	// Generate MD5 hash
	system.Execute(fmt.Sprintf("md5sum %s > %s.md5 2>/dev/null", backupPath, backupPath))

	info, err := os.Stat(backupPath)
	if err != nil {
		return nil, err
	}

	return &BackupInfo{
		Name:      backupName,
		Path:      backupPath,
		Size:      info.Size(),
		Type:      "full",
		CreatedAt: time.Now(),
	}, nil
}

// RestoreBackup restores from a backup file
func RestoreBackup(backupPath string) error {
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup file not found: %s", backupPath)
	}

	ext := filepath.Ext(backupPath)

	// Check if it's a SQL backup
	if strings.HasSuffix(backupPath, ".sql.gz") {
		// Extract database name from filename
		baseName := filepath.Base(backupPath)
		parts := strings.Split(baseName, "_db_")
		if len(parts) < 2 {
			return fmt.Errorf("invalid database backup filename")
		}
		dbName := parts[0]

		cmd := fmt.Sprintf("gunzip -c %s | mysql %s", backupPath, dbName)
		if _, err := system.Execute(cmd); err != nil {
			return fmt.Errorf("database restore failed: %v", err)
		}
		return nil
	}

	// Tar backup
	if ext == ".gz" || strings.HasSuffix(backupPath, ".tar.gz") {
		cmd := fmt.Sprintf("tar -xzf %s -C /", backupPath)
		if _, err := system.Execute(cmd); err != nil {
			return fmt.Errorf("restore failed: %v", err)
		}
		return nil
	}

	return fmt.Errorf("unsupported backup format: %s", ext)
}

// ListBackups returns all available backups
func ListBackups() ([]BackupInfo, error) {
	backupDir := getBackupDir()
	files, err := os.ReadDir(backupDir)
	if err != nil {
		return []BackupInfo{}, nil
	}

	var backups []BackupInfo
	for _, file := range files {
		if file.IsDir() {
			continue
		}

		info, err := file.Info()
		if err != nil {
			continue
		}

		// Determine type
		backupType := "unknown"
		name := file.Name()
		if strings.Contains(name, "_db_") {
			backupType = "database"
		} else if strings.HasPrefix(name, "full_backup_") {
			backupType = "full"
		} else if strings.HasPrefix(name, "config_backup_") {
			backupType = "config"
		} else if strings.HasSuffix(name, ".tar.gz") {
			backupType = "website"
		}

		// Skip checksum files
		if strings.HasSuffix(name, ".md5") {
			continue
		}

		backups = append(backups, BackupInfo{
			Name:      name,
			Path:      filepath.Join(backupDir, name),
			Size:      info.Size(),
			Type:      backupType,
			CreatedAt: info.ModTime(),
		})
	}

	return backups, nil
}

// CleanupOldBackups removes backups older than specified days
func CleanupOldBackups(days int) (int, error) {
	backupDir := getBackupDir()
	cutoff := time.Now().AddDate(0, 0, -days)

	files, err := os.ReadDir(backupDir)
	if err != nil {
		return 0, err
	}

	deleted := 0
	for _, file := range files {
		if file.IsDir() {
			continue
		}

		info, err := file.Info()
		if err != nil {
			continue
		}

		if info.ModTime().Before(cutoff) {
			path := filepath.Join(backupDir, file.Name())
			if err := os.Remove(path); err == nil {
				deleted++
			}
		}
	}

	return deleted, nil
}

// Helper to copy file with gzip compression
func compressFile(src, dst string) error {
	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()

	gzWriter := gzip.NewWriter(destination)
	defer gzWriter.Close()

	_, err = io.Copy(gzWriter, source)
	return err
}
