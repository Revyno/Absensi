package seed

import (
	"log"
	"time"

	"hris-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Demo mengisi data contoh untuk semua modul/route agar mudah dites.
// Idempotent: kalau sudah ada departemen, dilewati.
func Demo(db *gorm.DB) error {
	var deptCount int64
	db.Model(&models.Department{}).Count(&deptCount)
	if deptCount > 0 {
		log.Println("demo data already seeded, skipping")
		return nil
	}

	pass, err := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	hash := string(pass)

	return db.Transaction(func(tx *gorm.DB) error {
		// --- Departments ---
		itDept := models.Department{Name: "IT"}
		finDept := models.Department{Name: "Finance"}
		hrDept := models.Department{Name: "Human Resources"}
		for _, d := range []*models.Department{&itDept, &finDept, &hrDept} {
			if err := tx.Create(d).Error; err != nil {
				return err
			}
		}

		// --- Positions ---
		posBackend := models.Position{Name: "Backend Engineer", DepartmentID: &itDept.ID}
		posManager := models.Position{Name: "Engineering Manager", DepartmentID: &itDept.ID}
		posAccountant := models.Position{Name: "Accountant", DepartmentID: &finDept.ID}
		posHR := models.Position{Name: "HR Officer", DepartmentID: &hrDept.ID}
		for _, p := range []*models.Position{&posBackend, &posManager, &posAccountant, &posHR} {
			if err := tx.Create(p).Error; err != nil {
				return err
			}
		}

		// --- Leave types ---
		for _, lt := range []*models.LeaveType{
			{Name: "Annual Leave", Description: "Cuti tahunan"},
			{Name: "Sick Leave", Description: "Cuti sakit"},
			{Name: "Unpaid Leave", Description: "Cuti tanpa gaji"},
		} {
			if err := tx.Create(lt).Error; err != nil {
				return err
			}
		}
		var annual models.LeaveType
		if err := tx.Where("name = ?", "Annual Leave").First(&annual).Error; err != nil {
			return err
		}

		// mk membuat User + Employee, mengembalikan employee.
		mk := func(email, code, name string, role models.Role, deptID, posID, managerID *string, salary float64) (*models.Employee, error) {
			u := models.User{Email: email, Password: hash, Role: role, IsActive: true}
			if err := tx.Create(&u).Error; err != nil {
				return nil, err
			}
			join := time.Date(2025, 1, 6, 0, 0, 0, 0, time.UTC)
			e := models.Employee{
				UserID: u.ID, EmployeeCode: code, FullName: name,
				Phone: "0812" + code, DepartmentID: deptID, PositionID: posID,
				ManagerID: managerID, JoinDate: &join,
				EmploymentStatus: "active", BasicSalary: salary,
			}
			if err := tx.Create(&e).Error; err != nil {
				return nil, err
			}
			return &e, nil
		}

		hrEmp, err := mk("hr@lsi.com", "HR-001", "Rina HR", models.RoleHR, &hrDept.ID, &posHR.ID, nil, 9000000)
		if err != nil {
			return err
		}
		mgrEmp, err := mk("manager@lsi.com", "MGR-001", "Andi Manager", models.RoleManager, &itDept.ID, &posManager.ID, nil, 15000000)
		if err != nil {
			return err
		}
		budi, err := mk("budi@lsi.com", "EMP-001", "Budi Santoso", models.RoleEmployee, &itDept.ID, &posBackend.ID, &mgrEmp.ID, 8000000)
		if err != nil {
			return err
		}
		_, err = mk("siti@lsi.com", "EMP-002", "Siti Aminah", models.RoleEmployee, &finDept.ID, &posAccountant.ID, &hrEmp.ID, 7500000)
		if err != nil {
			return err
		}

		// --- Attendance (hari ini, sudah check-in & check-out) untuk Budi ---
		today := time.Now()
		day := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, today.Location())
		in := time.Date(today.Year(), today.Month(), today.Day(), 8, 55, 0, 0, today.Location())
		out := time.Date(today.Year(), today.Month(), today.Day(), 17, 5, 0, 0, today.Location())
		if err := tx.Create(&models.Attendance{
			EmployeeID: budi.ID, AttendanceDate: day, CheckIn: &in, CheckOut: &out,
			WorkingMinutes: int(out.Sub(in).Minutes()), Status: "present",
		}).Error; err != nil {
			return err
		}

		// --- Leave request (pending) untuk Budi ---
		if err := tx.Create(&models.LeaveRequest{
			EmployeeID:  budi.ID,
			LeaveTypeID: annual.ID,
			StartDate:   time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC),
			EndDate:     time.Date(2026, 10, 3, 0, 0, 0, 0, time.UTC),
			Reason:      "Liburan keluarga",
			Status:      models.LeavePending,
		}).Error; err != nil {
			return err
		}

		// --- Payroll period + payroll untuk Budi ---
		period := models.PayrollPeriod{
			Name:      "September 2026",
			StartDate: time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC),
			EndDate:   time.Date(2026, 9, 30, 0, 0, 0, 0, time.UTC),
			Status:    "draft",
		}
		if err := tx.Create(&period).Error; err != nil {
			return err
		}
		gross := budi.BasicSalary + 1000000 + 500000 // basic + allowance + overtime
		if err := tx.Create(&models.Payroll{
			EmployeeID: budi.ID, PayrollPeriodID: period.ID,
			BasicSalary: budi.BasicSalary, TotalAllowance: 1000000, TotalOvertime: 500000,
			TotalDeduction: 300000, GrossSalary: gross, NetSalary: gross - 300000, Status: "draft",
		}).Error; err != nil {
			return err
		}

		// --- BPJS untuk Budi ---
		if err := tx.Create(&models.BPJS{
			EmployeeID: budi.ID, BPJSNumber: "0001234567890", BPJSType: "Kesehatan",
			EmployeeContribution: 80000, CompanyContribution: 320000, Status: "active",
		}).Error; err != nil {
			return err
		}

		log.Println("seeded demo data: 3 departments, 4 positions, 4 users (password: password123), attendance, leave, payroll, bpjs")
		return nil
	})
}
