package database

import (
	"log"

	"hris-backend/internal/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Connect(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, err
	}
	log.Println("database connected")
	return db, nil
}

func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(models.AllModels()...)
}
