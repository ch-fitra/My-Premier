package report

import (
	"context"
	"fmt"
	"time"

	"mypremier-backend/internal/config"
)

// Repository provides data access for engineer reports using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// CreateReport inserts a new engineer report and returns the full created record.
// If reportDate is nil, uses CURRENT_TIMESTAMP. Otherwise uses the provided date.
func (r *Repository) CreateReport(ctx context.Context, userEmail, title, description string, notes *string, reportDate *time.Time) (*EngineerReport, error) {
	var report EngineerReport

	// If reportDate is provided, use it; otherwise let the database use DEFAULT CURRENT_TIMESTAMP
	var err error
	if reportDate != nil {
		err = config.DB.QueryRow(ctx, `
			INSERT INTO engineer_reports (user_email, title, description, notes, status, created_at)
			VALUES ($1, $2, $3, $4, 'submitted', $5)
			RETURNING 
				id::text,
				user_email,
				title,
				description,
				notes,
				status,
				created_at
		`, userEmail, title, description, notes, *reportDate).Scan(
			&report.ID,
			&report.UserEmail,
			&report.Title,
			&report.Description,
			&report.Notes,
			&report.Status,
			&report.CreatedAt,
		)
	} else {
		err = config.DB.QueryRow(ctx, `
			INSERT INTO engineer_reports (user_email, title, description, notes, status)
			VALUES ($1, $2, $3, $4, 'submitted')
			RETURNING 
				id::text,
				user_email,
				title,
				description,
				notes,
				status,
				created_at
		`, userEmail, title, description, notes).Scan(
			&report.ID,
			&report.UserEmail,
			&report.Title,
			&report.Description,
			&report.Notes,
			&report.Status,
			&report.CreatedAt,
		)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to create engineer report: %w", err)
	}

	return &report, nil
}

// GetReportsByEmail retrieves all reports for a specific engineer email.
func (r *Repository) GetReportsByEmail(ctx context.Context, userEmail string) ([]EngineerReport, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			title,
			description,
			notes,
			status,
			created_at
		FROM engineer_reports
		WHERE user_email = $1
		ORDER BY created_at DESC
	`, userEmail)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch engineer reports: %w", err)
	}
	defer rows.Close()

	var reports []EngineerReport
	for rows.Next() {
		var report EngineerReport
		err := rows.Scan(
			&report.ID,
			&report.UserEmail,
			&report.Title,
			&report.Description,
			&report.Notes,
			&report.Status,
			&report.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan engineer report: %w", err)
		}
		reports = append(reports, report)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating engineer reports: %w", err)
	}

	return reports, nil
}

// GetReportByID retrieves a single report by ID.
func (r *Repository) GetReportByID(ctx context.Context, id string) (*EngineerReport, error) {
	var report EngineerReport
	err := config.DB.QueryRow(ctx, `
		SELECT 
			id::text,
			user_email,
			title,
			description,
			notes,
			status,
			created_at
		FROM engineer_reports
		WHERE id::text = $1
	`, id).Scan(
		&report.ID,
		&report.UserEmail,
		&report.Title,
		&report.Description,
		&report.Notes,
		&report.Status,
		&report.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch engineer report: %w", err)
	}

	return &report, nil
}

// DeleteReport deletes an engineer report by ID and user_email.
// Returns the number of rows affected.
func (r *Repository) DeleteReport(ctx context.Context, id, userEmail string) (int64, error) {
	cmdTag, err := config.DB.Exec(ctx, `
		DELETE FROM engineer_reports
		WHERE id = $1 AND user_email = $2
	`, id, userEmail)
	if err != nil {
		return 0, fmt.Errorf("failed to delete engineer report: %w", err)
	}

	return cmdTag.RowsAffected(), nil
}

// GetAllReports retrieves all engineer reports for admin usage.
// NOTE: Prefer GetReportsByPeriod for dashboard views that need a specific month.
func (r *Repository) GetAllReports(ctx context.Context) ([]EngineerReport, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			title,
			description,
			notes,
			status,
			created_at
		FROM engineer_reports
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch all engineer reports: %w", err)
	}
	defer rows.Close()

	var reports []EngineerReport
	for rows.Next() {
		var report EngineerReport
		err := rows.Scan(
			&report.ID,
			&report.UserEmail,
			&report.Title,
			&report.Description,
			&report.Notes,
			&report.Status,
			&report.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan engineer report: %w", err)
		}
		reports = append(reports, report)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating engineer reports: %w", err)
	}

	return reports, nil
}

// GetReportsByPeriod retrieves engineer reports within a specific time window [start, end).
// Used by admin dashboard to show data per month starting from day 1.
func (r *Repository) GetReportsByPeriod(ctx context.Context, start, end time.Time) ([]EngineerReport, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			user_email,
			title,
			description,
			notes,
			status,
			created_at
		FROM engineer_reports
		WHERE created_at >= $1 AND created_at < $2
		ORDER BY created_at ASC
	`, start, end)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch engineer reports by period: %w", err)
	}
	defer rows.Close()

	var reports []EngineerReport
	for rows.Next() {
		var report EngineerReport
		err := rows.Scan(
			&report.ID,
			&report.UserEmail,
			&report.Title,
			&report.Description,
			&report.Notes,
			&report.Status,
			&report.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan engineer report by period: %w", err)
		}
		reports = append(reports, report)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating engineer reports by period: %w", err)
	}

	return reports, nil
}
