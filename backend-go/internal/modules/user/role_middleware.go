package user

import (
	"log"
	"net/http"

	"mypremier-backend/internal/common/authcontext"
)

// LoadUserRole middleware loads the user role from database and injects it into context.
// This should be used after AuthRequired middleware.
// Note: Role is already set by AuthRequired middleware from JWT token, but this can be used
// to refresh role from database if needed.
func LoadUserRole(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Get user ID from context (set by AuthRequired middleware)
		userID := authcontext.GetUserID(r.Context())
		if userID == "" {
			http.Error(w, "User ID not found in context", http.StatusInternalServerError)
			return
		}

		// Get user repository
		repo, err := NewRepository()
		if err != nil {
			log.Printf("Error creating user repository: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		// Fetch user from database
		userData, err := repo.GetByID(r.Context(), userID)
		if err != nil {
			log.Printf("Error fetching user: %v", err)
			http.Error(w, "User not found or error fetching user", http.StatusNotFound)
			return
		}

		// Inject role into context (refresh from database)
		ctx := authcontext.WithUserRole(r.Context(), userData.Role)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireRole checks if the user has the required role.
// This should be used after LoadUserRole middleware.
func RequireRole(requiredRole string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role := authcontext.GetUserRole(r.Context())
			if role == "" {
				http.Error(w, "User role not found in context", http.StatusInternalServerError)
				return
			}

			if role != requiredRole {
				http.Error(w, "Insufficient permissions", http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}


