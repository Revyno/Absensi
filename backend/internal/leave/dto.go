package leave

type CreateRequest struct {
	LeaveTypeID string `json:"leave_type_id" validate:"required"`
	StartDate   string `json:"start_date" validate:"required"`
	EndDate     string `json:"end_date" validate:"required"`
	Reason      string `json:"reason"`
	Attachment  string `json:"attachment"`
}

type LeaveTypeRequest struct {
	Name        string `json:"name" validate:"required"`
	Description string `json:"description"`
}
