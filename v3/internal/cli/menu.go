package cli

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/system"
)

// Colors
const (
	Reset  = "\033[0m"
	Red    = "\033[31m"
	Green  = "\033[32m"
	Yellow = "\033[33m"
	Blue   = "\033[34m"
	Cyan   = "\033[36m"
	White  = "\033[37m"
	Bold   = "\033[1m"
)

func ShowMenu() {
	clearScreen()
	for {
		printHeader()
		printMainMenu()

		choice := readInput("\n👉 Chọn một tùy chọn: ")

		switch choice {
		case "1":
			websiteMenu()
		case "2":
			databaseMenu()
		case "3":
			backupMenu()
		case "4":
			securityMenu()
		case "5":
			servicesMenu()
		case "6":
			doctorCheck()
		case "7":
			showSystemStatus()
		case "0":
			fmt.Println("\n👋 Tạm biệt!")
			os.Exit(0)
		default:
			fmt.Println(Red + "❌ Lựa chọn không hợp lệ!" + Reset)
			pause()
		}
	}
}

func printHeader() {
	fmt.Println(Cyan + Bold + `
╔═══════════════════════════════════════════════════════════════╗
║                    🐼 PANDA SCRIPT v3.0                       ║
║              Server Management Made Simple                     ║
╚═══════════════════════════════════════════════════════════════╝` + Reset)
}

func printMainMenu() {
	fmt.Println(Yellow + "\n📋 MENU CHÍNH:" + Reset)
	fmt.Println("  1) 🌐 Quản lý Website")
	fmt.Println("  2) 🗄️  Quản lý Database")
	fmt.Println("  3) 💾 Sao lưu & Khôi phục")
	fmt.Println("  4) 🛡️  Bảo mật")
	fmt.Println("  5) ⚙️  Quản lý Services")
	fmt.Println("  6) 🩺 Panda Doctor")
	fmt.Println("  7) 📊 Trạng thái Hệ thống")
	fmt.Println("  0) 🚪 Thoát")
}

func websiteMenu() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n🌐 QUẢN LÝ WEBSITE:" + Reset)
	fmt.Println("  1) Liệt kê websites")
	fmt.Println("  2) Tạo website mới")
	fmt.Println("  3) Xóa website")
	fmt.Println("  4) Cài đặt WordPress")
	fmt.Println("  0) Quay lại")

	choice := readInput("\n👉 Chọn: ")
	switch choice {
	case "1":
		listWebsites()
	case "2":
		createWebsite()
	case "3":
		deleteWebsite()
	case "4":
		installWordPress()
	}
}

func listWebsites() {
	var websites []db.Website
	db.DB.Find(&websites)

	fmt.Println(Cyan + "\n📋 Danh sách Websites:" + Reset)
	if len(websites) == 0 {
		fmt.Println("   Không có website nào")
	} else {
		for _, w := range websites {
			ssl := "❌"
			if w.SSL {
				ssl = "✅"
			}
			fmt.Printf("   • %s (SSL: %s)\n", w.Domain, ssl)
		}
	}
	pause()
}

func createWebsite() {
	domain := readInput("Nhập tên miền: ")
	if runtime.GOOS != "linux" {
		fmt.Println(Red + "❌ Chức năng này chỉ hoạt động trên Linux" + Reset)
		pause()
		return
	}

	webRoot := "/var/www/" + domain
	system.Execute("mkdir -p " + webRoot)
	system.Execute("chown -R www-data:www-data " + webRoot)

	db.DB.Create(&db.Website{Domain: domain, Root: webRoot, PHPVersion: "8.3"})
	fmt.Println(Green + "✅ Website đã được tạo!" + Reset)
	pause()
}

func deleteWebsite() {
	domain := readInput("Nhập tên miền cần xóa: ")
	confirm := readInput(fmt.Sprintf("Xác nhận xóa %s? (y/n): ", domain))

	if strings.ToLower(confirm) == "y" {
		db.DB.Where("domain = ?", domain).Delete(&db.Website{})
		if runtime.GOOS == "linux" {
			system.Execute("rm -rf /var/www/" + domain)
		}
		fmt.Println(Green + "✅ Website đã được xóa!" + Reset)
	}
	pause()
}

