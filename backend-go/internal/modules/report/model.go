package report

import "time"

// EngineerReport represents a daily report created by an engineer.
type EngineerReport struct {
	ID          string    `json:"id"`
	UserEmail   string    `json:"user_email"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Notes       *string   `json:"notes,omitempty"` // nullable
	Status      string    `json:"status"`          // draft, submitted, approved
	CreatedAt   time.Time `json:"created_at"`
}

// CreateReportInput represents the input for creating a new engineer report.
type CreateReportInput struct {
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Notes       *string `json:"notes,omitempty"`
	Date        *string `json:"date,omitempty"` // Optional date for the report in YYYY-MM-DD format. If not provided, uses current timestamp.
}
