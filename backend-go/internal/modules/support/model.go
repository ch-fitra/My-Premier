package support

import "time"

// Support represents a support request in PostgreSQL
type Support struct {
	ID        string    `json:"id"`
	UserEmail string    `json:"user_email"`
	Subject   string    `json:"subject"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateSupportInput represents the input for creating a support request
type CreateSupportInput struct {
	UserEmail string `json:"user_email"`
	Subject   string `json:"subject"`
}

// CreateSupportResponse represents the response after creating a support request
type CreateSupportResponse struct {
	ID string `json:"id"`
}

// SalesCreateSupportInput represents the input for creating a support from sales mobile app
type SalesCreateSupportInput struct {
	Subject string `json:"subject"`
	Message string `json:"message"`
}

// SupportDetailResponse represents support with messages
type SupportDetailResponse struct {
	Support  Support          `json:"support"`
	Messages []SupportMessage `json:"messages"`
}
