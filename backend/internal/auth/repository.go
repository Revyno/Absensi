package auth

import (
	"hris-backend/internal/models"

	"gorm.io/gorm"
)

type Repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

func (r *Repository) FindByEmail(email string) (*models.User, error) {
	var u models.User
	err := r.db.Preload("Employee").Where("email = ?", email).First(&u).Error
	return &u, err
}

func (r *Repository) FindByID(id string) (*models.User, error) {
	var u models.User
	err := r.db.Preload("Employee").First(&u, "id = ?", id).Error
	return &u, err
}
