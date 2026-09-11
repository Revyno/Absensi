package main

import (
	"log"

	"hris-backend/internal/config"
	"hris-backend/internal/database"
	"hris-backend/internal/router"
	"hris-backend/internal/seed"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database connect: %v", err)
	}
	if err := database.Migrate(db); err != nil {
		log.Fatalf("database migrate: %v", err)
	}
	if err := seed.Run(db, cfg); err != nil {
		log.Fatalf("seed: %v", err)
	}

	app := fiber.New(fiber.Config{AppName: "HRIS API"})
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New())

	router.Setup(app, db, cfg)

	log.Printf("HRIS API listening on :%s (env=%s)", cfg.Port, cfg.AppEnv)
	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatal(err)
	}
}
