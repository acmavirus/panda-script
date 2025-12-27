package php

import (
	"fmt"
	"os"
	"regexp"
	"runtime"
	"strings"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type PHPVersion struct {
	Version   string `json:"version"`
	Status    string `json:"status"` // running, stopped, inactive
	IsDefault bool   `json:"is_default"`
	FPMSocket string `json:"fpm_socket"`
}

type PHPConfig struct {
	Version           string `json:"version"`
	MemoryLimit       string `json:"memory_limit"`
	MaxExecutionTime  int    `json:"max_execution_time"`
	UploadMaxFilesize string `json:"upload_max_filesize"`
	PostMaxSize       string `json:"post_max_size"`
	OpcacheEnabled    bool   `json:"opcache_enabled"`
	OpcacheMemory     int    `json:"opcache_memory"`
}

var supportedVersions = []string{"8.4", "8.3", "8.2", "8.1", "8.0", "7.4"}

func checkLinux() error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("PHP management requires Linux")
	}
	return nil
}

// InstallVersion installs a specific PHP version
func InstallVersion(version string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	// Validate version
	validVersion := false
	for _, v := range supportedVersions {
		if v == version {
			validVersion = true
			break
		}
	}
	if !validVersion {
		return fmt.Errorf("unsupported PHP version: %s", version)
	}

	// Detect distro and install
	if isDebian() {
		return installPHPDebian(version)
	} else if isRHEL() {
		return installPHPRHEL(version)
	}

	return fmt.Errorf("unsupported Linux distribution")
}

func isDebian() bool {
	_, err := os.Stat("/etc/debian_version")
	return err == nil
}

func isRHEL() bool {
	_, err := os.Stat("/etc/redhat-release")
	return err == nil
}

func installPHPDebian(version string) error {
	// Add PHP repository (ondrej/php for Ubuntu, sury for Debian)
	out, _ := system.Execute("which add-apt-repository")
	if strings.TrimSpace(out) != "" {
		system.Execute("add-apt-repository -y ppa:ondrej/php 2>/dev/null")
	} else {
		// Debian
		system.Execute("apt-get install -y apt-transport-https lsb-release ca-certificates curl")
		system.Execute("curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor > /usr/share/keyrings/php.gpg")
		system.Execute(`echo "deb [signed-by=/usr/share/keyrings/php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list`)
	}

	system.Execute("apt-get update -y")

	packages := fmt.Sprintf("php%s-fpm php%s-cli php%s-common php%s-mysql php%s-curl php%s-gd php%s-mbstring php%s-xml php%s-zip php%s-bcmath php%s-intl php%s-opcache php%s-redis php%s-imagick",
		version, version, version, version, version, version, version, version, version, version, version, version, version, version)

	cmd := fmt.Sprintf("apt-get install -y %s", packages)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to install PHP %s: %v", version, err)
	}

	// Enable and start PHP-FPM
	system.Execute(fmt.Sprintf("systemctl enable php%s-fpm", version))
	system.Execute(fmt.Sprintf("systemctl start php%s-fpm", version))

	return nil
}

func installPHPRHEL(version string) error {
	// Install Remi repository
	system.Execute("dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm 2>/dev/null")
	system.Execute("dnf module reset php -y 2>/dev/null")
	system.Execute(fmt.Sprintf("dnf module enable php:remi-%s -y 2>/dev/null", version))

	cmd := "dnf install -y php php-fpm php-cli php-common php-mysqlnd php-curl php-gd php-mbstring php-xml php-zip php-bcmath php-intl php-opcache php-redis php-imagick"
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to install PHP: %v", err)
	}

	system.Execute("systemctl enable php-fpm")
	system.Execute("systemctl start php-fpm")

	return nil
}

// ListVersions returns all installed PHP versions
func ListVersions() ([]PHPVersion, error) {
	if runtime.GOOS == "windows" {
		return []PHPVersion{
			{Version: "8.3", Status: "mock", IsDefault: true, FPMSocket: "mock"},
		}, nil
	}

	var versions []PHPVersion

	// Check default PHP
	defaultVersion := ""
	out, _ := system.Execute("php -v 2>/dev/null | head -1")
	re := regexp.MustCompile(`PHP (\d+\.\d+)`)
	if matches := re.FindStringSubmatch(out); len(matches) > 1 {
		defaultVersion = matches[1]
	}

	// Check each version
	for _, ver := range supportedVersions {
		status := "inactive"
		socket := ""

		// Check if FPM is running
		checkCmd := fmt.Sprintf("systemctl is-active php%s-fpm 2>/dev/null", ver)
		out, _ := system.Execute(checkCmd)
		out = strings.TrimSpace(out)

		if out == "active" {
			status = "running"
		} else if out == "inactive" {
			status = "stopped"
		} else {
			// Check if installed but not as service
			binCheck := fmt.Sprintf("which php%s 2>/dev/null", ver)
			if binOut, _ := system.Execute(binCheck); strings.TrimSpace(binOut) != "" {
				status = "installed"
			} else {
				continue // Not installed
			}
		}

		socket = fmt.Sprintf("/var/run/php/php%s-fpm.sock", ver)

		versions = append(versions, PHPVersion{
			Version:   ver,
			Status:    status,
			IsDefault: ver == defaultVersion,
			FPMSocket: socket,
		})
	}

	return versions, nil
}

