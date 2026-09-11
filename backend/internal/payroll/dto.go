package payroll

type PeriodRequest struct {
	Name      string `json:"name" validate:"required"`
	StartDate string `json:"start_date" validate:"required"`
	EndDate   string `json:"end_date" validate:"required"`
}

type GenerateRequest struct {
	EmployeeID      string  `json:"employee_id" validate:"required"`
	PayrollPeriodID string  `json:"payroll_period_id" validate:"required"`
	TotalAllowance  float64 `json:"total_allowance"`
	TotalOvertime   float64 `json:"total_overtime"`
	TotalBonus      float64 `json:"total_bonus"`
	TotalDeduction  float64 `json:"total_deduction"`
}
