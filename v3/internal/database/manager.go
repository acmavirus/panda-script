package database

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
	_ "modernc.org/sqlite"
)

type Database struct {
	Name string `json:"name"`
	Size int64  `json:"size"`
	Path string `json:"path"`
	Type string `json:"type"` // sqlite, mysql, postgres
}

const dbDir = "databases"
const backupDir = "backups"

func init() {
	os.MkdirAll(dbDir, 0755)
	os.MkdirAll(backupDir, 0755)
}

// ListDatabases scans the databases directory (SQLite) and Docker containers (MySQL/Postgres)
func ListDatabases() ([]Database, error) {
	// SQLite
	files, err := os.ReadDir(dbDir)
	if err != nil {
		return nil, err
	}

	var dbs []Database
	for _, file := range files {
		info, err := file.Info()
		if err != nil {
			continue
		}
		if !file.IsDir() && filepath.Ext(file.Name()) == ".db" {
			dbs = append(dbs, Database{
				Name: file.Name(),
				Size: info.Size(),
				Path: filepath.Join(dbDir, file.Name()),
				Type: "sqlite",
			})
		}
	}

	// MySQL (via Docker) - Mock/Simple check
	// We assume container name is "mysql" and root password is "root" (as per App Store default)
	mysqlDBs, _ := listMySQLDatabases()
	dbs = append(dbs, mysqlDBs...)

	return dbs, nil
}

func listMySQLDatabases() ([]Database, error) {
	cmd := "docker exec mysql mysql -uroot -proot -e 'SHOW DATABASES;'"
	out, err := system.Execute(cmd)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(strings.TrimSpace(out), "\n")
	var dbs []Database
	for i, line := range lines {
		if i == 0 { continue } // Skip header
		line = strings.TrimSpace(line)
		if line == "" || line == "information_schema" || line == "mysql" || line == "performance_schema" || line == "sys" {
			continue
		}
		dbs = append(dbs, Database{
			Name: line,
			Type: "mysql",
		})
	}
	return dbs, nil
}

// CreateDatabase creates a new database
func CreateDatabase(name, dbType string) error {
	if dbType == "mysql" {
		cmd := fmt.Sprintf("docker exec mysql mysql -uroot -proot -e 'CREATE DATABASE %s;'", name)
		_, err := system.Execute(cmd)
		return err
	}

	// Default SQLite
	if filepath.Ext(name) != ".db" {
		name += ".db"
	}
	
	path := filepath.Join(dbDir, name)
	if _, err := os.Stat(path); err == nil {
		return fmt.Errorf("database already exists")
	}

	file, err := os.Create(path)
	if err != nil {
		return err
	}
	file.Close()

	// Initialize with a test table
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return err
	}
	defer db.Close()

	_, err = db.Exec("CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)")
	return err
}

// DeleteDatabase removes the database file
func DeleteDatabase(name, dbType string) error {
	if dbType == "mysql" {
		cmd := fmt.Sprintf("docker exec mysql mysql -uroot -proot -e 'DROP DATABASE %s;'", name)
		_, err := system.Execute(cmd)
		return err
	}

	// SQLite
	path := filepath.Join(dbDir, name)
	return os.Remove(path)
}

// ExecuteQuery executes a SQL query on the specified database
func ExecuteQuery(dbName, dbType, query string) ([]map[string]interface{}, error) {
	if dbType == "mysql" {
		cmd := fmt.Sprintf("docker exec -i mysql mysql -uroot -proot -D %s -e '%s' -B", dbName, query)
		out, err := system.Execute(cmd)
		if err != nil {
			return nil, err
		}
		
		lines := strings.Split(strings.TrimSpace(out), "\n")
		if len(lines) == 0 {
			return []map[string]interface{}{}, nil
		}
		
		headers := strings.Split(lines[0], "\t")
		var results []map[string]interface{}
		
		for i := 1; i < len(lines); i++ {
			values := strings.Split(lines[i], "\t")
			row := make(map[string]interface{})
			for j, header := range headers {
				if j < len(values) {
					row[header] = values[j]
				}
			}
			results = append(results, row)
		}
		return results, nil
	}

	path := filepath.Join(dbDir, dbName)
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	defer db.Close()

	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	columns, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	var results []map[string]interface{}
	for rows.Next() {
		// Create a slice of interface{} to hold the values
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, err
		}

		// Create a map for the row
		row := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			b, ok := val.([]byte)
			if ok {
				row[col] = string(b)
			} else {
				row[col] = val
			}
		}
		results = append(results, row)
	}

	return results, nil
}

// BackupDatabase creates a backup of the database
func BackupDatabase(name string) error {
	srcPath := filepath.Join(dbDir, name)
	if _, err := os.Stat(srcPath); os.IsNotExist(err) {
		return fmt.Errorf("database not found")
	}

	timestamp := time.Now().Format("20060102150405")
	dstPath := filepath.Join(backupDir, fmt.Sprintf("%s_%s.bak", name, timestamp))

	input, err := os.ReadFile(srcPath)
	if err != nil {
		return err
	}

	return os.WriteFile(dstPath, input, 0644)
}

// RestoreDatabase restores a database from a backup
func RestoreDatabase(name, backupFile string) error {
	backupPath := filepath.Join(backupDir, backupFile)
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup file not found")
	}

	input, err := os.ReadFile(backupPath)
	if err != nil {
		return err
	}

	dstPath := filepath.Join(dbDir, name)
	return os.WriteFile(dstPath, input, 0644)
}

// ListBackups lists available backups for a database
func ListBackups(name string) ([]string, error) {
	files, err := os.ReadDir(backupDir)
	if err != nil {
		return nil, err
	}

	var backups []string
	prefix := name + "_"
	for _, file := range files {
		if !file.IsDir() && strings.HasPrefix(file.Name(), prefix) && strings.HasSuffix(file.Name(), ".bak") {
			backups = append(backups, file.Name())
		}
	}
	return backups, nil
}
