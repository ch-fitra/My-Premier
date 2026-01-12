package config

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// DB is the shared PostgreSQL connection pool for the application.
var DB *pgxpool.Pool

// InitDatabase initializes the global PostgreSQL connection pool using
// the DATABASE_URL environment variable.
//
// Example DATABASE_URL for Supabase:
//   postgres://user:password@host:5432/dbname
func InitDatabase(ctx context.Context) {
	if DB != nil {
		// Already initialized.
		return
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	cfg, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		log.Fatalf("failed to parse DATABASE_URL: %v", err)
	}

	// Sensible defaults; can be tuned as needed.
	cfg.MaxConns = 10
	cfg.MinConns = 2
	cfg.MaxConnLifetime = time.Hour
	cfg.MaxConnIdleTime = 30 * time.Minute

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("failed to initialize database connection pool: %v", err)
	}

	DB = pool
	log.Println("✅ PostgreSQL connection pool initialized")
}

// CloseDatabase closes the global PostgreSQL connection pool.
func CloseDatabase() {
	if DB != nil {
		DB.Close()
		DB = nil
	}
}


