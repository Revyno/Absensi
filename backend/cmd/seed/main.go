// Command seed: jalankan migrasi + isi data contoh untuk testing semua route.
//
//	go run ./cmd/seed
package main

import (
	"log"

	"hris-backend/internal/config"
	"hris-backend/internal/database"
	"hris-backend/internal/seed"
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
		log.Fatalf("seed admin: %v", err)
	}
	if err := seed.Demo(db); err != nil {
		log.Fatalf("seed demo: %v", err)
	}
	log.Println("done")
}