// SwitchVersion changes the default PHP version
func SwitchVersion(version string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("update-alternatives --set php /usr/bin/php%s 2>/dev/null", version)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to switch to PHP %s: %v", version, err)
	}

	return nil
}

// GetConfig returns the PHP configuration for a version
func GetConfig(version string) (*PHPConfig, error) {
	if runtime.GOOS == "windows" {
		return &PHPConfig{
			Version:           version,
			MemoryLimit:       "256M",
			MaxExecutionTime:  300,
			UploadMaxFilesize: "100M",
			PostMaxSize:       "100M",
			OpcacheEnabled:    true,
			OpcacheMemory:     128,
		}, nil
	}

	// Find php.ini
	iniPath := fmt.Sprintf("/etc/php/%s/fpm/php.ini", version)
	if _, err := os.Stat(iniPath); os.IsNotExist(err) {
		iniPath = "/etc/php.ini"
	}

	content, err := os.ReadFile(iniPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read php.ini: %v", err)
	}

	config := &PHPConfig{Version: version}
	lines := strings.Split(string(content), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, ";") {
			continue
		}

		if strings.HasPrefix(line, "memory_limit") {
			parts := strings.Split(line, "=")
			if len(parts) == 2 {
				config.MemoryLimit = strings.TrimSpace(parts[1])
			}
		} else if strings.HasPrefix(line, "max_execution_time") {
			parts := strings.Split(line, "=")
			if len(parts) == 2 {
				fmt.Sscanf(strings.TrimSpace(parts[1]), "%d", &config.MaxExecutionTime)
			}
		} else if strings.HasPrefix(line, "upload_max_filesize") {
			parts := strings.Split(line, "=")
			if len(parts) == 2 {
				config.UploadMaxFilesize = strings.TrimSpace(parts[1])
			}
		} else if strings.HasPrefix(line, "post_max_size") {
			parts := strings.Split(line, "=")
			if len(parts) == 2 {
				config.PostMaxSize = strings.TrimSpace(parts[1])
			}
		} else if strings.HasPrefix(line, "opcache.enable=") {
			config.OpcacheEnabled = strings.Contains(line, "1")
		} else if strings.HasPrefix(line, "opcache.memory_consumption") {
			parts := strings.Split(line, "=")
			if len(parts) == 2 {
				fmt.Sscanf(strings.TrimSpace(parts[1]), "%d", &config.OpcacheMemory)
			}
		}
	}

	return config, nil
}

// UpdateConfig updates PHP configuration
func UpdateConfig(version string, config PHPConfig) error {
	if err := checkLinux(); err != nil {
		return err
	}

	iniPath := fmt.Sprintf("/etc/php/%s/fpm/php.ini", version)
	if _, err := os.Stat(iniPath); os.IsNotExist(err) {
		iniPath = "/etc/php.ini"
	}

	// Use sed to update values
	updates := map[string]string{
		"memory_limit":        config.MemoryLimit,
		"max_execution_time":  fmt.Sprintf("%d", config.MaxExecutionTime),
		"upload_max_filesize": config.UploadMaxFilesize,
		"post_max_size":       config.PostMaxSize,
	}

	for key, value := range updates {
		cmd := fmt.Sprintf(`sed -i "s/^%s =.*/%s = %s/" %s`, key, key, value, iniPath)
		system.Execute(cmd)
	}

	// Handle opcache
	if config.OpcacheEnabled {
		system.Execute(fmt.Sprintf(`sed -i "s/^;*opcache.enable=.*/opcache.enable=1/" %s`, iniPath))
	} else {
		system.Execute(fmt.Sprintf(`sed -i "s/^;*opcache.enable=.*/opcache.enable=0/" %s`, iniPath))
	}

	if config.OpcacheMemory > 0 {
		system.Execute(fmt.Sprintf(`sed -i "s/^;*opcache.memory_consumption=.*/opcache.memory_consumption=%d/" %s`, config.OpcacheMemory, iniPath))
	}

	// Restart PHP-FPM
	system.Execute(fmt.Sprintf("systemctl restart php%s-fpm 2>/dev/null || systemctl restart php-fpm", version))

	return nil
}

// GetStatus returns the status of all PHP-FPM processes
func GetStatus() ([]PHPVersion, error) {
	return ListVersions()
}

// RestartFPM restarts PHP-FPM for a specific version
func RestartFPM(version string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("systemctl restart php%s-fpm 2>/dev/null || systemctl restart php-fpm", version)
	_, err := system.Execute(cmd)
	return err
}
