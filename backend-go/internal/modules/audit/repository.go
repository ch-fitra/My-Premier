package audit

import (
	"context"
	"fmt"

	"mypremier-backend/internal/config"
)

// Repository provides data access for audit logs using PostgreSQL.
type Repository struct{}

// NewRepository creates a new Repository using the global PostgreSQL pool.
func NewRepository() (*Repository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &Repository{}, nil
}

// Create inserts a new audit log entry.
func (r *Repository) Create(ctx context.Context, log AuditLog) error {
	err := config.DB.QueryRow(ctx, `
		INSERT INTO audit_logs (actor_uid, action, entity, entity_id)
		VALUES ($1, $2, $3, $4)
		RETURNING id::text, created_at
	`,
		log.ActorUID,
		log.Action,
		log.Entity,
		log.EntityID,
	).Scan(&log.ID, &log.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to create audit log: %w", err)
	}

	return nil
}

// GetAll retrieves all audit logs ordered by creation time descending.
func (r *Repository) GetAll(ctx context.Context) ([]AuditLog, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			actor_uid,
			action,
			entity,
			entity_id,
			created_at
		FROM audit_logs
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch audit logs: %w", err)
	}
	defer rows.Close()

	var logs []AuditLog

	for rows.Next() {
		var log AuditLog
		if err := rows.Scan(
			&log.ID,
			&log.ActorUID,
			&log.Action,
			&log.Entity,
			&log.EntityID,
			&log.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan audit log: %w", err)
		}

		logs = append(logs, log)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating audit logs: %w", err)
	}

	return logs, nil
}

