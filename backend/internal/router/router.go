package router

import (
	"hris-backend/internal/attendance"
	"hris-backend/internal/auth"
	"hris-backend/internal/bpjs"
	"hris-backend/internal/config"
	"hris-backend/internal/department"
	"hris-backend/internal/docs"
	"hris-backend/internal/employee"
	"hris-backend/internal/leave"
	"hris-backend/internal/middleware"
	"hris-backend/internal/models"
	"hris-backend/internal/payroll"
	"hris-backend/internal/position"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

func Setup(app *fiber.App, db *gorm.DB, cfg *config.Config) {
	authH := auth.NewHandler(auth.NewService(auth.NewRepository(db), cfg))
	empH := employee.NewHandler(employee.NewService(employee.NewRepository(db)))
	deptH := department.NewHandler(db)
	posH := position.NewHandler(db)
	attH := attendance.NewHandler(attendance.NewService(attendance.NewRepository(db)))
	leaveH := leave.NewHandler(leave.NewService(leave.NewRepository(db)))
	payH := payroll.NewHandler(payroll.NewService(payroll.NewRepository(db)))
	bpjsH := bpjs.NewHandler(db)

	protected := middleware.JWTProtected(cfg.JWTSecret)
	hrAdmin := middleware.RequireRole(models.RoleSuperAdmin, models.RoleHR)
	managerUp := middleware.RequireRole(models.RoleSuperAdmin, models.RoleHR, models.RoleManager)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	docs.Mount(app) // Swagger UI di /docs

	api := app.Group("/api/v1")

	// Auth
	a := api.Group("/auth")
	a.Post("/login", authH.Login)
	a.Post("/refresh", authH.Refresh)
	a.Post("/logout", protected, authH.Logout)
	a.Get("/me", protected, authH.Me)

	// Employees
	e := api.Group("/employees", protected)
	e.Get("/", empH.List)
	e.Post("/", hrAdmin, empH.Create)
	e.Get("/me", empH.Profile) // harus sebelum "/:id"
	e.Get("/:id", empH.Get)
	e.Put("/:id", hrAdmin, empH.Update)
	e.Delete("/:id", hrAdmin, empH.Delete)

	// Departments
	d := api.Group("/departments", protected)
	d.Get("/", deptH.List)
	d.Post("/", hrAdmin, deptH.Create)
	d.Get("/:id", deptH.Get)
	d.Put("/:id", hrAdmin, deptH.Update)
	d.Delete("/:id", hrAdmin, deptH.Delete)

	// Positions
	p := api.Group("/positions", protected)
	p.Get("/", posH.List)
	p.Post("/", hrAdmin, posH.Create)
	p.Get("/:id", posH.Get)
	p.Put("/:id", hrAdmin, posH.Update)
	p.Delete("/:id", hrAdmin, posH.Delete)

	// Attendance
	at := api.Group("/attendance", protected)
	at.Post("/check-in", attH.CheckIn)
	at.Post("/check-out", attH.CheckOut)
	at.Get("/history", attH.History) // harus sebelum "/"
	at.Get("/", attH.List)

	// Leave types
	lt := api.Group("/leave-types", protected)
	lt.Get("/", leaveH.ListTypes)
	lt.Post("/", hrAdmin, leaveH.CreateType)

	// Leave requests
	l := api.Group("/leaves", protected)
	l.Get("/", leaveH.List)
	l.Post("/", leaveH.Create)
	l.Get("/:id", leaveH.Get)
	l.Post("/:id/cancel", leaveH.Cancel)
	l.Post("/:id/approve", managerUp, leaveH.Approve)
	l.Post("/:id/reject", managerUp, leaveH.Reject)

	// Payroll periods
	pp := api.Group("/payroll-periods", protected)
	pp.Get("/", managerUp, payH.ListPeriods)
	pp.Post("/", hrAdmin, payH.CreatePeriod)

	// Payrolls
	pr := api.Group("/payrolls", protected)
	pr.Get("/", payH.List)
	pr.Post("/", hrAdmin, payH.Generate)
	pr.Get("/:id", payH.Get)
	pr.Post("/:id/publish", hrAdmin, payH.Publish)

	// BPJS
	b := api.Group("/bpjs", protected)
	b.Get("/", bpjsH.List)
	b.Post("/", hrAdmin, bpjsH.Create)
	b.Get("/:id", bpjsH.Get)
	b.Put("/:id", hrAdmin, bpjsH.Update)
}
