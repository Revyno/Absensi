package employee

import (
	"hris-backend/internal/common"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Create(c *fiber.Ctx) error {
	var req CreateRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	emp, err := h.svc.Create(req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Employee created", emp)
}

func (h *Handler) List(c *fiber.Ctx) error {
	page, limit := common.Paginate(c)
	items, total, err := h.svc.List(page, limit, c.Query("search"), c.Query("department_id"))
	if err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.SuccessMeta(c, "OK", items, common.Meta{Page: page, Limit: limit, Total: total})
}

func (h *Handler) Get(c *fiber.Ctx) error {
	emp, err := h.svc.Get(c.Params("id"))
	if err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Employee not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", emp)
}

func (h *Handler) Update(c *fiber.Ctx) error {
	var req UpdateRequest
	if err := c.BodyParser(&req); err != nil {
		return common.Fail(c, fiber.StatusBadRequest, "Invalid request body")
	}
	emp, err := h.svc.Update(c.Params("id"), req)
	if err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Employee updated", emp)
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	if err := h.svc.Deactivate(c.Params("id")); err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Employee deactivated", nil)
}

// Profile mengembalikan data employee milik user yang login.
func (h *Handler) Profile(c *fiber.Ctx) error {
	emp, err := h.svc.GetByUserID(common.UserID(c))
	if err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Profile not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", emp)
}
