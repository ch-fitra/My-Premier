package support

import (
	"context"
	"fmt"

	"mypremier-backend/internal/config"
)

// Repository provides data access for supports using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// Create inserts a new support request and returns its generated ID.
func (r *Repository) Create(ctx context.Context, userEmail, subject string) (string, error) {
	var id string
	err := config.DB.QueryRow(ctx, `
		INSERT INTO supports (user_email, subject)
		VALUES ($1, $2)
		RETURNING id::text
	`, userEmail, subject).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to create support request (SQL error): %w", err)
	}

	return id, nil
}

// GetAll retrieves all support requests ordered by created_at descending.
func (r *Repository) GetAll(ctx context.Context) ([]Support, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			subject,
			created_at
		FROM supports
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch supports: %w", err)
	}
	defer rows.Close()

	var supports []Support

	for rows.Next() {
		var sup Support

		if err := rows.Scan(&sup.ID, &sup.UserEmail, &sup.Subject, &sup.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan support: %w", err)
		}

		supports = append(supports, sup)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating supports: %w", err)
	}

	// Ensure we always return an array, never nil
	if supports == nil {
		supports = []Support{}
	}

	return supports, nil
}

// UpdateStatus updates the status of a support request.
func (r *Repository) UpdateStatus(ctx context.Context, id string, status string) error {
	_, err := config.DB.Exec(ctx, `
		UPDATE supports
		SET status = $1
		WHERE id = $2::uuid
	`, status, id)
	if err != nil {
		return fmt.Errorf("failed to update support status (SQL error): %w", err)
	}
	return nil
}

// CreateSalesSupport inserts a new support request for sales and returns the full created record.
func (r *Repository) CreateSalesSupport(ctx context.Context, userEmail, subject string) (*Support, error) {
	var sup Support
	err := config.DB.QueryRow(ctx, `
		INSERT INTO supports (user_email, subject)
		VALUES ($1, $2)
		RETURNING 
			id::text,
			user_email,
			subject,
			status,
			created_at
	`, userEmail, subject).Scan(
		&sup.ID,
		&sup.UserEmail,
		&sup.Subject,
		&sup.Status,
		&sup.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create sales support (SQL error): %w", err)
	}

	return &sup, nil
}

// GetSalesSupportsByEmail retrieves all supports for a specific user email,
// ordered by created_at descending.
func (r *Repository) GetSalesSupportsByEmail(ctx context.Context, userEmail string) ([]Support, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			subject,
			status,
			created_at
		FROM supports
		WHERE user_email = $1
		ORDER BY created_at DESC
	`, userEmail)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch sales supports (SQL error): %w", err)
	}
	defer rows.Close()

	var supports []Support

	for rows.Next() {
		var sup Support
		if err := rows.Scan(
			&sup.ID,
			&sup.UserEmail,
			&sup.Subject,
			&sup.Status,
			&sup.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan support: %w", err)
		}

		supports = append(supports, sup)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating supports: %w", err)
	}

	// Ensure we always return an array, never nil
	if supports == nil {
		supports = []Support{}
	}

	return supports, nil
}

// GetClientSupportsByEmail retrieves all supports for a specific client email,
// ordered by created_at descending. This is used by the client mobile app.
func (r *Repository) GetClientSupportsByEmail(ctx context.Context, userEmail string) ([]Support, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT id::text, user_email, subject, status, created_at
		FROM supports
		WHERE user_email = $1
		ORDER BY created_at DESC
	`, userEmail)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch client supports (SQL error): %w", err)
	}
	defer rows.Close()

	var supports []Support

	for rows.Next() {
		var sup Support
		if err := rows.Scan(
			&sup.ID,
			&sup.UserEmail,
			&sup.Subject,
			&sup.Status,
			&sup.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan client support: %w", err)
		}

		supports = append(supports, sup)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating client supports: %w", err)
	}

	// Ensure we always return an array, never nil
	if supports == nil {
		supports = []Support{}
	}

	return supports, nil
}

// GetByID retrieves a support by ID.
func (r *Repository) GetByID(ctx context.Context, id string) (*Support, error) {
	var sup Support
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id::text,
			user_email,
			subject,
			status,
			created_at
		FROM supports
		WHERE id = $1::uuid
	`, id).Scan(
		&sup.ID,
		&sup.UserEmail,
		&sup.Subject,
		&sup.Status,
		&sup.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch support (SQL error): %w", err)
	}

	return &sup, nil
}

// GetByIDAndEmail retrieves a support by ID and user email, ensuring ownership.
func (r *Repository) GetByIDAndEmail(ctx context.Context, id, userEmail string) (*Support, error) {
	var sup Support
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id::text,
			user_email,
			subject,
			status,
			created_at
		FROM supports
		WHERE id = $1::uuid
		  AND user_email = $2
	`, id, userEmail).Scan(
		&sup.ID,
		&sup.UserEmail,
		&sup.Subject,
		&sup.Status,
		&sup.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch support for client (SQL error): %w", err)
	}

	return &sup, nil
}
