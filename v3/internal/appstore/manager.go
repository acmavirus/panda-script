package appstore

import (
	"fmt"
	"os"

	"github.com/acmavirus/panda-script/v3/internal/system"
	"gopkg.in/yaml.v3"
)

type App struct {
	Name        string `json:"name" yaml:"name"`
	Description string `json:"description" yaml:"description"`
	Image       string `json:"image" yaml:"image"`
	DefaultPort int    `json:"default_port" yaml:"default_port"`
	Category    string `json:"category" yaml:"category"`
	InstallCmd  string `json:"install_cmd" yaml:"install_cmd"`
}

type AppConfig struct {
	Apps []App `yaml:"apps"`
}

var AvailableApps []App

func init() {
	LoadApps()
}

func LoadApps() error {
	data, err := os.ReadFile("internal/appstore/apps.yaml")
	if err != nil {
		// Fallback or error logging
		fmt.Println("Failed to load apps.yaml:", err)
		return err
	}

	var config AppConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		fmt.Println("Failed to parse apps.yaml:", err)
		return err
	}

	AvailableApps = config.Apps
	return nil
}

func GetApps() []App {
	return AvailableApps
}

func InstallApp(appName string) error {
	var targetApp *App
	for _, app := range AvailableApps {
		if app.Name == appName {
			targetApp = &app
			break
		}
	}

	if targetApp == nil {
		return fmt.Errorf("app not found")
	}

	_, err := system.Execute(targetApp.InstallCmd)
	return err
}
