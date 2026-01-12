package request

import (
	"context"
	"fmt"

	"mypremier-backend/internal/config"
)

// Repository provides data access for requests using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// Create inserts a new request and returns its generated ID.
// It looks up user_id from email and product_id from product_name.
func (r *Repository) Create(ctx context.Context, userEmail, productName, message string) (string, error) {
	// Look up user_id from email
	var userID string
	err := config.DB.QueryRow(ctx, `
		SELECT id::text FROM users WHERE email = $1 LIMIT 1
	`, userEmail).Scan(&userID)
	if err != nil {
		return "", fmt.Errorf("user not found with email %s: %w", userEmail, err)
	}

	// Look up product_id from product_name
	var productID string
	err = config.DB.QueryRow(ctx, `
		SELECT id::text FROM products WHERE name = $1 LIMIT 1
	`, productName).Scan(&productID)
	if err != nil {
		return "", fmt.Errorf("product not found with name %s: %w", productName, err)
	}

	// Insert request with user_id and product_id
	var id string
	err = config.DB.QueryRow(ctx, `
		INSERT INTO requests (user_id, product_id, message, status)
		VALUES ($1, $2, $3, 'pending')
		RETURNING id::text
	`, userID, productID, message).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	return id, nil
}

// CreateSalesRequest inserts a new sales request and returns the full created record.
// It uses the actual schema: user_email, product_name, message, status.
func (r *Repository) CreateSalesRequest(ctx context.Context, userEmail, productName, message string) (*SalesRequest, error) {
	var req SalesRequest
	err := config.DB.QueryRow(ctx, `
		INSERT INTO requests (user_email, product_name, message, status)
		VALUES ($1, $2, $3, 'pending')
		RETURNING 
			id::text,
			user_email,
			product_name,
			message,
			status,
			created_at
	`, userEmail, productName, message).Scan(
		&req.ID,
		&req.UserEmail,
		&req.ProductName,
		&req.Message,
		&req.Status,
		&req.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create sales request: %w", err)
	}

	return &req, nil
}

// GetAll retrieves all requests ordered by created_at descending.
// Reads directly from requests table which has user_email and product_name columns.
func (r *Repository) GetAll(ctx context.Context) ([]Request, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			product_name,
			message,
			status,
			created_at
		FROM requests
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch requests: %w", err)
	}
	defer rows.Close()

	var requests []Request

	for rows.Next() {
		var req Request

		if err := rows.Scan(&req.ID, &req.UserEmail, &req.ProductName, &req.Message, &req.Status, &req.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan request: %w", err)
		}

		requests = append(requests, req)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating requests: %w", err)
	}

	return requests, nil
}

// GetSalesRequestsByEmail retrieves all requests for a specific user email,
// ordered by created_at descending.
func (r *Repository) GetSalesRequestsByEmail(ctx context.Context, userEmail string) ([]SalesRequest, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			product_name,
			message,
			status,
			created_at
		FROM requests
		WHERE user_email = $1
		ORDER BY created_at DESC
	`, userEmail)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch sales requests: %w", err)
	}
	defer rows.Close()

	var requests []SalesRequest

	for rows.Next() {
		var req SalesRequest
		if err := rows.Scan(
			&req.ID,
			&req.UserEmail,
			&req.ProductName,
			&req.Message,
			&req.Status,
			&req.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan sales request: %w", err)
		}

		requests = append(requests, req)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating sales requests: %w", err)
	}

	return requests, nil
}