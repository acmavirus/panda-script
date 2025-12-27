package security

import (
	"fmt"
	"regexp"
	"runtime"
	"strconv"
	"strings"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type FirewallRule struct {
	ID     int    `json:"id"`
	To     string `json:"to"`     // port or service
	Action string `json:"action"` // ALLOW, DENY
	From   string `json:"from"`   // IP or Anywhere
}

type FirewallStatus struct {
	Enabled bool           `json:"enabled"`
	Rules   []FirewallRule `json:"rules"`
}

func checkLinux() error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("firewall management requires Linux with UFW")
	}
	return nil
}

// GetStatus returns the current firewall status
func GetStatus() (*FirewallStatus, error) {
	if runtime.GOOS == "windows" {
		return &FirewallStatus{
			Enabled: false,
			Rules:   []FirewallRule{},
		}, nil
	}

	out, _ := system.Execute("ufw status 2>/dev/null")
	enabled := strings.Contains(out, "Status: active")

	rules, _ := ListRules()

	return &FirewallStatus{
		Enabled: enabled,
		Rules:   rules,
	}, nil
}

// EnableFirewall enables UFW
func EnableFirewall() error {
	if err := checkLinux(); err != nil {
		return err
	}

	// First allow SSH to prevent lockout
	system.Execute("ufw allow ssh")

	_, err := system.Execute("ufw --force enable")
	return err
}

// DisableFirewall disables UFW
func DisableFirewall() error {
	if err := checkLinux(); err != nil {
		return err
	}

	_, err := system.Execute("ufw --force disable")
	return err
}

// WhitelistIP allows an IP address for a specific port
func WhitelistIP(ip string, port int) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if ip == "" {
		return fmt.Errorf("IP address required")
	}

	var cmd string
	if port > 0 {
		cmd = fmt.Sprintf("ufw allow from %s to any port %d", ip, port)
	} else {
		cmd = fmt.Sprintf("ufw allow from %s", ip)
	}

	_, err := system.Execute(cmd)
	return err
}

// BlacklistIP blocks an IP address
func BlacklistIP(ip string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if ip == "" {
		return fmt.Errorf("IP address required")
	}

	cmd := fmt.Sprintf("ufw deny from %s", ip)
	_, err := system.Execute(cmd)
	return err
}

// AllowPort opens a port
func AllowPort(port int, protocol string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if protocol == "" {
		protocol = "tcp"
	}

	cmd := fmt.Sprintf("ufw allow %d/%s", port, protocol)
	_, err := system.Execute(cmd)
	return err
}

// DenyPort blocks a port
func DenyPort(port int, protocol string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if protocol == "" {
		protocol = "tcp"
	}

	cmd := fmt.Sprintf("ufw deny %d/%s", port, protocol)
	_, err := system.Execute(cmd)
	return err
}

// DeleteRule deletes a firewall rule by ID
func DeleteRule(id int) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("ufw --force delete %d", id)
	_, err := system.Execute(cmd)
	return err
}

// ListRules returns all firewall rules
func ListRules() ([]FirewallRule, error) {
	if runtime.GOOS == "windows" {
		return []FirewallRule{}, nil
	}

	out, err := system.Execute("ufw status numbered 2>/dev/null")
	if err != nil {
		return []FirewallRule{}, nil
	}

	var rules []FirewallRule
	lines := strings.Split(out, "\n")

	// Pattern: [ 1] 22/tcp                     ALLOW IN    Anywhere
	re := regexp.MustCompile(`\[\s*(\d+)\]\s+(\S+)\s+(ALLOW|DENY)\s+\w+\s+(.+)`)

	for _, line := range lines {
		matches := re.FindStringSubmatch(line)
		if len(matches) >= 5 {
			id, _ := strconv.Atoi(matches[1])
			rules = append(rules, FirewallRule{
				ID:     id,
				To:     strings.TrimSpace(matches[2]),
				Action: matches[3],
				From:   strings.TrimSpace(matches[4]),
			})
		}
	}

	return rules, nil
}

// GetSSHPort returns the current SSH port
func GetSSHPort() (int, error) {
	if runtime.GOOS == "windows" {
		return 22, nil
	}

	out, err := system.Execute("grep '^Port' /etc/ssh/sshd_config 2>/dev/null")
	if err != nil || strings.TrimSpace(out) == "" {
		return 22, nil // Default
	}

	parts := strings.Fields(out)
	if len(parts) >= 2 {
		port, err := strconv.Atoi(parts[1])
		if err == nil {
			return port, nil
		}
	}

	return 22, nil
}

// ChangeSSHPort changes the SSH port
func ChangeSSHPort(newPort int) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if newPort < 1 || newPort > 65535 {
		return fmt.Errorf("invalid port number: %d", newPort)
	}

	// Update sshd_config
	cmd := fmt.Sprintf(`sed -i 's/^#*Port .*/Port %d/' /etc/ssh/sshd_config`, newPort)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to update SSH config: %v", err)
	}

	// Update firewall rules
	oldPort, _ := GetSSHPort()
	if oldPort != newPort {
		system.Execute(fmt.Sprintf("ufw allow %d/tcp", newPort))
		system.Execute(fmt.Sprintf("ufw delete allow %d/tcp", oldPort))
	}

	// Restart SSH service
	system.Execute("systemctl restart sshd 2>/dev/null || systemctl restart ssh")

	return nil
}

// GetPublicIP returns the server's public IP
func GetPublicIP() (string, error) {
	out, err := system.Execute("curl -s https://ifconfig.me 2>/dev/null")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(out), nil
}

// SetupBasicFirewall sets up a basic firewall configuration
func SetupBasicFirewall() error {
	if err := checkLinux(); err != nil {
		return err
	}

	// Default policies
	system.Execute("ufw default deny incoming")
	system.Execute("ufw default allow outgoing")

	// Allow common services
	system.Execute("ufw allow ssh")
	system.Execute("ufw allow http")
	system.Execute("ufw allow https")

	// Enable
	return EnableFirewall()
}
