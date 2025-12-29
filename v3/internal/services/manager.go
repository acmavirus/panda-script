package services

import (
	"fmt"
	"runtime"
	"strings"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type Service struct {
	Name        string `json:"name"`
	Status      string `json:"status"` // running, stopped, failed, inactive
	Enabled     bool   `json:"enabled"`
	Description string `json:"description,omitempty"`
}

// Known services that Panda Script manages
var knownServices = []string{
	"nginx",
	"php8.3-fpm",
	"php8.2-fpm",
	"php8.1-fpm",
	"php8.0-fpm",
	"php7.4-fpm",
	"php-fpm",
	"mysql",
	"mariadb",
	"docker",
	"redis",
	"memcached",
	"ssh",
	"sshd",
	"ufw",
	"fail2ban",
}

func checkLinux() error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("service management requires Linux with systemd")
	}
	return nil
}

// ListServices returns all known services and their status
func ListServices() ([]Service, error) {
	if runtime.GOOS == "windows" {
		return []Service{
			{Name: "nginx", Status: "mock", Enabled: true},
			{Name: "php-fpm", Status: "mock", Enabled: true},
		}, nil
	}

	var services []Service

	// Check systemd services
	for _, name := range knownServices {
		svc, err := GetStatus(name)
		if err != nil {
			continue // Service not installed
		}
		services = append(services, *svc)
	}

	// Also check Docker containers for database services
	dockerServices := map[string]string{
		"panda-mysql":      "MySQL (Docker)",
		"panda-redis":      "Redis (Docker)",
		"panda-postgresql": "PostgreSQL (Docker)",
		"panda-mongodb":    "MongoDB (Docker)",
	}

	for containerName, displayName := range dockerServices {
		out, err := system.Execute(fmt.Sprintf("docker inspect -f '{{.State.Status}}' %s 2>/dev/null", containerName))
		if err == nil {
			status := strings.TrimSpace(out)
			if status != "" {
				svc := Service{
					Name:        displayName,
					Status:      status, // "running", "exited", etc.
					Enabled:     true,
					Description: fmt.Sprintf("Docker container: %s", containerName),
				}
				services = append(services, svc)
			}
		}
	}

	return services, nil
}

// GetStatus returns the status of a specific service
func GetStatus(name string) (*Service, error) {
	if runtime.GOOS == "windows" {
		return &Service{
			Name:    name,
			Status:  "mock",
			Enabled: true,
		}, nil
	}

	// Check if service exists
	checkCmd := fmt.Sprintf("systemctl list-unit-files %s.service 2>/dev/null | grep -q %s", name, name)
	if _, err := system.Execute(checkCmd); err != nil {
		return nil, fmt.Errorf("service not found: %s", name)
	}

	svc := &Service{Name: name}

	// Get active status
	out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", name))
	svc.Status = strings.TrimSpace(out)
	if svc.Status == "" {
		svc.Status = "unknown"
	}

	// Get enabled status
	out, _ = system.Execute(fmt.Sprintf("systemctl is-enabled %s 2>/dev/null", name))
	svc.Enabled = strings.TrimSpace(out) == "enabled"

	// Get description
	out, _ = system.Execute(fmt.Sprintf("systemctl show %s --property=Description --value 2>/dev/null", name))
	svc.Description = strings.TrimSpace(out)

	return svc, nil
}

// StartService starts a service
func StartService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl start %s", name)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to start %s: %v", name, err)
	}

	return nil
}

// StopService stops a service
func StopService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl stop %s", name)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to stop %s: %v", name, err)
	}

	return nil
}

// RestartService restarts a service
func RestartService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl restart %s", name)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to restart %s: %v", name, err)
	}

	return nil
}

// ReloadService reloads a service configuration
func ReloadService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl reload %s", name)
	if _, err := system.Execute(cmd); err != nil {
		// Fallback to restart if reload not supported
		return RestartService(name)
	}

	return nil
}

// EnableService enables a service to start on boot
func EnableService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl enable %s", name)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to enable %s: %v", name, err)
	}

	return nil
}

// DisableService disables a service from starting on boot
func DisableService(name string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl disable %s", name)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to disable %s: %v", name, err)
	}

	return nil
}

// GetJournalLogs returns the recent journal logs for a service
func GetJournalLogs(name string, lines int) (string, error) {
	if runtime.GOOS == "windows" {
		return "Mock logs (Windows)", nil
	}

	if lines <= 0 {
		lines = 50
	}

	cmd := fmt.Sprintf("journalctl -u %s --no-pager -n %d 2>/dev/null", name, lines)
	out, err := system.Execute(cmd)
	if err != nil {
		return "", fmt.Errorf("failed to get logs for %s: %v", name, err)
	}

	return out, nil
}

// IsRunning checks if a service is currently running
func IsRunning(name string) bool {
	if runtime.GOOS == "windows" {
		return false
	}

	out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", name))
	return strings.TrimSpace(out) == "active"
}
