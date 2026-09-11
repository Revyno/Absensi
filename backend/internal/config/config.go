package config

import (
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv               string
	Port                 string
	DatabaseURL          string
	JWTSecret            string
	AccessTokenDuration  time.Duration
	RefreshTokenDuration time.Duration

	SeedAdminEmail    string
	SeedAdminPassword string
}

func Load() *Config {
	_ = godotenv.Load()

	cfg := &Config{
		AppEnv:            env("APP_ENV", "development"),
		Port:              env("PORT", "3000"),
		DatabaseURL:       os.Getenv("DATABASE_URL"),
		JWTSecret:         env("JWT_SECRET", "change-this-secret"),
		SeedAdminEmail:    env("SEED_ADMIN_EMAIL", "admin@hris.local"),
		SeedAdminPassword: env("SEED_ADMIN_PASSWORD", "admin123"),
	}

	if cfg.DatabaseURL == "" {
		cfg.DatabaseURL = fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
			env("DB_HOST", "localhost"), env("DB_PORT", "5432"),
			env("DB_USER", "postgres"), env("DB_PASSWORD", "password"),
			env("DB_NAME", "hris"), env("DB_SSLMODE", "disable"),
		)
	}

	cfg.AccessTokenDuration = duration("ACCESS_TOKEN_DURATION", 15*time.Minute)
	cfg.RefreshTokenDuration = duration("REFRESH_TOKEN_DURATION", 168*time.Hour)
	return cfg
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func duration(key string, fallback time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
