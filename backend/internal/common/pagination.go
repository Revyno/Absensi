package common

import "github.com/gofiber/fiber/v2"

func Paginate(c *fiber.Ctx) (page, limit int) {
	page = c.QueryInt("page", 1)
	limit = c.QueryInt("limit", 10)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	return page, limit
}
