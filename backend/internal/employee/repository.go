package employee

import (
	"time"

	"hris-backend/internal/models"

	"gorm.io/gorm"
)

type Repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

// CreateWithUser membuat User + Employee dalam satu transaksi.
func (r *Repository) CreateWithUser(user *models.User, emp *models.Employee) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(user).Error; err != nil {
			return err
		}
		emp.UserID = user.ID
		return tx.Create(emp).Error
	})
}

func (r *Repository) List(page, limit int, search, departmentID string) ([]models.Employee, int64, error) {
	var items []models.Employee
	var total int64
	q := r.db.Model(&models.Employee{}).
		Preload("User").Preload("Department").Preload("Position")
	if search != "" {
		like := "%" + search + "%"
		q = q.Where("full_name ILIKE ? OR employee_code ILIKE ?", like, like)
	}
	if departmentID != "" {
		q = q.Where("department_id = ?", departmentID)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := q.Offset((page - 1) * limit).Limit(limit).Order("created_at DESC").Find(&items).Error
	return items, total, err
}

func (r *Repository) FindByID(id string) (*models.Employee, error) {
	var emp models.Employee
	err := r.db.Preload("User").Preload("Department").Preload("Position").
		First(&emp, "id = ?", id).Error
	return &emp, err
}

func (r *Repository) FindByUserID(userID string) (*models.Employee, error) {
	var emp models.Employee
	err := r.db.Preload("Department").Preload("Position").
		First(&emp, "user_id = ?", userID).Error
	return &emp, err
}

func (r *Repository) Save(emp *models.Employee) error {
	return r.db.Save(emp).Error
}

// Deactivate menonaktifkan employee sekaligus akun user-nya.
func (r *Repository) Deactivate(id string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		var emp models.Employee
		if err := tx.First(&emp, "id = ?", id).Error; err != nil {
			return err
		}
		if err := tx.Model(&emp).Updates(map[string]any{
			"employment_status": "inactive",
			"updated_at":        time.Now(),
		}).Error; err != nil {
			return err
		}
		return tx.Model(&models.User{}).Where("id = ?", emp.UserID).
			Update("is_active", false).Error
	})
}
