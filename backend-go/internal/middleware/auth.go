package middleware

import (
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/common/jwt"
)

// AuthRequired validates JWT tokens and injects user info into context
func AuthRequired(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract token from Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		// Check Bearer token format
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		tokenString := parts[1]

		// Validate token
		claims, err := jwt.ValidateToken(tokenString)
		if err != nil {
			log.Printf("Token validation error: %v", err)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		// Log token claims (for debugging)
		log.Printf("Token validated - UserID: %s, Email: %s, Role: %s", claims.UserID, claims.Email, claims.Role)

		// Inject user info into context
		ctx := r.Context()
		ctx = authcontext.WithUserID(ctx, claims.UserID)
		ctx = authcontext.WithUserEmail(ctx, claims.Email)
		ctx = authcontext.WithUserRole(ctx, claims.Role)

		// Pass request with updated context
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

