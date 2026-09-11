package employee

type CreateRequest struct {
	Email        string  `json:"email" validate:"required,email"`
	Password     string  `json:"password" validate:"required,min=6"`
	Role         string  `json:"role" validate:"omitempty,oneof=SUPER_ADMIN HR MANAGER EMPLOYEE"`
	EmployeeCode string  `json:"employee_code" validate:"required"`
	FullName     string  `json:"full_name" validate:"required"`
	Phone        string  `json:"phone"`
	DepartmentID *string `json:"department_id"`
	PositionID   *string `json:"position_id"`
	ManagerID    *string `json:"manager_id"`
	JoinDate     string  `json:"join_date"`
	BasicSalary  float64 `json:"basic_salary"`
}

type UpdateRequest struct {
	FullName         *string  `json:"full_name"`
	Phone            *string  `json:"phone"`
	DepartmentID     *string  `json:"department_id"`
	PositionID       *string  `json:"position_id"`
	ManagerID        *string  `json:"manager_id"`
	JoinDate         *string  `json:"join_date"`
	EmploymentStatus *string  `json:"employment_status"`
	BasicSalary      *float64 `json:"basic_salary"`
}
