package system

import (
	"os/exec"
	"runtime"
	"strings"
)

// Execute runs a shell command and returns the output
func Execute(command string) (string, error) {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("powershell", "-Command", command)
	} else {
		cmd = exec.Command("bash", "-c", command)
	}

	output, err := cmd.CombinedOutput()
	return string(output), err
}

// GetOSInfo returns basic OS information
func GetOSInfo() string {
	return runtime.GOOS + " " + runtime.GOARCH
}

// IsRoot checks if the application is running with root/admin privileges
func IsRoot() bool {
	if runtime.GOOS == "windows" {
		// Simple check for Windows admin - try to write to a protected area or use a specific command
		_, err := exec.Command("net", "session").Output()
		return err == nil
	}
	return strings.TrimSpace(ExecuteQuiet("id -u")) == "0"
}

func ExecuteQuiet(command string) string {
	out, _ := Execute(command)
	return out
}
