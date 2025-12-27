package docker

import (
	"encoding/json"
	"strings"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type Container struct {
	ID      string `json:"id"`
	Image   string `json:"image"`
	Status  string `json:"status"`
	Names   string `json:"names"`
	State   string `json:"state"`
}

func ListContainers() ([]Container, error) {
	out, err := system.Execute("docker ps -a --format '{{json .}}'")
	if err != nil {
		return nil, err
	}

	var containers []Container
	lines := strings.Split(strings.TrimSpace(out), "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}
		var c Container
		// Docker returns invalid JSON objects per line (keys are capitalized)
		// We might need a more robust parser or specific format
		// Simplified for now:
		if err := json.Unmarshal([]byte(line), &c); err != nil {
			continue
		}
		containers = append(containers, c)
	}
	return containers, nil
}

func StartContainer(id string) (string, error) {
	return system.Execute("docker start " + id)
}

func StopContainer(id string) (string, error) {
	return system.Execute("docker stop " + id)
}

func RestartContainer(id string) (string, error) {
	return system.Execute("docker restart " + id)
}
