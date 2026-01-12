package support

import "time"

// SupportMessage represents a message in a support chat in PostgreSQL
// Note: Database column is "sender", but JSON field is "sender_type" for API compatibility
type SupportMessage struct {
	ID         string    `json:"id"`
	SupportID  string    `json:"support_id"`
	SenderType string    `json:"sender_type"` // Allowed values: "client", "sales", "admin"
	Message    string    `json:"message"`
	CreatedAt  time.Time `json:"created_at"`
}

// CreateMessageInput represents the input for creating a support message
type CreateMessageInput struct {
	Message    string `json:"message"`
	SenderType string `json:"sender_type"` // Allowed values: "client", "sales", "admin"
}

// CreateMessageResponse represents the response after creating a message
type CreateMessageResponse struct {
	ID         string    `json:"id"`
	SupportID  string    `json:"support_id"`
	SenderType string    `json:"sender_type"`
	Message    string    `json:"message"`
	CreatedAt  time.Time `json:"created_at"`
}
