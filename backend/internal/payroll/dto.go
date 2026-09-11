package payroll

type PeriodRequest struct {
	Name      string `json:"name" validate:"required"`
	StartDate string `json:"start_date" validate:"required"` // YYYY-MM-DD
	EndDate   string `json:"end_date" validate:"required"`
}

// GenerateRequest: basic_salary diambil dari data employee; komponen lain diinput HR.
// ponytail: total_deduction sudah termasuk BPJS+tax+potongan lain. Auto-pull BPJS dari tabel bpjs = enhancement berikutnya.
type GenerateRequest struct {
	EmployeeID      string  `json:"employee_id" validate:"required"`
	PayrollPeriodID string  `json:"payroll_period_id" validate:"required"`
	TotalAllowance  float64 `json:"total_allowance"`
	TotalOvertime   float64 `json:"total_overtime"`
	TotalBonus      float64 `json:"total_bonus"`
	TotalDeduction  float64 `json:"total_deduction"`
}
