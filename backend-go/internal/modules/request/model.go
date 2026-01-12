package request

import "time"

// Request represents a request/quotation in PostgreSQL.
// This is used by the admin endpoints to display requests with joined user and product data.
type Request struct {
	ID          string    `json:"id"`
	UserEmail   string    `json:"user_email"`   // From JOIN with users table
	ProductName string    `json:"product_name"` // From JOIN with products table
	Message     string    `json:"message"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

// CreateRequestInput represents the input for creating a legacy public request.
type CreateRequestInput struct {
	UserEmail   string `json:"user_email"`
	ProductName string `json:"product_name"`
	Message     string `json:"message"`
}

// CreateRequestResponse represents the response after creating a legacy request.
type CreateRequestResponse struct {
	ID string `json:"id"`
}

// SalesCreateRequestInput represents the input for creating a sales request
// from the authenticated Sales mobile app.
type SalesCreateRequestInput struct {
	ProductName string `json:"product_name"`
	Message     string `json:"message"`
}

// SalesRequest represents a request created by a sales user for a product.
// This matches the actual database schema with user_email and product_name.
type SalesRequest struct {
	ID          string    `json:"id"`
	UserEmail   string    `json:"user_email"`
	ProductName string    `json:"product_name"`
	Message     string    `json:"message"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}
