package common

import (
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func UserID(c *fiber.Ctx) string {
	v, _ := c.Locals("user_id").(string)
	return v
}

func EmployeeID(c *fiber.Ctx) string {
	v, _ := c.Locals("employee_id").(string)
	return v
}

func CurrentRole(c *fiber.Ctx) models.Role {
	v, _ := c.Locals("role").(string)
	return models.Role(v)
}
