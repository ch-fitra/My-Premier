package user

import (
	"time"
)

// User represents a user in PostgreSQL
type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email"`
	Role         string    `json:"role"` // admin/sales/client/engineer
	FullName     string    `json:"full_name,omitempty"`
	Phone        string    `json:"phone,omitempty"`
	PasswordHash string    `json:"-"`    // never serialize to JSON
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at,omitempty"`
}

// Valid roles
const (
	RoleAdmin   = "admin"
	RoleSales   = "sales"
	RoleClient  = "client"
	RoleEngineer = "engineer"
)

// IsValidRole checks if the role is valid
func IsValidRole(role string) bool {
	return role == RoleAdmin || role == RoleSales || role == RoleClient || role == RoleEngineer
}

