package category

import (
	"context"
	"fmt"

	"mypremier-backend/internal/config"
)

// Repository provides data access for categories using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// GetAll retrieves all categories.
func (r *Repository) GetAll(ctx context.Context) ([]Category, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			name,
			created_at
		FROM categories
		ORDER BY created_at ASC,
		         name ASC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch categories: %w", err)
	}
	defer rows.Close()

	var categories []Category

	for rows.Next() {
		var c Category

		if err := rows.Scan(&c.ID, &c.Name, &c.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan category: %w", err)
		}

		categories = append(categories, c)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating categories: %w", err)
	}

	return categories, nil
}

// GetByID retrieves a single category by its ID.
func (r *Repository) GetByID(ctx context.Context, id string) (*Category, error) {
	var c Category

	err := config.DB.QueryRow(ctx, `
		SELECT 
			id::text,
			name,
			created_at
		FROM categories
		WHERE id = $1
	`, id).Scan(&c.ID, &c.Name, &c.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to get category: %w", err)
	}

	return &c, nil
}

// Create inserts a new category and returns its generated ID.
func (r *Repository) Create(ctx context.Context, category Category) (string, error) {
	var id string

	err := config.DB.QueryRow(ctx, `
		INSERT INTO categories (name)
		VALUES ($1)
		RETURNING id::text
	`, category.Name).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to create category: %w", err)
	}

	return id, nil
}

// Update modifies an existing category.
// If the category does not exist, an error containing "not found" is returned.
func (r *Repository) Update(ctx context.Context, id string, category Category) error {
	cmdTag, err := config.DB.Exec(ctx, `
		UPDATE categories
		SET 
			name = $1
		WHERE id = $2
	`, category.Name, id)
	if err != nil {
		return fmt.Errorf("failed to update category: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("category not found")
	}

	return nil
}

// Delete removes a category by ID.
// If the category does not exist, an error containing "not found" is returned.
func (r *Repository) Delete(ctx context.Context, id string) error {
	cmdTag, err := config.DB.Exec(ctx, `
		DELETE FROM categories
		WHERE id = $1
	`, id)
	if err != nil {
		return fmt.Errorf("failed to delete category: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("category not found")
	}

	return nil
}


