package cli

import (
	"fmt"
	"os"
	"runtime"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/auth"
	"github.com/acmavirus/panda-script/v3/internal/db"
	"github.com/acmavirus/panda-script/v3/internal/system"
	"github.com/spf13/cobra"
	"golang.org/x/crypto/bcrypt"
)

func RegisterWebsiteCommands(rootCmd *cobra.Command) {
	websiteCmd := &cobra.Command{
		Use:   "website",
		Short: "Website management",
	}

	websiteCmd.AddCommand(&cobra.Command{
		Use:   "list",
		Short: "List websites",
		Run: func(cmd *cobra.Command, args []string) {
			var websites []db.Website
			db.DB.Find(&websites)
			fmt.Println("🌐 Websites:")
			for _, w := range websites {
				fmt.Printf("  • %s\n", w.Domain)
			}
		},
	})

	websiteCmd.AddCommand(&cobra.Command{
		Use:   "create [domain]",
		Short: "Create website",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			domain := args[0]
			if runtime.GOOS == "linux" {
				system.Execute("mkdir -p /home/" + domain)
				system.Execute("chown -R www-data:www-data /home/" + domain)
			}
			db.DB.Create(&db.Website{Domain: domain, Root: "/home/" + domain})
			fmt.Printf("✅ Created %s\n", domain)
		},
	})

	rootCmd.AddCommand(websiteCmd)
}

func RegisterDatabaseCommands(rootCmd *cobra.Command) {
	dbCmd := &cobra.Command{
		Use:   "db",
		Short: "Database management",
	}

	dbCmd.AddCommand(&cobra.Command{
		Use:   "list",
		Short: "List databases",
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				out, _ := system.Execute("mysql -e 'SHOW DATABASES;'")
				fmt.Println(out)
			}
		},
	})

	dbCmd.AddCommand(&cobra.Command{
		Use:   "create [name] [user] [password]",
		Short: "Create database",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				system.Execute(fmt.Sprintf("mysql -e \"CREATE DATABASE IF NOT EXISTS %s; GRANT ALL ON %s.* TO '%s'@'localhost' IDENTIFIED BY '%s';\"", args[0], args[0], args[1], args[2]))
				fmt.Printf("✅ Created database %s\n", args[0])
			}
		},
	})

	rootCmd.AddCommand(dbCmd)
}

func RegisterBackupCommands(rootCmd *cobra.Command) {
	backupCmd := &cobra.Command{
		Use:   "backup",
		Short: "Backup management",
	}

	backupCmd.AddCommand(&cobra.Command{
		Use:   "website [domain]",
		Short: "Backup website",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				filename := fmt.Sprintf("/opt/panda/backups/website_%s_%s.tar.gz", args[0], time.Now().Format("20060102_150405"))
				system.Execute("mkdir -p /opt/panda/backups")
				system.Execute(fmt.Sprintf("tar -czf %s -C /home %s", filename, args[0]))
				fmt.Printf("✅ Backup: %s\n", filename)
			}
		},
	})

	backupCmd.AddCommand(&cobra.Command{
		Use:   "list",
		Short: "List backups",
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				out, _ := system.Execute("ls -lh /opt/panda/backups/ 2>/dev/null")
				fmt.Println(out)
			}
		},
	})

	rootCmd.AddCommand(backupCmd)
}

func RegisterSecurityCommands(rootCmd *cobra.Command) {
	securityCmd := &cobra.Command{
		Use:     "security",
		Aliases: []string{"fw"},
		Short:   "Security management",
	}

	securityCmd.AddCommand(&cobra.Command{
		Use:   "status",
		Short: "Firewall status",
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				out, _ := system.Execute("ufw status")
				fmt.Println(out)
			}
		},
	})

	securityCmd.AddCommand(&cobra.Command{
		Use:   "allow [port]",
		Short: "Allow port",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if runtime.GOOS == "linux" {
				system.Execute("ufw allow " + args[0])
				fmt.Printf("✅ Allowed port %s\n", args[0])
			}
		},
	})

	rootCmd.AddCommand(securityCmd)
}

func RegisterDoctorCommands(rootCmd *cobra.Command) {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "doctor",
		Short: "Health check",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🩺 Panda Doctor")
			score := 100
			if runtime.GOOS == "linux" {
				services := []string{"nginx", "mysql"}
				for _, svc := range services {
					out, _ := system.Execute(fmt.Sprintf("systemctl is-active %s 2>/dev/null", svc))
					if strings.TrimSpace(out) != "active" {
						fmt.Printf("  ❌ %s down\n", svc)
						score -= 20
					} else {
						fmt.Printf("  ✅ %s running\n", svc)
					}
				}
			}
			fmt.Printf("🏆 Score: %d/100\n", score)
		},
	})
}

func RegisterPanelCommands(rootCmd *cobra.Command) {
	panelCmd := &cobra.Command{
		Use:   "panel",
		Short: "Panel management",
	}

	panelCmd.AddCommand(&cobra.Command{
		Use:   "get-login",
		Short: "Generate login link",
		Run: func(cmd *cobra.Command, args []string) {
			token, expiresAt, _ := auth.GenerateLoginToken()
			var user db.User
			db.DB.Where("username = ?", "admin").First(&user)
			db.DB.Create(&db.LoginToken{Token: token, UserID: user.ID, ExpiresAt: expiresAt})

			ip := "your-ip"
			if runtime.GOOS == "linux" {
				out, _ := system.Execute("hostname -I | awk '{print $1}'")
				ip = strings.TrimSpace(out)
			}
			fmt.Printf("🔗 Login: http://%s/panda/login?token=%s\n", ip, token)
		},
	})

	panelCmd.AddCommand(&cobra.Command{
		Use:   "password [new-password]",
		Short: "Change admin password",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var user db.User
			db.DB.Where("username = ?", "admin").First(&user)
			hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(args[0]), bcrypt.DefaultCost)
			user.Password = string(hashedPassword)
			db.DB.Save(&user)
			fmt.Println("✅ Password changed")
		},
	})

	panelCmd.AddCommand(&cobra.Command{
		Use:   "status",
		Short: "Panel status",
		Run: func(cmd *cobra.Command, args []string) {
			port := os.Getenv("PANDA_PORT")
			if port == "" {
				port = "8888"
			}
			fmt.Printf("🐼 Panel: http://localhost:%s/panda\n", port)
			if runtime.GOOS == "linux" {
				out, _ := system.Execute("systemctl is-active panda 2>/dev/null")
				if strings.TrimSpace(out) == "active" {
					fmt.Println("   Status: 🟢 Running")
				} else {
					fmt.Println("   Status: 🔴 Stopped")
				}
			}
		},
	})

	rootCmd.AddCommand(panelCmd)
}
