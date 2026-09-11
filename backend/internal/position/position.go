package position

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

type request struct {
	Name         string  `json:"name" validate:"required"`
	DepartmentID *string `json:"department_id"`
}

func (h *Handler) List(c *fiber.Ctx) error {
	var items []models.Position
	q := h.db.Preload("Department").Order("name")
	if dept := c.Query("department_id"); dept != "" {
		q = q.Where("department_id = ?", dept)
	}
	if err := q.Find(&items).Error; err != nil {
		return common.Fail(c, fiber.StatusInternalServerError, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "OK", items)
}

func (h *Handler) Create(c *fiber.Ctx) error {
	var req request
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	p := models.Position{Name: req.Name, DepartmentID: req.DepartmentID}
	if err := h.db.Create(&p).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "Position created", p)
}

func (h *Handler) Get(c *fiber.Ctx) error {
	var p models.Position
	if err := h.db.Preload("Department").First(&p, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Position not found")
	}
	return common.Success(c, fiber.StatusOK, "OK", p)
}

func (h *Handler) Update(c *fiber.Ctx) error {
	var p models.Position
	if err := h.db.First(&p, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "Position not found")
	}
	var req request
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	p.Name = req.Name
	if req.DepartmentID != nil {
		p.DepartmentID = req.DepartmentID
	}
	if err := h.db.Save(&p).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Position updated", p)
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	if err := h.db.Delete(&models.Position{}, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "Position deleted", nil)
}
