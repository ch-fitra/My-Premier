package user

import (
	"context"
	"errors"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"

	"mypremier-backend/internal/config"
)

// Repository provides data access for users using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// GetAll retrieves all users ordered by creation time descending.
func (r *Repository) GetAll(ctx context.Context) ([]User, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id,
			email,
			role,
			full_name,
			phone,
			created_at,
			updated_at
		FROM users
		ORDER BY created_at DESC
	`)
	if err != nil {
		log.Printf("SQL Error in GetAll: %v", err)
		return nil, fmt.Errorf("failed to fetch users: %w", err)
	}
	defer rows.Close()

	var users []User

	for rows.Next() {
		var u User
		var fullName, phone *string
		if err := rows.Scan(
			&u.ID,
			&u.Email,
			&u.Role,
			&fullName,
			&phone,
			&u.CreatedAt,
			&u.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}

		if fullName != nil {
			u.FullName = *fullName
		}
		if phone != nil {
			u.Phone = *phone
		}

		users = append(users, u)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating users: %w", err)
	}

	return users, nil
}

// GetByEmail retrieves a user by their email (used for login).
func (r *Repository) GetByEmail(ctx context.Context, email string) (*User, error) {
	var u User
	var fullName, phone *string
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id,
			email,
			role,
			full_name,
			phone,
			password_hash,
			created_at,
			updated_at
		FROM users
		WHERE email = $1
	`, email).Scan(
		&u.ID,
		&u.Email,
		&u.Role,
		&fullName,
		&phone,
		&u.PasswordHash,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			log.Printf("User not found by email: %s", email)
			return nil, fmt.Errorf("user not found")
		}
		log.Printf("SQL Error in GetByEmail for email %s: %v", email, err)
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if fullName != nil {
		u.FullName = *fullName
	}
	if phone != nil {
		u.Phone = *phone
	}

	return &u, nil
}

// GetByEmailAndPassword retrieves a user by email and password using pgcrypto.
// Returns the user if credentials are valid, otherwise returns an error.
func (r *Repository) GetByEmailAndPassword(ctx context.Context, email, password string) (*User, error) {
	var u User
	var fullName, phone *string
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id,
			email,
			role,
			full_name,
			phone,
			created_at,
			updated_at
		FROM users
		WHERE email = $1
		  AND password_hash = crypt($2, password_hash)
		LIMIT 1
	`, email, password).Scan(
		&u.ID,
		&u.Email,
		&u.Role,
		&fullName,
		&phone,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("user not found")
		}
		log.Printf("SQL Error in GetByEmailAndPassword for email %s: %v", email, err)
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if fullName != nil {
		u.FullName = *fullName
	}
	if phone != nil {
		u.Phone = *phone
	}

	return &u, nil
}

// GetByID retrieves a user by their ID.
func (r *Repository) GetByID(ctx context.Context, id string) (*User, error) {
	var u User
	var fullName, phone *string
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id,
			email,
			role,
			full_name,
			phone,
			password_hash,
			created_at,
			updated_at
		FROM users
		WHERE id = $1
	`, id).Scan(
		&u.ID,
		&u.Email,
		&u.Role,
		&fullName,
		&phone,
		&u.PasswordHash,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if fullName != nil {
		u.FullName = *fullName
	}
	if phone != nil {
		u.Phone = *phone
	}

	return &u, nil
}

// GetByIDForMe retrieves user profile data for the /me endpoint.
func (r *Repository) GetByIDForMe(ctx context.Context, id string) (*User, error) {
	var u User
	var fullName, phone *string
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id,
			email,
			role,
			full_name,
			phone,
			created_at,
			updated_at
		FROM users
		WHERE id = $1
	`, id).Scan(
		&u.ID,
		&u.Email,
		&u.Role,
		&fullName,
		&phone,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if fullName != nil {
		u.FullName = *fullName
	}
	if phone != nil {
		u.Phone = *phone
	}

	return &u, nil
}

// UpdateRole updates the role of a user by ID.
func (r *Repository) UpdateRole(ctx context.Context, id string, role string) error {
	if !IsValidRole(role) {
		return fmt.Errorf("invalid role: %s. Must be one of: admin, sales, client", role)
	}

	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE users
		SET role = $1
		WHERE id = $2
	`, role, id)
	if err != nil {
		log.Printf("SQL Error updating user role for id %s: %v", id, err)
		return fmt.Errorf("failed to update user role: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for role update: id %s", id)
		return fmt.Errorf("user not found")
	}

	log.Printf("Updated role for user id %s to %s, rows affected: %d", id, role, cmdTag.RowsAffected())
	return nil
}

// UpdateStatus is deprecated - users table does not have is_active column
// This method is kept for backward compatibility but will return an error
func (r *Repository) UpdateStatus(ctx context.Context, id string, isActive bool) error {
	return fmt.Errorf("user status update is not supported - is_active column does not exist")
}

