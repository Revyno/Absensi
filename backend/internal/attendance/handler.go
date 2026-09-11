package attendance

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) CheckIn(c *fiber.Ctx) error {
	empID := common.EmployeeID(c)
	if empID == "" {
		return common.Fail(c, fiber.StatusBadRequest, "Employee profile required")
	}
	att, err := h.svc.CheckIn(empID)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Checked in", att)
}

func (h *Handler) CheckOut(c *fiber.Ctx) error {
	empID := common.EmployeeID(c)
	if empID == "" {
		return common.Fail(c, fiber.StatusBadRequest, "Employee profile required")
	}
	att, err := h.svc.CheckOut(empID)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Checked out", att)
}

func (h *Handler) List(c *fiber.Ctx) error {
	page, limit := common.Paginate(c)
	empFilter := c.Query("employee_id")
	if common.CurrentRole(c) == models.RoleEmployee {
		empFilter = common.EmployeeID(c)
	}
	items, total, err := h.svc.List(page, limit, empFilter, c.Query("date"))
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.SuccessMeta(c, "OK", items, common.Meta{Page: page, Limit: limit, Total: total})
}

func (h *Handler) History(c *fiber.Ctx) error {
	empID := common.EmployeeID(c)
	if empID == "" {
		return common.Fail(c, fiber.StatusBadRequest, "Employee profile required")
	}
	page, limit := common.Paginate(c)
	items, total, err := h.svc.List(page, limit, empID, "")
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.SuccessMeta(c, "OK", items, common.Meta{Page: page, Limit: limit, Total: total})
}
