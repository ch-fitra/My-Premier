package stats

import (
	"context"
	"fmt"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/config"
)

// Repository provides aggregated statistics using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

func (r *Repository) CountProducts(ctx context.Context) (int, error) {
	var count int
	err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM products
	`).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count products: %w", err)
	}

	return count, nil
}

func (r *Repository) CountCategories(ctx context.Context) (int, error) {
	var count int
	err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM categories
	`).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count categories: %w", err)
	}

	return count, nil
}

func (r *Repository) CountRequests(ctx context.Context) (int, error) {
	var count int
	err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM requests
	`).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count requests: %w", err)
	}

	return count, nil
}

func (r *Repository) CountSupports(ctx context.Context) (int, error) {
	var count int
	err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM supports
	`).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count supports: %w", err)
	}

	return count, nil
}

// ---- Client-scoped aggregations ----

type ClientSummary struct {
	TotalRequests int `json:"total_requests"`
	OpenRequests  int `json:"open_requests"`
	TotalSupports int `json:"total_supports"`
	OpenSupports  int `json:"open_supports"`
}

// GetClientSummary aggregates request/support counts for the current client (by email).
func (r *Repository) GetClientSummary(ctx context.Context) (ClientSummary, error) {
	email := authcontext.GetUserEmail(ctx)
	if email == "" {
		return ClientSummary{}, fmt.Errorf("user email not in context")
	}

	var totalReq, openReq, totalSup, openSup int
	if err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM requests 
		WHERE user_email = $1
	`, email).Scan(&totalReq); err != nil {
		return ClientSummary{}, fmt.Errorf("failed to count client requests: %w", err)
	}
	if err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM requests 
		WHERE user_email = $1 AND status = 'open'
	`, email).Scan(&openReq); err != nil {
		return ClientSummary{}, fmt.Errorf("failed to count client open requests: %w", err)
	}
	if err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM supports 
		WHERE user_email = $1
	`, email).Scan(&totalSup); err != nil {
		return ClientSummary{}, fmt.Errorf("failed to count client supports: %w", err)
	}
	if err := config.DB.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM supports 
		WHERE user_email = $1 AND status = 'open'
	`, email).Scan(&openSup); err != nil {
		return ClientSummary{}, fmt.Errorf("failed to count client open supports: %w", err)
	}

	return ClientSummary{
		TotalRequests: totalReq,
		OpenRequests:  openReq,
		TotalSupports: totalSup,
		OpenSupports:  openSup,
	}, nil
}