func installWordPress() {
	domain := readInput("Nhập tên miền: ")
	dbName := readInput("Tên database: ")
	dbUser := readInput("User database: ")
	dbPass := readInput("Password database: ")

	if runtime.GOOS != "linux" {
		fmt.Println(Red + "❌ Chức năng này chỉ hoạt động trên Linux" + Reset)
		pause()
		return
	}

	webRoot := "/var/www/" + domain
	fmt.Println("⏳ Đang tải WordPress...")

	system.Execute("mkdir -p " + webRoot)
	system.Execute("cd " + webRoot + " && curl -sO https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz")
	system.Execute("chown -R www-data:www-data " + webRoot)

	wpConfig := fmt.Sprintf("<?php\ndefine('DB_NAME', '%s');\ndefine('DB_USER', '%s');\ndefine('DB_PASSWORD', '%s');\ndefine('DB_HOST', 'localhost');\n$table_prefix = 'wp_';\nif (!defined('ABSPATH')) { define('ABSPATH', __DIR__ . '/'); }\nrequire_once ABSPATH . 'wp-settings.php';", dbName, dbUser, dbPass)
	os.WriteFile(webRoot+"/wp-config.php", []byte(wpConfig), 0644)

	fmt.Println(Green + "✅ WordPress đã được cài đặt!" + Reset)
	pause()
}

func databaseMenu() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n🗄️ QUẢN LÝ DATABASE:" + Reset)
	fmt.Println("  1) Liệt kê databases")
	fmt.Println("  2) Tạo database + user")
	fmt.Println("  0) Quay lại")

	choice := readInput("\n👉 Chọn: ")
	switch choice {
	case "1":
		if runtime.GOOS == "linux" {
			out, _ := system.Execute("mysql -e 'SHOW DATABASES;'")
			fmt.Println(Cyan + "\n📋 Databases:" + Reset)
			fmt.Println(out)
		}
		pause()
	case "2":
		name := readInput("Tên database: ")
		user := readInput("User: ")
		pass := readInput("Password: ")
		if runtime.GOOS == "linux" {
			system.Execute(fmt.Sprintf("mysql -e \"CREATE DATABASE IF NOT EXISTS %s; GRANT ALL ON %s.* TO '%s'@'localhost' IDENTIFIED BY '%s';\"", name, name, user, pass))
			fmt.Println(Green + "✅ Database đã tạo!" + Reset)
		}
		pause()
	}
}

func backupMenu() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n💾 SAO LƯU:" + Reset)
	fmt.Println("  1) Sao lưu website")
	fmt.Println("  2) Sao lưu database")
	fmt.Println("  3) Liệt kê backups")
	fmt.Println("  0) Quay lại")

	choice := readInput("\n👉 Chọn: ")
	switch choice {
	case "1":
		domain := readInput("Tên miền: ")
		if runtime.GOOS == "linux" {
			filename := fmt.Sprintf("/opt/panda/backups/website_%s_%s.tar.gz", domain, time.Now().Format("20060102_150405"))
			system.Execute("mkdir -p /opt/panda/backups")
			system.Execute(fmt.Sprintf("tar -czf %s -C /var/www %s", filename, domain))
			fmt.Printf(Green+"✅ Backup: %s\n"+Reset, filename)
		}
		pause()
	case "2":
		name := readInput("Database: ")
		if runtime.GOOS == "linux" {
			filename := fmt.Sprintf("/opt/panda/backups/db_%s_%s.sql.gz", name, time.Now().Format("20060102_150405"))
			system.Execute("mkdir -p /opt/panda/backups")
			system.Execute(fmt.Sprintf("mysqldump %s | gzip > %s", name, filename))
			fmt.Printf(Green+"✅ Backup: %s\n"+Reset, filename)
		}
		pause()
	case "3":
		if runtime.GOOS == "linux" {
			out, _ := system.Execute("ls -lh /opt/panda/backups/ 2>/dev/null || echo 'Chưa có backup'")
			fmt.Println(out)
		}
		pause()
	}
}

