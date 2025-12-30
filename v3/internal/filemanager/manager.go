package filemanager

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type FileInfo struct {
	Name    string    `json:"name"`
	Size    int64     `json:"size"`
	Mode    string    `json:"mode"`
	ModTime time.Time `json:"mod_time"`
	IsDir   bool      `json:"is_dir"`
	Path    string    `json:"path"`
}

func ListDirectory(path string) ([]FileInfo, error) {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var files []FileInfo
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			continue
		}
		files = append(files, FileInfo{
			Name:    entry.Name(),
			Size:    info.Size(),
			Mode:    info.Mode().String(),
			ModTime: info.ModTime(),
			IsDir:   entry.IsDir(),
			Path:    filepath.Join(path, entry.Name()),
		})
	}
	return files, nil
}

func ReadFile(path string) (string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

func WriteFile(path string, content string) error {
	return os.WriteFile(path, []byte(content), 0644)
}

func DeleteFile(path string) error {
	return os.RemoveAll(path)
}

func RenameFile(oldPath, newPath string) error {
	return os.Rename(oldPath, newPath)
}

func CreateDirectory(path string) error {
	return os.MkdirAll(path, 0755)
}

func Compress(srcPath, destPath, format string) error {
	var cmd *exec.Cmd
	switch format {
	case "zip":
		cmd = exec.Command("zip", "-r", destPath, ".")
		cmd.Dir = srcPath
	case "tar.gz":
		cmd = exec.Command("tar", "-czf", destPath, "-C", srcPath, ".")
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
	return cmd.Run()
}

func Extract(archivePath, destPath string) error {
	var cmd *exec.Cmd
	if strings.HasSuffix(archivePath, ".zip") {
		cmd = exec.Command("unzip", "-o", archivePath, "-d", destPath)
	} else if strings.HasSuffix(archivePath, ".tar.gz") || strings.HasSuffix(archivePath, ".tgz") {
		cmd = exec.Command("tar", "-xzf", archivePath, "-C", destPath)
	} else if strings.HasSuffix(archivePath, ".tar.bz2") {
		cmd = exec.Command("tar", "-xjf", archivePath, "-C", destPath)
	} else {
		return fmt.Errorf("unsupported archive format")
	}
	return cmd.Run()
}

func DownloadRemoteFile(url, destPath string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to download file: %s", resp.Status)
	}

	out, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

func Chmod(path string, mode int) error {
	return os.Chmod(path, os.FileMode(mode))
}

func Copy(src, dst string) error {
	cmd := exec.Command("cp", "-r", src, dst)
	return cmd.Run()
}

func Move(src, dst string) error {
	cmd := exec.Command("mv", src, dst)
	return cmd.Run()
}

func ListArchive(archivePath string) ([]string, error) {
	var cmd *exec.Cmd
	if strings.HasSuffix(archivePath, ".zip") {
		cmd = exec.Command("unzip", "-l", archivePath)
	} else if strings.HasSuffix(archivePath, ".tar.gz") || strings.HasSuffix(archivePath, ".tgz") {
		cmd = exec.Command("tar", "-tf", archivePath)
	} else {
		return nil, fmt.Errorf("unsupported archive format")
	}

	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(out), "\n")
	var results []string
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			results = append(results, line)
		}
	}
	return results, nil
}
