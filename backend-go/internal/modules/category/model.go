package category

import "time"

// Category represents a category in PostgreSQL
type Category struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

