package logs

import (
	"bufio"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type AccessLogEntry struct {
	IP       string    `json:"ip"`
	Time     time.Time `json:"time"`
	Method   string    `json:"method"`
	Path     string    `json:"path"`
	Status   int       `json:"status"`
	Agent    string    `json:"agent"`
	IsBot    bool      `json:"is_bot"`
	Location string    `json:"location"`
}

type SecurityLogEntry struct {
	Time    string `json:"time"`
	Type    string `json:"type"`   // SSH, Login, Sudo
	Status  string `json:"status"` // Success, Failed
	User    string `json:"user"`
	IP      string `json:"ip"`
	Message string `json:"message"`
}

var (
	// Example Nginx: 127.0.0.1 - - [29/Dec/2025:03:35:12 +0700] "GET /api/health HTTP/1.1" 200 45 "-" "Mozilla/5.0..."
	nginxRegex = regexp.MustCompile(`^(\S+) \S+ \S+ \[(.*?)\] "(.*?) (.*?) .*?" (\d+) \d+ ".*?" "(.*?)"`)

	// Example Auth: Dec 29 03:35:12 panda-vps sshd[1234]: Failed password for root from 1.2.3.4 port 5678 ssh2
	sshFailedRegex  = regexp.MustCompile(`Failed password for (?:invalid user )?(\S+) from (\S+) port \d+`)
	sshSuccessRegex = regexp.MustCompile(`Accepted password for (\S+) from (\S+) port \d+`)
)

func ParseAccessLogs(limit int) ([]AccessLogEntry, error) {
	path := "/var/log/nginx/access.log"
	if _, err := os.Stat(path); os.IsNotExist(err) {
		path = "logs/nginx_access.log"
	}
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return []AccessLogEntry{}, nil
	}

	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var entries []AccessLogEntry
	scanner := bufio.NewScanner(file)

	var lines []string
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	start := 0
	if len(lines) > limit {
		start = len(lines) - limit
	}

	for i := len(lines) - 1; i >= start; i-- {
		line := lines[i]
		matches := nginxRegex.FindStringSubmatch(line)
		if len(matches) > 6 {
			status, _ := strconv.Atoi(matches[5])
			entry := AccessLogEntry{
				IP:     matches[1],
				Method: matches[3],
				Path:   matches[4],
				Status: status,
				Agent:  matches[6],
			}

			// Parse time (Nginx format: 02/Jan/2006:15:04:05 -0700)
			t, err := time.Parse("02/Jan/2006:15:04:05 -0700", matches[2])
			if err == nil {
				entry.Time = t
			}

			// Bot detection
			lowAgent := strings.ToLower(entry.Agent)
			botKeywords := []string{"bot", "spider", "crawler", "go-http-client", "python-requests", "curl", "wget", "headless"}
			for _, keyword := range botKeywords {
				if strings.Contains(lowAgent, keyword) {
					entry.IsBot = true
					break
				}
			}

			entries = append(entries, entry)
		}
	}

	return entries, nil
}

func ParseSecurityLogs(limit int) ([]SecurityLogEntry, error) {
	path := "/var/log/auth.log"
	if _, err := os.Stat(path); os.IsNotExist(err) {
		path = "/var/log/syslog"
	}
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return []SecurityLogEntry{}, nil
	}

	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var entries []SecurityLogEntry
	scanner := bufio.NewScanner(file)

	var lines []string
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	start := 0
	if len(lines) > limit {
		start = len(lines) - limit
	}

	for i := len(lines) - 1; i >= start; i-- {
		line := lines[i]

		if matches := sshFailedRegex.FindStringSubmatch(line); len(matches) > 2 {
			entries = append(entries, SecurityLogEntry{
				Time:    extractTime(line),
				Type:    "SSH",
				Status:  "Failed",
				User:    matches[1],
				IP:      matches[2],
				Message: "Brute force attempt detected",
			})
		} else if matches := sshSuccessRegex.FindStringSubmatch(line); len(matches) > 2 {
			entries = append(entries, SecurityLogEntry{
				Time:    extractTime(line),
				Type:    "SSH",
				Status:  "Success",
				User:    matches[1],
				IP:      matches[2],
				Message: "Successful login",
			})
		}
	}

	return entries, nil
}

func extractTime(line string) string {
	if len(line) < 15 {
		return ""
	}
	return line[:15]
}
