package auth

import (
	"hris-backend/internal/common"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	res, err := h.svc.Login(req.Email, req.Password)
	if err != nil {
		return common.Fail(c, fiber.StatusUnauthorized, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Login successful", res)
}

func (h *Handler) Refresh(c *fiber.Ctx) error {
	var req RefreshRequest
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	res, err := h.svc.Refresh(req.RefreshToken)
	if err != nil {
		return common.Fail(c, fiber.StatusUnauthorized, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Token refreshed", res)
}

func (h *Handler) Logout(c *fiber.Ctx) error {
	return common.Success(c, fiber.StatusOK, "Logout successful", nil)
}

func (h *Handler) Me(c *fiber.Ctx) error {
	user, err := h.svc.Me(common.UserID(c))
	if err != nil {
		return common.Fail(c, fiber.StatusNotFound, "User not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", user)
}
