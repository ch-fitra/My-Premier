package product

import (
	"context"
	"fmt"
	"log"

	"mypremier-backend/internal/config"
)

// Repository provides data access for products using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// GetAll retrieves all products with their images and categories.
// Returns products with all schema fields and images as []string array.
func (r *Repository) GetAll(ctx context.Context) ([]Product, error) {
	// Use LEFT JOIN to aggregate image URLs as array of strings
	rows, err := config.DB.Query(ctx, `
		SELECT
			p.id,
			p.name,
			p.brand,
			p.series,
			p.category_id,
			p.technical_overview,
			p.typical_application,
			p.is_active,
			p.datasheet_url,
			COALESCE(
				array_agg(pi.image_url ORDER BY pi.created_at ASC) FILTER (WHERE pi.image_url IS NOT NULL),
				ARRAY[]::text[]
			) as images
		FROM products p
		LEFT JOIN product_images pi ON p.id = pi.product_id
		GROUP BY p.id, p.name, p.brand, p.series, p.category_id, 
		         p.technical_overview, p.typical_application, 
		         p.is_active, p.datasheet_url, p.created_at
		ORDER BY p.created_at DESC
	`)
	if err != nil {
		log.Printf("SQL Error in GetAll: %v", err)
		return nil, fmt.Errorf("failed to fetch products: %w", err)
	}
	defer rows.Close()

	var products []Product

	for rows.Next() {
		var p Product
		var categoryID *string
		var technicalOverview *string
		var typicalApplication *string
		var datasheetURL *string
		var imagesArray []string

		if err := rows.Scan(
			&p.ID,
			&p.Name,
			&p.Brand,
			&p.Series,
			&categoryID,
			&technicalOverview,
			&typicalApplication,
			&p.IsActive,
			&datasheetURL,
			&imagesArray,
		); err != nil {
			log.Printf("SQL Scan Error in GetAll: %v", err)
			return nil, fmt.Errorf("failed to scan product: %w", err)
		}

		// Handle nullable fields
		if categoryID != nil {
			p.CategoryID = *categoryID
		}
		if technicalOverview != nil {
			p.TechnicalOverview = *technicalOverview
		}
		if typicalApplication != nil {
			p.TypicalApplication = *typicalApplication
		}
		if datasheetURL != nil {
			p.DatasheetURL = *datasheetURL
		}

		// Set images array (already []string from PostgreSQL array_agg)
		if imagesArray == nil {
			p.Images = []string{}
		} else {
			p.Images = imagesArray
		}

		products = append(products, p)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating products: %w", err)
	}

	return products, nil
}

// GetByID retrieves a single product by its ID, including all fields and images.
// Returns product with images as []string array.
func (r *Repository) GetByID(ctx context.Context, id string) (*Product, error) {
	var p Product
	var categoryID *string
	var technicalOverview *string
	var typicalApplication *string
	var datasheetURL *string

	// Step 1: Fetch product with all fields
	err := config.DB.QueryRow(ctx, `
		SELECT
			p.id,
			p.name,
			p.brand,
			p.series,
			p.category_id,
			p.technical_overview,
			p.typical_application,
			p.is_active,
			p.datasheet_url
		FROM products p
		WHERE p.id = $1
	`, id).Scan(
		&p.ID,
		&p.Name,
		&p.Brand,
		&p.Series,
		&categoryID,
		&technicalOverview,
		&typicalApplication,
		&p.IsActive,
		&datasheetURL,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get product: %w", err)
	}

	// Handle nullable fields
	if categoryID != nil {
		p.CategoryID = *categoryID
	}
	if technicalOverview != nil {
		p.TechnicalOverview = *technicalOverview
	}
	if typicalApplication != nil {
		p.TypicalApplication = *typicalApplication
	}
	if datasheetURL != nil {
		p.DatasheetURL = *datasheetURL
	}

	// Step 2: Fetch product images as array of URLs
	imageRows, err := config.DB.Query(ctx, `
		SELECT image_url
		FROM product_images
		WHERE product_id = $1
		ORDER BY created_at ASC
	`, id)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch product images: %w", err)
	}
	defer imageRows.Close()

	var images []string
	for imageRows.Next() {
		var imageURL string
		if err := imageRows.Scan(&imageURL); err != nil {
			return nil, fmt.Errorf("failed to scan image: %w", err)
		}
		images = append(images, imageURL)
	}
	if err := imageRows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating images: %w", err)
	}

	if images == nil {
		p.Images = []string{}
	} else {
		p.Images = images
	}

	return &p, nil
}

