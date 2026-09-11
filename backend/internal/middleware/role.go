package middleware

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
)

func RequireRole(roles ...models.Role) fiber.Handler {
	allowed := make(map[string]bool, len(roles))
	for _, r := range roles {
		allowed[string(r)] = true
	}
	return func(c *fiber.Ctx) error {
		if role, _ := c.Locals("role").(string); !allowed[role] {
			return common.Fail(c, fiber.StatusForbidden, "Forbidden")
		}
		return c.Next()
	}
}