func securityMenu() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n🛡️ BẢO MẬT:" + Reset)
	fmt.Println("  1) Trạng thái Firewall")
	fmt.Println("  2) Mở port")
	fmt.Println("  3) Đóng port")
	fmt.Println("  0) Quay lại")

	choice := readInput("\n👉 Chọn: ")
	if runtime.GOOS != "linux" {
		pause()
		return
	}

	switch choice {
	case "1":
		out, _ := system.Execute("ufw status")
		fmt.Println(out)
		pause()
	case "2":
		port := readInput("Port: ")
		system.Execute("ufw allow " + port)
		fmt.Println(Green + "✅ Đã mở port " + port + Reset)
		pause()
	case "3":
		port := readInput("Port: ")
		system.Execute("ufw deny " + port)
		fmt.Println(Green + "✅ Đã đóng port " + port + Reset)
		pause()
	}
}

func servicesMenu() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n⚙️ SERVICES:" + Reset)

	services := []string{"nginx", "mysql", "php8.3-fpm"}
	for i, svc := range services {
		status := "⚪"
		if runtime.GOOS == "linux" {
			out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", svc))
			if strings.TrimSpace(out) == "active" {
				status = "🟢"
			} else {
				status = "🔴"
			}
		}
		fmt.Printf("  %d) %s %s\n", i+1, status, svc)
	}
	fmt.Println("  0) Quay lại")

	choice := readInput("\n👉 Chọn: ")
	idx, err := strconv.Atoi(choice)
	if err != nil || idx < 1 || idx > len(services) {
		return
	}

	svc := services[idx-1]
	action := readInput(fmt.Sprintf("Action cho %s (start/stop/restart): ", svc))
	if runtime.GOOS == "linux" {
		system.Execute(fmt.Sprintf("systemctl %s %s", action, svc))
		fmt.Printf(Green+"✅ %s %s\n"+Reset, svc, action)
	}
	pause()
}

func doctorCheck() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n🩺 PANDA DOCTOR" + Reset)
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	score := 100
	if runtime.GOOS == "linux" {
		out, _ := system.Execute("df -h / | tail -1 | awk '{print $5}' | tr -d '%'")
		diskUsage, _ := strconv.Atoi(strings.TrimSpace(out))
		status := Green + "✅" + Reset
		if diskUsage > 90 {
			status = Red + "❌" + Reset
			score -= 30
		} else if diskUsage > 80 {
			status = Yellow + "⚠️" + Reset
			score -= 10
		}
		fmt.Printf("  %s Disk: %d%%\n", status, diskUsage)

		services := []string{"nginx", "mysql"}
		for _, svc := range services {
			out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", svc))
			svcStatus := Green + "✅" + Reset
			if strings.TrimSpace(out) != "active" {
				svcStatus = Red + "❌" + Reset
				score -= 15
			}
			fmt.Printf("  %s %s\n", svcStatus, svc)
		}
	}

	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Printf("  🏆 Score: %d/100\n", score)
	pause()
}

func showSystemStatus() {
	clearScreen()
	printHeader()
	fmt.Println(Yellow + "\n📊 HỆ THỐNG" + Reset)

	if runtime.GOOS == "linux" {
		uptime, _ := system.Execute("uptime -p")
		fmt.Printf("  ⏱️ %s", uptime)
		mem, _ := system.Execute("free -h | grep Mem | awk '{print $3\"/\"$2}'")
		fmt.Printf("  🧠 Memory: %s", mem)
		disk, _ := system.Execute("df -h / | tail -1 | awk '{print $3\"/\"$2}'")
		fmt.Printf("  💾 Disk: %s\n", disk)
	}
	pause()
}

func clearScreen() {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("cmd", "/c", "cls")
		cmd.Stdout = os.Stdout
		cmd.Run()
	} else {
		fmt.Print("\033[H\033[2J")
	}
}

func readInput(prompt string) string {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	return strings.TrimSpace(input)
}

func pause() {
	fmt.Print("\n⏎ Nhấn Enter để tiếp tục...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}
