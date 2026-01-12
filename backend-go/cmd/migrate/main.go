package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"

	"mypremier-backend/internal/config"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("⚠️  Could not load .env file: %v", err)
	}

	if strings.TrimSpace(os.Getenv("DATABASE_URL")) == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	ctx := context.Background()
	config.InitDatabase(ctx)
	defer config.CloseDatabase()

	if len(os.Args) < 2 {
		log.Fatal("Usage: go run cmd/migrate/main.go <migration_file.sql>")
	}

	migrationFile := os.Args[1]
	sql, err := os.ReadFile(migrationFile)
	if err != nil {
		log.Fatalf("Failed to read migration file: %v", err)
	}

	// Execute the migration
	_, err = config.DB.Exec(ctx, string(sql))
	if err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	fmt.Printf("✅ Migration %s executed successfully\n", migrationFile)
}

