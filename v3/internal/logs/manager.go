package logs

import (
	"bufio"
	"os"
	"runtime"
)

type LogFile struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

var CommonLogs = []LogFile{
	{Name: "Syslog", Path: "/var/log/syslog"},
	{Name: "Auth Log", Path: "/var/log/auth.log"},
	{Name: "Nginx Access", Path: "/var/log/nginx/access.log"},
	{Name: "Nginx Error", Path: "/var/log/nginx/error.log"},
	{Name: "Panda Script", Path: "/var/log/panda.log"},
}

func init() {
	if runtime.GOOS == "windows" {
		// Mock logs for Windows dev environment
		os.MkdirAll("logs", 0755)
		CommonLogs = []LogFile{
			{Name: "Mock Syslog", Path: "logs/syslog.log"},
			{Name: "Mock Nginx Access", Path: "logs/nginx_access.log"},
			{Name: "Mock Nginx Error", Path: "logs/nginx_error.log"},
		}
		
		// Create dummy files
		for _, log := range CommonLogs {
			if _, err := os.Stat(log.Path); os.IsNotExist(err) {
				os.WriteFile(log.Path, []byte("Mock log entry 1\nMock log entry 2\n"), 0644)
			}
		}
	}
}

func GetLogFiles() []LogFile {
	return CommonLogs
}

func ReadLog(path string, lines int) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var result []string
	scanner := bufio.NewScanner(file)
	
	// Inefficient for huge files, but simple for MVP. 
	// Production should use seek from end.
	for scanner.Scan() {
		result = append(result, scanner.Text())
	}

	if len(result) > lines {
		return result[len(result)-lines:], nil
	}
	return result, nil
}
