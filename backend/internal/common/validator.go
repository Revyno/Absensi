package common

import (
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

var validate = validator.New()

// Validate mengembalikan map field->pesan, atau nil jika valid.
func Validate(s any) map[string][]string {
	err := validate.Struct(s)
	if err == nil {
		return nil
	}
	out := map[string][]string{}
	for _, e := range err.(validator.ValidationErrors) {
		field := e.Field()
		out[field] = append(out[field], messageFor(e))
	}
	return out
}

// BindAndValidate parse body JSON lalu validasi. Return false jika sudah membalas error.
func BindAndValidate(c *fiber.Ctx, out any) bool {
	if err := c.BodyParser(out); err != nil {
		_ = Fail(c, fiber.StatusBadRequest, "Invalid request body")
		return false
	}
	if errs := Validate(out); errs != nil {
		_ = FailValidation(c, errs)
		return false
	}
	return true
}

func messageFor(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return e.Field() + " is required"
	case "email":
		return e.Field() + " must be a valid email"
	case "min":
		return e.Field() + " must be at least " + e.Param() + " characters"
	case "oneof":
		return e.Field() + " must be one of: " + e.Param()
	default:
		return e.Field() + " is invalid"
	}
}
