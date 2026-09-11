// Package department: lookup sederhana, jadi handler langsung ke DB (tanpa layer service/repo terpisah).
package department

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

type request struct {
	Name string `json:"name" validate:"required"`
}

func (h *Handler) List(c *fiber.Ctx) error {
	var items []models.Department
	if err := h.db.Order("name").Find(&items).Error; err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "OK", items)
}

func (h *Handler) Create(c *fiber.Ctx) error {
	var req request
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	d := models.Department{Name: req.Name}
	if err := h.db.Create(&d).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Department created", d)
}

func (h *Handler) Get(c *fiber.Ctx) error {
	var d models.Department
	if err := h.db.First(&d, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Department not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", d)
}

func (h *Handler) Update(c *fiber.Ctx) error {
	var d models.Department
	if err := h.db.First(&d, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Department not found")
	}
	var req request
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	d.Name = req.Name
	if err := h.db.Save(&d).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Department updated", d)
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	if err := h.db.Delete(&models.Department{}, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Department deleted", nil)
}
