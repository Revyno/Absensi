package payroll

import (
	"errors"

	"hris-backend/internal/models"

	"gorm.io/gorm"
)

type Repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) *Repository { return &Repository{db: db} }

func (r *Repository) CreatePeriod(p *models.PayrollPeriod) error { return r.db.Create(p).Error }

func (r *Repository) ListPeriods() ([]models.PayrollPeriod, error) {
	var items []models.PayrollPeriod
	err := r.db.Order("start_date DESC").Find(&items).Error
	return items, err
}

func (r *Repository) FindPeriod(id string) (*models.PayrollPeriod, error) {
	var p models.PayrollPeriod
	err := r.db.First(&p, "id = ?", id).Error
	return &p, err
}

func (r *Repository) FindEmployee(id string) (*models.Employee, error) {
	var e models.Employee
	err := r.db.First(&e, "id = ?", id).Error
	return &e, err
}

func (r *Repository) UpsertPayroll(p *models.Payroll) error {
	var existing models.Payroll
	err := r.db.Where("employee_id = ? AND payroll_period_id = ?", p.EmployeeID, p.PayrollPeriodID).First(&existing).Error
	if err == nil {
		if existing.Status == "published" {
			return errors.New("payroll already published for this period")
		}
		p.ID = existing.ID
		p.CreatedAt = existing.CreatedAt
		return r.db.Save(p).Error
	}
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return r.db.Create(p).Error
	}
	return err
}

func (r *Repository) FindPayroll(id string) (*models.Payroll, error) {
	var p models.Payroll
	err := r.db.Preload("Employee").Preload("PayrollPeriod").First(&p, "id = ?", id).Error
	return &p, err
}

func (r *Repository) FindByEmpPeriod(employeeID, periodID string) (*models.Payroll, error) {
	var p models.Payroll
	err := r.db.Preload("Employee").Preload("PayrollPeriod").
		Where("employee_id = ? AND payroll_period_id = ?", employeeID, periodID).First(&p).Error
	return &p, err
}

func (r *Repository) SavePayroll(p *models.Payroll) error { return r.db.Save(p).Error }

func (r *Repository) ListPayrolls(page, limit int, employeeID, periodID, status string) ([]models.Payroll, int64, error) {
	var items []models.Payroll
	var total int64
	q := r.db.Model(&models.Payroll{}).Preload("Employee").Preload("PayrollPeriod")
	if employeeID != "" {
		q = q.Where("employee_id = ?", employeeID)
	}
	if periodID != "" {
		q = q.Where("payroll_period_id = ?", periodID)
	}
	if status != "" {
		q = q.Where("status = ?", status)
	}
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := q.Offset((page - 1) * limit).Limit(limit).Order("created_at DESC").Find(&items).Error
	return items, total, err
}
