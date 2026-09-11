package attendance

import (
	"errors"
	"time"

	"hris-backend/internal/models"

	"gorm.io/gorm"
)

var (
	ErrAlreadyCheckedIn  = errors.New("already checked in today")
	ErrNotCheckedIn      = errors.New("no check-in found for today")
	ErrAlreadyCheckedOut = errors.New("already checked out today")
)

// lateThreshold: jam kerja mulai. ponytail: hardcoded 09:00 — pindahkan ke config/company policy saat multi-shift dibutuhkan.
var lateThreshold = 9

type Service struct{ repo *Repository }

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

func todayDate() time.Time {
	n := time.Now()
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, n.Location())
}

func (s *Service) CheckIn(employeeID string) (*models.Attendance, error) {
	date := todayDate()
	if existing, err := s.repo.FindByEmployeeDate(employeeID, date); err == nil && existing.CheckIn != nil {
		return nil, ErrAlreadyCheckedIn
	} else if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	now := time.Now()
	status := "present"
	if now.Hour() > lateThreshold || (now.Hour() == lateThreshold && now.Minute() > 0) {
		status = "late"
	}
	att := &models.Attendance{EmployeeID: employeeID, AttendanceDate: date, CheckIn: &now, Status: status}
	if err := s.repo.Create(att); err != nil {
		return nil, err
	}
	return att, nil
}

func (s *Service) CheckOut(employeeID string) (*models.Attendance, error) {
	att, err := s.repo.FindByEmployeeDate(employeeID, todayDate())
	if err != nil || att.CheckIn == nil {
		return nil, ErrNotCheckedIn
	}
	if att.CheckOut != nil {
		return nil, ErrAlreadyCheckedOut
	}
	now := time.Now()
	att.CheckOut = &now
	att.WorkingMinutes = int(now.Sub(*att.CheckIn).Minutes())
	if err := s.repo.Save(att); err != nil {
		return nil, err
	}
	return att, nil
}

func (s *Service) List(page, limit int, employeeID, date string) ([]models.Attendance, int64, error) {
	return s.repo.List(page, limit, employeeID, date)
}