// Create inserts a new product with all fields and images in a transaction.
// Returns the generated product ID.
// images is a slice of image URLs to insert into product_images.
func (r *Repository) Create(ctx context.Context, product Product, images []string) (string, error) {
	// Begin transaction
	tx, err := config.DB.Begin(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Step 1: Insert product with all fields
	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO products (
			name,
			brand,
			series,
			category_id,
			technical_overview,
			typical_application,
			is_active,
			datasheet_url
		)
		VALUES ($1, $2, $3, NULLIF($4, '')::uuid, NULLIF($5, ''), NULLIF($6, ''), $7, NULLIF($8, ''))
		RETURNING id::text
	`,
		product.Name,
		product.Brand,
		product.Series,
		product.CategoryID,
		product.TechnicalOverview,
		product.TypicalApplication,
		product.IsActive,
		product.DatasheetURL,
	).Scan(&id)
	if err != nil {
		log.Printf("SQL Error creating product: %v", err)
		return "", fmt.Errorf("failed to create product: %w", err)
	}
	log.Printf("Created product with ID: %s", id)

	// Step 2: Insert all image URLs into product_images
	imagesInserted := 0
	for _, imageURL := range images {
		if imageURL != "" {
			cmdTag, err := tx.Exec(ctx, `
				INSERT INTO product_images (product_id, image_url)
				VALUES ($1, $2)
			`, id, imageURL)
			if err != nil {
				log.Printf("SQL Error inserting image %s: %v", imageURL, err)
				return "", fmt.Errorf("failed to insert image: %w", err)
			}
			if cmdTag.RowsAffected() > 0 {
				imagesInserted++
			}
		}
	}
	log.Printf("Inserted %d images for product %s", imagesInserted, id)

	// Commit transaction
	if err := tx.Commit(ctx); err != nil {
		return "", fmt.Errorf("failed to commit transaction: %w", err)
	}

	return id, nil
}

// Update modifies an existing product with all fields and updates its images in a transaction.
// If the product does not exist, an error containing "not found" is returned.
// images is a slice of image URLs to set for the product (replaces all existing images).
func (r *Repository) Update(ctx context.Context, id string, product Product, images []string) error {
	// Begin transaction
	tx, err := config.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Step 1: Update products table with all fields
	cmdTag, err := tx.Exec(ctx, `
		UPDATE products SET
			name = $1,
			brand = $2,
			series = $3,
			category_id = NULLIF($4, '')::uuid,
			technical_overview = NULLIF($5, ''),
			typical_application = NULLIF($6, ''),
			is_active = $7,
			datasheet_url = NULLIF($8, '')
		WHERE id = $9
	`,
		product.Name,
		product.Brand,
		product.Series,
		product.CategoryID,
		product.TechnicalOverview,
		product.TypicalApplication,
		product.IsActive,
		product.DatasheetURL,
		id,
	)
	if err != nil {
		log.Printf("SQL Error updating product %s: %v", id, err)
		return fmt.Errorf("failed to update product: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		log.Printf("Product not found for update: %s", id)
		return fmt.Errorf("product not found")
	}
	log.Printf("Updated product %s, rows affected: %d", id, cmdTag.RowsAffected())

	// Step 2: Delete all existing images
	deleteCmdTag, err := tx.Exec(ctx, `
		DELETE FROM product_images WHERE product_id = $1
	`, id)
	if err != nil {
		log.Printf("SQL Error deleting images for product %s: %v", id, err)
		return fmt.Errorf("failed to delete existing images: %w", err)
	}
	log.Printf("Deleted %d existing images for product %s", deleteCmdTag.RowsAffected(), id)

	// Step 3: Insert new images
	imagesInserted := 0
	for _, imageURL := range images {
		if imageURL != "" {
			cmdTag, err := tx.Exec(ctx, `
				INSERT INTO product_images (product_id, image_url)
				VALUES ($1, $2)
			`, id, imageURL)
			if err != nil {
				log.Printf("SQL Error inserting image %s for product %s: %v", imageURL, id, err)
				return fmt.Errorf("failed to insert image: %w", err)
			}
			if cmdTag.RowsAffected() > 0 {
				imagesInserted++
			}
		}
	}
	log.Printf("Inserted %d new images for product %s", imagesInserted, id)

	// Commit transaction
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// Delete removes a product by ID (cascade will delete images).
// If the product does not exist, an error containing "not found" is returned.
func (r *Repository) Delete(ctx context.Context, id string) error {
	cmdTag, err := config.DB.Exec(ctx, `
		DELETE FROM products
		WHERE id = $1
	`, id)
	if err != nil {
		return fmt.Errorf("failed to delete product: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("product not found")
	}

	return nil
}
