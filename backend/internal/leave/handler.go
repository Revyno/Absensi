package leave

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// --- Leave Types ---

func (h *Handler) ListTypes(c *fiber.Ctx) error {
	items, err := h.svc.ListTypes()
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "OK", items)
}

func (h *Handler) CreateType(c *fiber.Ctx) error {
	var req LeaveTypeRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	t, err := h.svc.CreateType(req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Leave type created", t)
}

// --- Leave Requests ---

func (h *Handler) Create(c *fiber.Ctx) error {
	empID := common.EmployeeID(c)
	if empID == "" {
		return common.Fail(c, fiber.StatusBadRequest, "Employee profile required")
	}
	var req CreateRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	lr, err := h.svc.Create(empID, req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Leave request created", lr)
}

// List: EMPLOYEE -> milik sendiri; MANAGER -> tim; HR/SUPER_ADMIN -> semua (filter ?employee_id, ?status).
func (h *Handler) List(c *fiber.Ctx) error {
	page, limit := common.Paginate(c)
	status := c.Query("status")
	var (
		items []models.LeaveRequest
		total int64
		err   error
	)
	switch common.CurrentRole(c) {
	case models.RoleEmployee:
		items, total, err = h.svc.List(page, limit, common.EmployeeID(c), status)
	case models.RoleManager:
		items, total, err = h.svc.ListTeam(common.EmployeeID(c), page, limit, status)
	default:
		items, total, err = h.svc.List(page, limit, c.Query("employee_id"), status)
	}
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.SuccessMeta(c, "OK", items, common.Meta{Page: page, Limit: limit, Total: total})
}

func (h *Handler) Get(c *fiber.Ctx) error {
	lr, err := h.svc.Get(c.Params("id"))
	if err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Leave request not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", lr)
}

func (h *Handler) Cancel(c *fiber.Ctx) error {
	lr, err := h.svc.Cancel(c.Params("id"), common.EmployeeID(c))
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Leave request cancelled", lr)
}

func (h *Handler) Approve(c *fiber.Ctx) error {
	lr, err := h.svc.Approve(c.Params("id"), common.UserID(c))
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Leave request approved", lr)
}

func (h *Handler) Reject(c *fiber.Ctx) error {
	lr, err := h.svc.Reject(c.Params("id"), common.UserID(c))
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Leave request rejected", lr)
}
