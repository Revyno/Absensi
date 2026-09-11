package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Role enum untuk RBAC.
type Role string

const (
	RoleSuperAdmin Role = "SUPER_ADMIN"
	RoleHR         Role = "HR"
	RoleManager    Role = "MANAGER"
	RoleEmployee   Role = "EMPLOYEE"
)

// Base menyediakan UUID primary key + timestamps untuk semua tabel.
type Base struct {
	ID        string    `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (b *Base) BeforeCreate(tx *gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.NewString()
	}
	return nil
}

type User struct {
	Base
	Email    string    `gorm:"uniqueIndex;not null" json:"email"`
	Password string    `gorm:"not null" json:"-"`
	Role     Role      `gorm:"type:varchar(20);not null;default:'EMPLOYEE'" json:"role"`
	IsActive bool      `gorm:"default:true" json:"is_active"`
	Employee *Employee `json:"employee,omitempty"`
}

type Employee struct {
	Base
	UserID           string      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	EmployeeCode     string      `gorm:"uniqueIndex;not null" json:"employee_code"`
	FullName         string      `gorm:"not null" json:"full_name"`
	Phone            string      `json:"phone"`
	DepartmentID     *string     `gorm:"type:uuid" json:"department_id"`
	PositionID       *string     `gorm:"type:uuid" json:"position_id"`
	ManagerID        *string     `gorm:"type:uuid" json:"manager_id"`
	JoinDate         *time.Time  `gorm:"type:date" json:"join_date"`
	EmploymentStatus string      `gorm:"default:'active'" json:"employment_status"`
	BasicSalary      float64     `gorm:"default:0" json:"basic_salary"`
	User             *User       `json:"user,omitempty"`
	Department       *Department `json:"department,omitempty"`
	Position         *Position   `json:"position,omitempty"`
}

type Department struct {
	Base
	Name string `gorm:"not null" json:"name"`
}

type Position struct {
	Base
	DepartmentID *string     `gorm:"type:uuid" json:"department_id"`
	Name         string      `gorm:"not null" json:"name"`
	Department   *Department `json:"department,omitempty"`
}

type Attendance struct {
	Base
	EmployeeID     string     `gorm:"type:uuid;not null;uniqueIndex:idx_emp_date" json:"employee_id"`
	AttendanceDate time.Time  `gorm:"type:date;not null;uniqueIndex:idx_emp_date" json:"attendance_date"`
	CheckIn        *time.Time `json:"check_in"`
	CheckOut       *time.Time `json:"check_out"`
	WorkingMinutes int        `gorm:"default:0" json:"working_minutes"`
	Status         string     `json:"status"`
	Employee       *Employee  `json:"employee,omitempty"`
}

type LeaveType struct {
	Base
	Name        string `gorm:"not null" json:"name"`
	Description string `json:"description"`
}

type LeaveStatus string

const (
	LeavePending   LeaveStatus = "PENDING"
	LeaveApproved  LeaveStatus = "APPROVED"
	LeaveRejected  LeaveStatus = "REJECTED"
	LeaveCancelled LeaveStatus = "CANCELLED"
)

type LeaveRequest struct {
	Base
	EmployeeID  string      `gorm:"type:uuid;not null;index" json:"employee_id"`
	LeaveTypeID string      `gorm:"type:uuid;not null" json:"leave_type_id"`
	StartDate   time.Time   `gorm:"type:date;not null" json:"start_date"`
	EndDate     time.Time   `gorm:"type:date;not null" json:"end_date"`
	Reason      string      `json:"reason"`
	Attachment  string      `json:"attachment"`
	Status      LeaveStatus `gorm:"type:varchar(20);default:'PENDING'" json:"status"`
	ApprovedBy  *string     `gorm:"type:uuid" json:"approved_by"`
	ApprovedAt  *time.Time  `json:"approved_at"`
	Employee    *Employee   `json:"employee,omitempty"`
	LeaveType   *LeaveType  `json:"leave_type,omitempty"`
}

type PayrollPeriod struct {
	Base
	Name      string    `gorm:"not null" json:"name"`
	StartDate time.Time `gorm:"type:date" json:"start_date"`
	EndDate   time.Time `gorm:"type:date" json:"end_date"`
	Status    string    `gorm:"default:'draft'" json:"status"`
}

type Payroll struct {
	Base
	EmployeeID      string         `gorm:"type:uuid;not null;uniqueIndex:idx_emp_period" json:"employee_id"`
	PayrollPeriodID string         `gorm:"type:uuid;not null;uniqueIndex:idx_emp_period" json:"payroll_period_id"`
	BasicSalary     float64        `json:"basic_salary"`
	TotalAllowance  float64        `json:"total_allowance"`
	TotalOvertime   float64        `json:"total_overtime"`
	TotalBonus      float64        `json:"total_bonus"`
	TotalDeduction  float64        `json:"total_deduction"`
	GrossSalary     float64        `json:"gross_salary"`
	NetSalary       float64        `json:"net_salary"`
	Status          string         `gorm:"default:'draft'" json:"status"`
	Employee        *Employee      `json:"employee,omitempty"`
	PayrollPeriod   *PayrollPeriod `json:"payroll_period,omitempty"`
}

type BPJS struct {
	Base
	EmployeeID           string    `gorm:"type:uuid;not null;index" json:"employee_id"`
	BPJSNumber           string    `json:"bpjs_number"`
	BPJSType             string    `json:"bpjs_type"`
	EmployeeContribution float64   `json:"employee_contribution"`
	CompanyContribution  float64   `json:"company_contribution"`
	Status               string    `gorm:"default:'active'" json:"status"`
	Employee             *Employee `json:"employee,omitempty"`
}

// AllModels dipakai database.Migrate untuk auto-migrate.
func AllModels() []any {
	return []any{
		&User{}, &Employee{}, &Department{}, &Position{},
		&Attendance{}, &LeaveType{}, &LeaveRequest{},
		&PayrollPeriod{}, &Payroll{}, &BPJS{},
	}
}
