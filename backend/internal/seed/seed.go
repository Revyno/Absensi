package seed

import (
	"log"

	"hris-backend/internal/config"
	"hris-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func Run(db *gorm.DB, cfg *config.Config) error {
	var count int64
	db.Model(&models.User{}).Where("email = ?", cfg.SeedAdminEmail).Count(&count)
	if count > 0 {
		return nil
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(cfg.SeedAdminPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	return db.Transaction(func(tx *gorm.DB) error {
		user := &models.User{
			Email:    cfg.SeedAdminEmail,
			Password: string(hash),
			Role:     models.RoleSuperAdmin,
			IsActive: true,
		}
		if err := tx.Create(user).Error; err != nil {
			return err
		}
		emp := &models.Employee{
			UserID:           user.ID,
			EmployeeCode:     "ADMIN-001",
			FullName:         "Super Admin",
			EmploymentStatus: "active",
		}
		if err := tx.Create(emp).Error; err != nil {
			return err
		}
		log.Printf("seeded SUPER_ADMIN: %s / %s (ganti password setelah login)", cfg.SeedAdminEmail, cfg.SeedAdminPassword)
		return nil
	})
}
