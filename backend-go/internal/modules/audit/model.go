package audit

import "time"

// AuditLog represents an audit log entry stored in PostgreSQL.
type AuditLog struct {
	ID        string    `json:"id"`
	ActorUID  string    `json:"actor_uid"`
	Action    string    `json:"action"`
	Entity    string    `json:"entity"`
	EntityID  string    `json:"entity_id"`
	CreatedAt time.Time `json:"created_at"`
}

