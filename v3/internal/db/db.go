package db

import (
	"log"
	"time"

	"github.com/glebarez/sqlite"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

type User struct {
	ID               uint      `gorm:"primaryKey" json:"id"`
	Username         string    `gorm:"uniqueIndex;not null" json:"username"`
	Password         string    `json:"-"` // Don't expose password hash in JSON
	Role             string    `json:"role"`
	TwoFactorSecret  string    `json:"-"` // TOTP secret for 2FA
	TwoFactorEnabled bool      `json:"two_factor_enabled"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type Website struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	Domain     string    `gorm:"uniqueIndex;not null" json:"domain"`
	Port       int       `json:"port"`
	Root       string    `json:"root"`
	SSL        bool      `json:"ssl"`
	PHPVersion string    `json:"php_version"`
	DiskQuota  int64     `json:"disk_quota"` // Bytes, 0 = unlimited
	DiskUsed   int64     `json:"disk_used"`
	OwnerID    uint      `json:"owner_id"` // For multi-user
	Hot        bool      `json:"hot"`      // Highlighted website
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type Setting struct {
	ID    uint   `gorm:"primaryKey" json:"id"`
	Key   string `gorm:"uniqueIndex;not null" json:"key"`
	Value string `json:"value"`
}

// LoginToken for one-time login links
type LoginToken struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Token     string    `gorm:"uniqueIndex;not null" json:"token"`
	UserID    uint      `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
	Used      bool      `json:"used"`
	CreatedAt time.Time `json:"created_at"`
}

// IPWhitelist for admin panel access control
type IPWhitelist struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	IP          string    `gorm:"not null" json:"ip"`
	Description string    `json:"description"`
	Enabled     bool      `json:"enabled"`
	CreatedAt   time.Time `json:"created_at"`
}

// Notification for alert system
type Notification struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Type      string    `json:"type"` // info, warning, error, success
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	Read      bool      `json:"read"`
	CreatedAt time.Time `json:"created_at"`
}

// App for App Store
type App struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Name        string    `gorm:"uniqueIndex;not null" json:"name"`
	Slug        string    `gorm:"uniqueIndex;not null" json:"slug"`
	Description string    `json:"description"`
	Icon        string    `json:"icon"`
	DockerImage string    `json:"docker_image"`
	Port        int       `json:"port"`
	Installed   bool      `json:"installed"`
	ContainerID string    `json:"container_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

func Init() {
	var err error

	// Use absolute path for database
	dbPath := "/opt/panda/panda.db"

	DB, err = gorm.Open(sqlite.Open(dbPath), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent), // Reduce log noise
	})

	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Migrate the schema
	err = DB.AutoMigrate(&User{}, &Website{}, &Setting{}, &LoginToken{}, &IPWhitelist{}, &Notification{}, &App{})
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Create default admin user if not exists
	var count int64
	DB.Model(&User{}).Count(&count)
	if count == 0 {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("admin"), bcrypt.DefaultCost)
		admin := User{
			Username: "admin",
			Password: string(hashedPassword),
			Role:     "admin",
		}
		DB.Create(&admin)
		log.Println("Default admin user created (admin/admin)")
	}
}
