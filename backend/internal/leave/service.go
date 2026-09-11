package leave

import (
	"errors"
	"time"

	"hris-backend/internal/common"
	"hris-backend/internal/models"
)

type Service struct{ repo *Repository }

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func (s *Service) ListTypes() ([]models.LeaveType, error) { return s.repo.ListTypes() }

func (s *Service) CreateType(req LeaveTypeRequest) (*models.LeaveType, error) {
	t := &models.LeaveType{Name: req.Name, Description: req.Description}
	if err := s.repo.CreateType(t); err != nil {
		return nil, err
	}
	return t, nil
}

func (s *Service) Create(employeeID string, req CreateRequest) (*models.LeaveRequest, error) {
	start, err1 := common.ParseDate(req.StartDate)
	end, err2 := common.ParseDate(req.EndDate)
	if err1 != nil || err2 != nil || start == nil || end == nil {
		return nil, errors.New("start_date and end_date must be YYYY-MM-DD")
	}
	if end.Before(*start) {
		return nil, errors.New("end_date must be on or after start_date")
	}
	lr := &models.LeaveRequest{
		EmployeeID:  employeeID,
		LeaveTypeID: req.LeaveTypeID,
		StartDate:   *start,
		EndDate:     *end,
		Reason:      req.Reason,
		Attachment:  req.Attachment,
		Status:      models.LeavePending,
	}
	if err := s.repo.Create(lr); err != nil {
		return nil, err
	}
	return s.repo.FindByID(lr.ID)
}

func (s *Service) Get(id string) (*models.LeaveRequest, error) { return s.repo.FindByID(id) }

func (s *Service) List(page, limit int, employeeID, status string) ([]models.LeaveRequest, int64, error) {
	return s.repo.List(page, limit, employeeID, status)
}

func (s *Service) ListTeam(managerEmployeeID string, page, limit int, status string) ([]models.LeaveRequest, int64, error) {
	return s.repo.ListByManager(managerEmployeeID, page, limit, status)
}

func (s *Service) Cancel(id, employeeID string) (*models.LeaveRequest, error) {
	lr, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("leave request not found")
	}
	if lr.EmployeeID != employeeID {
		return nil, errors.New("forbidden")
	}
	if lr.Status != models.LeavePending {
		return nil, errors.New("only pending request can be cancelled")
	}
	lr.Status = models.LeaveCancelled
	if err := s.repo.Save(lr); err != nil {
		return nil, err
	}
	return s.repo.FindByID(id)
}

func (s *Service) Approve(id, approverUserID string) (*models.LeaveRequest, error) {
	return s.decide(id, approverUserID, models.LeaveApproved)
}

func (s *Service) Reject(id, approverUserID string) (*models.LeaveRequest, error) {
	return s.decide(id, approverUserID, models.LeaveRejected)
}

func (s *Service) decide(id, approverUserID string, status models.LeaveStatus) (*models.LeaveRequest, error) {
	lr, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("leave request not found")
	}
	if lr.Status != models.LeavePending {
		return nil, errors.New("leave request already processed")
	}
	now := time.Now()
	lr.Status = status
	lr.ApprovedBy = &approverUserID
	lr.ApprovedAt = &now
	if err := s.repo.Save(lr); err != nil {
		return nil, err
	}
	return s.repo.FindByID(id)
}
