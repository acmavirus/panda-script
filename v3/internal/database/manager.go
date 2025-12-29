package database

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
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

func runMySQLCommand(query string, dbName string, batch bool) (string, error) {
	// 1. Try local mysql (native)
	args := "-uroot"
	if batch {
		args += " -B"
	}
	
	cmd := ""
	if dbName != "" {
		cmd = fmt.Sprintf("mysql %s -e \"%s\" %s", args, query, dbName)
	} else {
		cmd = fmt.Sprintf("mysql %s -e \"%s\"", args, query)
	}

	out, err := system.Execute(cmd)
	if err == nil {
		return out, nil
	}

	// 2. Try docker panda-mysql
	if dbName != "" {
		cmd = fmt.Sprintf("docker exec panda-mysql mysql -uroot -proot %s -e \"%s\" %s", args, query, dbName)
	} else {
		cmd = fmt.Sprintf("docker exec panda-mysql mysql -uroot -proot %s -e \"%s\"", args, query)
	}
	out, err = system.Execute(cmd)
	if err == nil {
		return out, nil
	}

	// 3. Try docker mysql (fallback name)
	if dbName != "" {
		cmd = fmt.Sprintf("docker exec mysql mysql -uroot -proot %s -e \"%s\" %s", args, query, dbName)
	} else {
		cmd = fmt.Sprintf("docker exec mysql mysql -uroot -proot %s -e \"%s\"", args, query)
	}
	return system.Execute(cmd)
}

func ListDatabases() ([]Database, error) {
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

	mysqlDBs, _ := listMySQLDatabases()
	dbs = append(dbs, mysqlDBs...)

	return dbs, nil
}

func listMySQLDatabases() ([]Database, error) {
	out, err := runMySQLCommand("SHOW DATABASES;", "", false)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(strings.TrimSpace(out), "\n")
	var dbs []Database
	for i, line := range lines {
		if i == 0 {
			continue
		}
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

func CreateDatabase(name, dbType string) error {
	if dbType == "mysql" {
		_, err := runMySQLCommand(fmt.Sprintf("CREATE DATABASE %s;", name), "", false)
		return err
	}

	if filepath.Ext(name) != ".db" {
		name += ".db"
	}

	path := filepath.Join(dbDir, name)
	if _, err := os.Stat(path); err == nil {
		return fmt.Errorf("database already exists")
	}

	// For SQLite, we can just create the file and GORM will handle it if we ever connect to it
	// But to stay within the "Unified" approach, we don't open a separate connection
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	f.Close()
	return nil
}

func DeleteDatabase(name, dbType string) error {
	if dbType == "mysql" {
		_, err := runMySQLCommand(fmt.Sprintf("DROP DATABASE %s;", name), "", false)
		return err
	}
	path := filepath.Join(dbDir, name)
	return os.Remove(path)
}

func ExecuteQuery(dbName, dbType, query string) ([]map[string]interface{}, error) {
	if dbType == "mysql" {
		out, err := runMySQLCommand(query, dbName, true)
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

	// For SQLite queries on dynamic files, we'll use GORM's Raw method but we need a connection to THAT file.
	// This is tricky if we want to avoid sql.Open.
	// BUT, if we use the GORM driver's connection, we might still trigger the same issue.
	// Let's try to use GORM to open the temp connection - GORM might handle the driver better.
	// Actually, gorm.Open(sqlite.Open(path)) uses the same "sqlite" driver.

	// If we can't avoid registration, let's try to use a DIFFERENT driver for manual calls?
	// No.

	// WAIT! I know. If the panic happens during INIT, it means the binary just won't start.
	// If I use ONLY ONE package that registers "sqlite", it will work.

	// I'll try to REMOVE the "database/sql" use and use the existing db.DB for panel data,
	// and for external sqlite files, I'll use system commands (sqlite3 CLI) which is much safer and avoids linking conflicts.

	out, err := system.Execute(fmt.Sprintf("sqlite3 -json %s \"%s\"", filepath.Join(dbDir, dbName), query))
	if err != nil {
		return nil, err
	}

	// sqlite3 -json returns a JSON array
	var results []map[string]interface{}
	if err := json.Unmarshal([]byte(out), &results); err != nil {
		// If not json (maybe empty), return empty
		return []map[string]interface{}{}, nil
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
