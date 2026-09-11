package attendance

import (
	"time"

	"hris-backend/internal/models"

	"gorm.io/gorm"
)

type Repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

func (r *Repository) FindByEmployeeDate(employeeID string, date time.Time) (*models.Attendance, error) {
	var a models.Attendance
	err := r.db.Where("employee_id = ? AND attendance_date = ?", employeeID, date).First(&a).Error
	return &a, err
}

func (r *Repository) Create(a *models.Attendance) error { return r.db.Create(a).Error }

func (r *Repository) Save(a *models.Attendance) error { return r.db.Save(a).Error }

func (r *Repository) List(page, limit int, employeeID, date string) ([]models.Attendance, int64, error) {
	var items []models.Attendance
	var total int64
	q := r.db.Model(&models.Attendance{}).Preload("Employee")
	if employeeID != "" {
		q = q.Where("employee_id = ?", employeeID)
	}
	if date != "" {
		q = q.Where("attendance_date = ?", date)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := q.Offset((page - 1) * limit).Limit(limit).Order("attendance_date DESC").Find(&items).Error
	return items, total, err
}
