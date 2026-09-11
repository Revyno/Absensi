// Package bpjs: CRUD data BPJS. Handler langsung ke DB (thin).
package bpjs

import (
	"hris-backend/internal/common"
	"hris-backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

type request struct {
	EmployeeID           string  `json:"employee_id" validate:"required"`
	BPJSNumber           string  `json:"bpjs_number"`
	BPJSType             string  `json:"bpjs_type"`
	EmployeeContribution float64 `json:"employee_contribution"`
	CompanyContribution  float64 `json:"company_contribution"`
	Status               string  `json:"status"`
}

// List: EMPLOYEE hanya melihat BPJS miliknya; role lain bisa filter ?employee_id.
func (h *Handler) List(c *fiber.Ctx) error {
	var items []models.BPJS
	q := h.db.Preload("Employee").Order("created_at DESC")
	empFilter := c.Query("employee_id")
	if common.CurrentRole(c) == models.RoleEmployee {
		empFilter = common.EmployeeID(c)
	}
	if empFilter != "" {
		q = q.Where("employee_id = ?", empFilter)
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
	b := models.BPJS{
		EmployeeID:           req.EmployeeID,
		BPJSNumber:           req.BPJSNumber,
		BPJSType:             req.BPJSType,
		EmployeeContribution: req.EmployeeContribution,
		CompanyContribution:  req.CompanyContribution,
		Status:               defaultStr(req.Status, "active"),
	}
	if err := h.db.Create(&b).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusCreated, "BPJS created", b)
}

func (h *Handler) Get(c *fiber.Ctx) error {
	var b models.BPJS
	if err := h.db.Preload("Employee").First(&b, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "BPJS not found")
	}
	if common.CurrentRole(c) == models.RoleEmployee && b.EmployeeID != common.EmployeeID(c) {
		return common.Fail(c, fiber.StatusForbidden, "Forbidden")
	}
	return common.Success(c, fiber.StatusOK, "OK", b)
}

func (h *Handler) Update(c *fiber.Ctx) error {
	var b models.BPJS
	if err := h.db.First(&b, "id = ?", c.Params("id")).Error; err != nil {
		return common.Fail(c, fiber.StatusNotFound, "BPJS not found")
	}
	var req request
	if !common.BindAndValidate(c, &req) {
		return nil
	}
	b.BPJSNumber = req.BPJSNumber
	b.BPJSType = req.BPJSType
	b.EmployeeContribution = req.EmployeeContribution
	b.CompanyContribution = req.CompanyContribution
	if req.Status != "" {
		b.Status = req.Status
	}
	if err := h.db.Save(&b).Error; err != nil {
		return common.Fail(c, fiber.StatusBadRequest, err.Error())
	}
	return common.Success(c, fiber.StatusOK, "BPJS updated", b)
}

func defaultStr(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}
