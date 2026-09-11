package payroll

import (
	"errors"

	"hris-backend/internal/common"
	"hris-backend/internal/models"
)

type Service struct{ repo *Repository }

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func (s *Service) CreatePeriod(req PeriodRequest) (*models.PayrollPeriod, error) {
	start, err1 := common.ParseDate(req.StartDate)
	end, err2 := common.ParseDate(req.EndDate)
	if err1 != nil || err2 != nil || start == nil || end == nil {
		return nil, errors.New("start_date and end_date must be YYYY-MM-DD")
	}
	p := &models.PayrollPeriod{Name: req.Name, StartDate: *start, EndDate: *end, Status: "draft"}
	if err := s.repo.CreatePeriod(p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Service) ListPeriods() ([]models.PayrollPeriod, error) { return s.repo.ListPeriods() }

func computeSalary(basic, allowance, overtime, bonus, deduction float64) (gross, net float64) {
	gross = basic + allowance + overtime + bonus
	net = gross - deduction
	return
}

func (s *Service) Generate(req GenerateRequest) (*models.Payroll, error) {
	emp, err := s.repo.FindEmployee(req.EmployeeID)
	if err != nil {
		return nil, errors.New("employee not found")
	}
	if _, err := s.repo.FindPeriod(req.PayrollPeriodID); err != nil {
		return nil, errors.New("payroll period not found")
	}
	gross, net := computeSalary(emp.BasicSalary, req.TotalAllowance, req.TotalOvertime, req.TotalBonus, req.TotalDeduction)
	p := &models.Payroll{
		EmployeeID:      req.EmployeeID,
		PayrollPeriodID: req.PayrollPeriodID,
		BasicSalary:     emp.BasicSalary,
		TotalAllowance:  req.TotalAllowance,
		TotalOvertime:   req.TotalOvertime,
		TotalBonus:      req.TotalBonus,
		TotalDeduction:  req.TotalDeduction,
		GrossSalary:     gross,
		NetSalary:       net,
		Status:          "draft",
	}
	if err := s.repo.UpsertPayroll(p); err != nil {
		return nil, err
	}
	return s.repo.FindByEmpPeriod(req.EmployeeID, req.PayrollPeriodID)
}

func (s *Service) Get(id string) (*models.Payroll, error) { return s.repo.FindPayroll(id) }

func (s *Service) List(page, limit int, employeeID, periodID, status string) ([]models.Payroll, int64, error) {
	return s.repo.ListPayrolls(page, limit, employeeID, periodID, status)
}

func (s *Service) Publish(id string) (*models.Payroll, error) {
	p, err := s.repo.FindPayroll(id)
	if err != nil {
		return nil, errors.New("payroll not found")
	}
	p.Status = "published"
	if err := s.repo.SavePayroll(p); err != nil {
		return nil, err
	}
	return s.repo.FindPayroll(id)
}
