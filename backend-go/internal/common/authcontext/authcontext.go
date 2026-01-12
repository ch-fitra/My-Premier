package authcontext

import "context"

// contextKey is a private type to avoid key collisions in context.
type contextKey string

const (
	// userIDKey is the context key used to store the authenticated user's ID.
	userIDKey contextKey = "userID"
	// userUIDKey is the context key used to store the authenticated user's UID (legacy, kept for backward compatibility).
	userUIDKey contextKey = "userUID"
	// userRoleKey is the context key used to store the authenticated user's role.
	userRoleKey contextKey = "userRole"
	// userEmailKey is the context key used to store the authenticated user's email.
	userEmailKey contextKey = "userEmail"
)

// WithUserID returns a new context with the given user ID stored.
func WithUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}

// GetUserID retrieves the user ID from the context.
// It returns an empty string if no ID is present.
func GetUserID(ctx context.Context) string {
	userID, _ := ctx.Value(userIDKey).(string)
	return userID
}

// WithUserUID returns a new context with the given user UID stored (legacy, kept for backward compatibility).
func WithUserUID(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, userUIDKey, uid)
}

// GetUserUID retrieves the user UID from the context (legacy, kept for backward compatibility).
// It returns an empty string if no UID is present.
func GetUserUID(ctx context.Context) string {
	uid, _ := ctx.Value(userUIDKey).(string)
	return uid
}

// WithUserRole returns a new context with the given user role stored.
func WithUserRole(ctx context.Context, role string) context.Context {
	return context.WithValue(ctx, userRoleKey, role)
}

// GetUserRole retrieves the user role from the context.
// It returns an empty string if no role is present.
func GetUserRole(ctx context.Context) string {
	role, _ := ctx.Value(userRoleKey).(string)
	return role
}

// WithUserEmail returns a new context with the given user email stored.
func WithUserEmail(ctx context.Context, email string) context.Context {
	return context.WithValue(ctx, userEmailKey, email)
}

// GetUserEmail retrieves the user email from the context.
// It returns an empty string if no email is present.
func GetUserEmail(ctx context.Context) string {
	email, _ := ctx.Value(userEmailKey).(string)
	return email
}


