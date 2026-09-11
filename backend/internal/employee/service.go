package employee

import (
	"errors"

	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
)

type Service struct{ repo *Repository }

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func (s *Service) Create(req CreateRequest) (*models.Employee, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	role := models.Role(req.Role)
	if role == "" {
		role = models.RoleEmployee
	}
	joinDate, err := common.ParseDate(req.JoinDate)
	if err != nil {
		return nil, errors.New("join_date must be YYYY-MM-DD")
	}

	user := &models.User{Email: req.Email, Password: string(hash), Role: role, IsActive: true}
	emp := &models.Employee{
		EmployeeCode:     req.EmployeeCode,
		FullName:         req.FullName,
		Phone:            req.Phone,
		DepartmentID:     req.DepartmentID,
		PositionID:       req.PositionID,
		ManagerID:        req.ManagerID,
		JoinDate:         joinDate,
		EmploymentStatus: "active",
		BasicSalary:      req.BasicSalary,
	}
	if err := s.repo.CreateWithUser(user, emp); err != nil {
		return nil, err
	}
	return s.repo.FindByID(emp.ID)
}

func (s *Service) List(page, limit int, search, departmentID string) ([]models.Employee, int64, error) {
	return s.repo.List(page, limit, search, departmentID)
}

func (s *Service) Get(id string) (*models.Employee, error) { return s.repo.FindByID(id) }

func (s *Service) GetByUserID(userID string) (*models.Employee, error) {
	return s.repo.FindByUserID(userID)
}

func (s *Service) Update(id string, req UpdateRequest) (*models.Employee, error) {
	emp, err := s.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if req.FullName != nil {
		emp.FullName = *req.FullName
	}
	if req.Phone != nil {
		emp.Phone = *req.Phone
	}
	if req.DepartmentID != nil {
		emp.DepartmentID = req.DepartmentID
	}
	if req.PositionID != nil {
		emp.PositionID = req.PositionID
	}
	if req.ManagerID != nil {
		emp.ManagerID = req.ManagerID
	}
	if req.EmploymentStatus != nil {
		emp.EmploymentStatus = *req.EmploymentStatus
	}
	if req.BasicSalary != nil {
		emp.BasicSalary = *req.BasicSalary
	}
	if req.JoinDate != nil {
		d, err := common.ParseDate(*req.JoinDate)
		if err != nil {
			return nil, errors.New("join_date must be YYYY-MM-DD")
		}
		emp.JoinDate = d
	}
	if err := s.repo.Save(emp); err != nil {
		return nil, err
	}
	return s.repo.FindByID(id)
}

func (s *Service) Deactivate(id string) error { return s.repo.Deactivate(id) }
