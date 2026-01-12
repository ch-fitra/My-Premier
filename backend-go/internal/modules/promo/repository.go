package promo

import (
	"context"
	"time"

	"mypremier-backend/internal/config"
)

type Repository struct{}

func NewRepository() (*Repository, error) {
	return &Repository{}, nil
}

func (r *Repository) GetAll(ctx context.Context) ([]Promo, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT id, title, description, image_url, is_active, start_date, end_date, created_at
		FROM promos
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	promos := make([]Promo, 0)
	for rows.Next() {
		var p Promo
		var startDate, endDate *time.Time
		if err := rows.Scan(&p.ID, &p.Title, &p.Description, &p.ImageURL, &p.IsActive, &startDate, &endDate, &p.CreatedAt); err != nil {
			return nil, err
		}
		p.StartDate = startDate
		p.EndDate = endDate
		promos = append(promos, p)
	}
	return promos, nil
}

func (r *Repository) GetActiveForClient(ctx context.Context, now time.Time) ([]Promo, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT id, title, description, image_url, is_active, start_date, end_date, created_at
		FROM promos
		WHERE is_active = TRUE
		  AND (start_date IS NULL OR start_date <= $1::date)
		  AND (end_date IS NULL OR end_date >= $1::date)
		ORDER BY created_at DESC
	`, now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	promos := make([]Promo, 0)
	for rows.Next() {
		var p Promo
		var startDate, endDate *time.Time
		if err := rows.Scan(&p.ID, &p.Title, &p.Description, &p.ImageURL, &p.IsActive, &startDate, &endDate, &p.CreatedAt); err != nil {
			return nil, err
		}
		p.StartDate = startDate
		p.EndDate = endDate
		promos = append(promos, p)
	}
	return promos, nil
}

func (r *Repository) Create(ctx context.Context, p *Promo) (*Promo, error) {
	now := time.Now()
	p.CreatedAt = now

	err := config.DB.QueryRow(ctx, `
		INSERT INTO promos (title, description, image_url, is_active, start_date, end_date)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at
	`, p.Title, p.Description, p.ImageURL, p.IsActive, p.StartDate, p.EndDate).
		Scan(&p.ID, &p.CreatedAt)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *Repository) Update(ctx context.Context, id string, p *Promo) (*Promo, error) {
	err := config.DB.QueryRow(ctx, `
		UPDATE promos
		SET title = $1,
		    description = $2,
		    image_url = $3,
		    is_active = $4,
		    start_date = $5,
		    end_date = $6
		WHERE id = $7
		RETURNING id, created_at
	`, p.Title, p.Description, p.ImageURL, p.IsActive, p.StartDate, p.EndDate, id).
		Scan(&p.ID, &p.CreatedAt)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	_, err := config.DB.Exec(ctx, `DELETE FROM promos WHERE id = $1`, id)
	return err
}


