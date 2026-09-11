package middleware

import (
	"strings"

	"hris-backend/internal/common"

	"github.com/gofiber/fiber/v2"
)

// JWTProtected memvalidasi access token lalu menaruh identitas di c.Locals.
func JWTProtected(secret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if !strings.HasPrefix(auth, "Bearer ") {
			return common.Fail(c, fiber.StatusUnauthorized, "Unauthorized")
		}
		claims, err := common.ParseToken(secret, strings.TrimPrefix(auth, "Bearer "))
		if err != nil {
			return common.Fail(c, fiber.StatusUnauthorized, "Unauthorized")
		}
		if claims.Type != common.TokenAccess {
			return common.Fail(c, fiber.StatusUnauthorized, "Invalid token type")
		}
		c.Locals("user_id", claims.Subject)
		c.Locals("employee_id", claims.EmployeeID)
		c.Locals("role", claims.Role)
		return c.Next()
	}
}