// UpdatePasswordHashByEmail updates the password hash for a user by email.
func (r *Repository) UpdatePasswordHashByEmail(ctx context.Context, email string, passwordHash string) error {
	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE users
		SET password_hash = $1
		WHERE email = $2
	`, passwordHash, email)
	if err != nil {
		log.Printf("SQL Error updating password hash for email %s: %v", email, err)
		return fmt.Errorf("failed to update password hash: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for password hash update: email %s", email)
		return fmt.Errorf("user not found")
	}

	log.Printf("Updated password hash for user email %s, rows affected: %d", email, cmdTag.RowsAffected())
	return nil
}

// UpdateProfile updates full_name and phone for a user by ID.
func (r *Repository) UpdateProfile(ctx context.Context, id string, fullName, phone string) error {
	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE users
		SET full_name = $1,
		    phone = $2,
		    updated_at = NOW()
		WHERE id = $3
	`, fullName, phone, id)
	if err != nil {
		log.Printf("SQL Error updating profile for id %s: %v", id, err)
		return fmt.Errorf("failed to update profile: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for profile update: id %s", id)
		return fmt.Errorf("user not found")
	}

	log.Printf("Updated profile for user id %s, rows affected: %d", id, cmdTag.RowsAffected())
	return nil
}

// UpdatePasswordByID updates the password for a user by ID using pgcrypto.
// It verifies the old password before updating.
func (r *Repository) UpdatePasswordByID(ctx context.Context, id string, oldPassword, newPassword string) error {
	// First, verify the old password
	var userID string
	err := config.DB.QueryRow(ctx, `
		SELECT id
		FROM users
		WHERE id = $1
		  AND password_hash = crypt($2, password_hash)
	`, id, oldPassword).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("invalid old password")
		}
		log.Printf("SQL Error verifying old password for id %s: %v", id, err)
		return fmt.Errorf("failed to verify old password: %w", err)
	}

	// Update password using pgcrypto
	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE users
		SET password_hash = crypt($1, gen_salt('bf')),
		    updated_at = NOW()
		WHERE id = $2
	`, newPassword, id)
	if err != nil {
		log.Printf("SQL Error updating password for id %s: %v", id, err)
		return fmt.Errorf("failed to update password: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for password update: id %s", id)
		return fmt.Errorf("user not found")
	}

	log.Printf("Updated password for user id %s, rows affected: %d", id, cmdTag.RowsAffected())
	return nil
}

// Create creates a new user with email, role, full_name, phone, and password.
func (r *Repository) Create(ctx context.Context, email, role, fullName, phone, password string) (*User, error) {
	if !IsValidRole(role) {
		return nil, fmt.Errorf("invalid role: %s. Must be one of: admin, sales, client, engineer", role)
	}

	var u User
	var fullNamePtr, phonePtr *string
	if fullName != "" {
		fullNamePtr = &fullName
	}
	if phone != "" {
		phonePtr = &phone
	}

	err := config.DB.QueryRow(ctx, `
		INSERT INTO users (email, role, full_name, phone, password_hash)
		VALUES ($1, $2, $3, $4, crypt($5, gen_salt('bf')))
		RETURNING 
			id,
			email,
			role,
			full_name,
			phone,
			created_at,
			updated_at
	`, email, role, fullNamePtr, phonePtr, password).Scan(
		&u.ID,
		&u.Email,
		&u.Role,
		&fullNamePtr,
		&phonePtr,
		&u.CreatedAt,
		&u.UpdatedAt,
	)
	if err != nil {
		log.Printf("SQL Error creating user: %v", err)
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	if fullNamePtr != nil {
		u.FullName = *fullNamePtr
	}
	if phonePtr != nil {
		u.Phone = *phonePtr
	}

	log.Printf("Created user with id %s, email %s, role %s", u.ID, u.Email, u.Role)
	return &u, nil
}

// Update updates email, full_name, and phone for a user by ID.
func (r *Repository) Update(ctx context.Context, id, email, fullName, phone string) error {
	var fullNamePtr, phonePtr *string
	if fullName != "" {
		fullNamePtr = &fullName
	}
	if phone != "" {
		phonePtr = &phone
	}

	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE users
		SET email = $1,
		    full_name = $2,
		    phone = $3,
		    updated_at = NOW()
		WHERE id = $4
	`, email, fullNamePtr, phonePtr, id)
	if err != nil {
		log.Printf("SQL Error updating user for id %s: %v", id, err)
		return fmt.Errorf("failed to update user: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for update: id %s", id)
		return fmt.Errorf("user not found")
	}

	log.Printf("Updated user id %s, rows affected: %d", id, cmdTag.RowsAffected())
	return nil
}

// Delete deletes a user by ID.
func (r *Repository) Delete(ctx context.Context, id string) error {
	cmdTag, err := config.DB.Exec(ctx, `
		DELETE FROM users
		WHERE id = $1
	`, id)
	if err != nil {
		log.Printf("SQL Error deleting user for id %s: %v", id, err)
		return fmt.Errorf("failed to delete user: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("User not found for deletion: id %s", id)
		return fmt.Errorf("user not found")
	}

	log.Printf("Deleted user id %s, rows affected: %d", id, cmdTag.RowsAffected())
	return nil
}
