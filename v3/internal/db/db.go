package db

import (
	"log"
	"time"

	"golang.org/x/crypto/bcrypt"
	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"uniqueIndex;not null" json:"username"`
	Password  string    `json:"-"` // Don't expose password hash in JSON
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Website struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Domain    string    `gorm:"uniqueIndex;not null" json:"domain"`
	Port      int       `json:"port"`
	Root      string    `json:"root"`
	SSL       bool      `json:"ssl"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Setting struct {
	ID    uint   `gorm:"primaryKey" json:"id"`
	Key   string `gorm:"uniqueIndex;not null" json:"key"`
	Value string `json:"value"`
}

func Init() {
	var err error
	DB, err = gorm.Open(sqlite.Open("panda.db"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Migrate the schema
	err = DB.AutoMigrate(&User{}, &Website{}, &Setting{})
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
