package payroll

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) CreatePeriod(c *fiber.Ctx) error {
	var req PeriodRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	p, err := h.svc.CreatePeriod(req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Payroll period created", p)
}

func (h *Handler) ListPeriods(c *fiber.Ctx) error {
	items, err := h.svc.ListPeriods()
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "OK", items)
}

func (h *Handler) Generate(c *fiber.Ctx) error {
	var req GenerateRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	p, err := h.svc.Generate(req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Payroll generated", p)
}

// List: EMPLOYEE hanya melihat payroll miliknya yang sudah published.
func (h *Handler) List(c *fiber.Ctx) error {
	page, limit := common.Paginate(c)
	empFilter := c.Query("employee_id")
	status := c.Query("status")
	if common.CurrentRole(c) == models.RoleEmployee {
		empFilter = common.EmployeeID(c)
		status = "published"
	}
	items, total, err := h.svc.List(page, limit, empFilter, c.Query("payroll_period_id"), status)
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.SuccessMeta(c, "OK", items, common.Meta{Page: page, Limit: limit, Total: total})
}

// Get berfungsi sebagai payslip. EMPLOYEE hanya boleh payroll miliknya yang published.
func (h *Handler) Get(c *fiber.Ctx) error {
	p, err := h.svc.Get(c.Params("id"))
	if err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Payroll not found")
	}
	if common.CurrentRole(c) == models.RoleEmployee {
		if p.EmployeeID != common.EmployeeID(c) || p.Status != "published" {
			return common.Fail(c, fiber.StatusForbidden, "Forbidden")
		}
	}
	return common.Success(c, fiber.StatusOK, "OK", p)
}

func (h *Handler) Publish(c *fiber.Ctx) error {
	p, err := h.svc.Publish(c.Params("id"))
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Payroll published", p)
}
