package leave

import (
	"hris-backend/internal/models"

	"gorm.io/gorm"
)

type Repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

// --- Leave Types ---

func (r *Repository) ListTypes() ([]models.LeaveType, error) {
	var items []models.LeaveType
	err := r.db.Order("name").Find(&items).Error
	return items, err
}

func (r *Repository) CreateType(t *models.LeaveType) error { return r.db.Create(t).Error }

// --- Leave Requests ---

func (r *Repository) Create(lr *models.LeaveRequest) error { return r.db.Create(lr).Error }

func (r *Repository) Save(lr *models.LeaveRequest) error { return r.db.Save(lr).Error }

func (r *Repository) FindByID(id string) (*models.LeaveRequest, error) {
	var lr models.LeaveRequest
	err := r.db.Preload("Employee").Preload("LeaveType").First(&lr, "id = ?", id).Error
	return &lr, err
}

func (r *Repository) List(page, limit int, employeeID, status string) ([]models.LeaveRequest, int64, error) {
	q := r.db.Model(&models.LeaveRequest{}).Preload("Employee").Preload("LeaveType")
	if employeeID != "" {
		q = q.Where("employee_id = ?", employeeID)
	}
	if status != "" {
		q = q.Where("status = ?", status)
	}
	return paginate(q, page, limit)
}

// ListByManager: request milik anggota tim (employees.manager_id = managerEmployeeID).
func (r *Repository) ListByManager(managerEmployeeID string, page, limit int, status string) ([]models.LeaveRequest, int64, error) {
	sub := r.db.Model(&models.Employee{}).Select("id").Where("manager_id = ?", managerEmployeeID)
	q := r.db.Model(&models.LeaveRequest{}).Preload("Employee").Preload("LeaveType").
		Where("employee_id IN (?)", sub)
	if status != "" {
		q = q.Where("status = ?", status)
	}
	return paginate(q, page, limit)
}

func paginate(q *gorm.DB, page, limit int) ([]models.LeaveRequest, int64, error) {
	var items []models.LeaveRequest
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := q.Offset((page - 1) * limit).Limit(limit).Order("created_at DESC").Find(&items).Error
	return items, total, err
}
