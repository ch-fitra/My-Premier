package support

import (
	"context"
	"fmt"

	"mypremier-backend/internal/config"
)

// MessageRepository provides data access for support messages using PostgreSQL.
type MessageRepository struct{}

// NewMessageRepository creates a new MessageRepository using the global PostgreSQL pool.
func NewMessageRepository() (*MessageRepository, error) {
	if config.DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}

	return &MessageRepository{}, nil
}

// GetBySupportID retrieves all messages for a specific support request ordered by created_at ascending.
func (r *MessageRepository) GetBySupportID(ctx context.Context, supportID string) ([]SupportMessage, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT 
			id::text,
			support_id::text,
			sender,
			message,
			created_at
		FROM support_messages
		WHERE support_id = $1::uuid
		ORDER BY created_at ASC
	`, supportID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch support messages: %w", err)
	}
	defer rows.Close()

	var messages []SupportMessage

	for rows.Next() {
		var msg SupportMessage

		if err := rows.Scan(&msg.ID, &msg.SupportID, &msg.SenderType, &msg.Message, &msg.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan support message: %w", err)
		}

		messages = append(messages, msg)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating support messages: %w", err)
	}

	// Ensure we always return an array, never nil
	if messages == nil {
		messages = []SupportMessage{}
	}

	return messages, nil
}

// Create inserts a new support message and returns its generated ID.
func (r *MessageRepository) Create(ctx context.Context, supportID string, senderType string, message string) (string, error) {
	var id string
	err := config.DB.QueryRow(ctx, `
		INSERT INTO support_messages (support_id, sender, message)
		VALUES ($1::uuid, $2, $3)
		RETURNING id::text
	`, supportID, senderType, message).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to create support message (SQL error): %w", err)
	}

	return id, nil
}

// CreateAndReturn inserts a new support message and returns the full message.
func (r *MessageRepository) CreateAndReturn(ctx context.Context, supportID string, senderType string, message string) (*SupportMessage, error) {
	var msg SupportMessage
	err := config.DB.QueryRow(ctx, `
		INSERT INTO support_messages (support_id, sender, message)
		VALUES ($1::uuid, $2, $3)
		RETURNING 
			id::text,
			support_id::text,
			sender,
			message,
			created_at
	`, supportID, senderType, message).Scan(
		&msg.ID,
		&msg.SupportID,
		&msg.SenderType,
		&msg.Message,
		&msg.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create support message (SQL error): %w", err)
	}

	return &msg, nil
}