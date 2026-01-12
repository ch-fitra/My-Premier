package auth

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/common/jwt"
	"mypremier-backend/internal/modules/user"
)

type Handler struct {
	userRepo *user.Repository
}

func NewHandler() (*Handler, error) {
	userRepo, err := user.NewRepository()
	if err != nil {
		return nil, err
	}

	return &Handler{
		userRepo: userRepo,
	}, nil
}

// LoginRequest represents the login request body
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// LoginResponse represents the login response
type LoginResponse struct {
	Token string `json:"token"`
}

// Login handles POST /auth/login
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	log.Printf("🔐 LOGIN: Login endpoint hit - Method: %s, Path: %s", r.Method, r.URL.Path)
	
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("❌ LOGIN: Error decoding login request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Email == "" || req.Password == "" {
		log.Printf("❌ LOGIN: Missing email or password")
		http.Error(w, "Email and password are required", http.StatusBadRequest)
		return
	}

	log.Printf("🔍 LOGIN: Attempting login for email: %s", req.Email)

	// Get user by email and password using pgcrypto
	userData, err := h.userRepo.GetByEmailAndPassword(r.Context(), req.Email, req.Password)
	if err != nil {
		log.Printf("❌ LOGIN: Invalid credentials for email %s: %v", req.Email, err)
		http.Error(w, "Invalid email or password", http.StatusUnauthorized)
		return
	}

	log.Printf("✅ LOGIN: User authenticated - ID: %s, Email: %s, Role: %s", userData.ID, userData.Email, userData.Role)

	// Generate JWT token
	log.Printf("🎫 LOGIN: Generating JWT token for user %s (ID: %s, Role: %s)", req.Email, userData.ID, userData.Role)
	token, err := jwt.GenerateToken(userData.ID, userData.Email, userData.Role)
	if err != nil {
		log.Printf("❌ LOGIN: Error generating JWT token: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	log.Printf("✅ LOGIN: JWT token generated successfully for user %s", req.Email)

	// Return token
	response := LoginResponse{
		Token: token,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("❌ LOGIN: Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ LOGIN: Login successful for user %s", req.Email)
}

// RegisterRequest represents the register request body
type RegisterRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	FullName string `json:"full_name,omitempty"`
	Phone    string `json:"phone,omitempty"`
	Role     string `json:"role,omitempty"` // Optional, defaults to "client"
}

// RegisterResponse represents the register response
type RegisterResponse struct {
	Token string `json:"token"`
	User  struct {
		ID       string `json:"id"`
		Email    string `json:"email"`
		Role     string `json:"role"`
		FullName string `json:"full_name,omitempty"`
		Phone    string `json:"phone,omitempty"`
	} `json:"user"`
}

// Register handles POST /auth/register
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	log.Printf("📝 REGISTER: Register endpoint hit - Method: %s, Path: %s", r.Method, r.URL.Path)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("❌ REGISTER: Error decoding register request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Email == "" || req.Password == "" {
		log.Printf("❌ REGISTER: Missing email or password")
		http.Error(w, "Email and password are required", http.StatusBadRequest)
		return
	}

	if len(req.Password) < 6 {
		log.Printf("❌ REGISTER: Password too short")
		http.Error(w, "Password must be at least 6 characters", http.StatusBadRequest)
		return
	}

	// Default role to "client" if not provided
	if req.Role == "" {
		req.Role = "client"
	}

	log.Printf("🔍 REGISTER: Attempting to register email: %s, Role: %s", req.Email, req.Role)

	// Create user using repository Create method
	userData, err := h.userRepo.Create(r.Context(), req.Email, req.Role, req.FullName, req.Phone, req.Password)
	if err != nil {
		log.Printf("❌ REGISTER: Failed to create user %s: %v", req.Email, err)
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") || strings.Contains(err.Error(), "already exists") {
			http.Error(w, "Email already exists", http.StatusConflict)
			return
		}
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ REGISTER: User created - ID: %s, Email: %s, Role: %s", userData.ID, userData.Email, userData.Role)

	// Generate JWT token
	log.Printf("🎫 REGISTER: Generating JWT token for user %s", req.Email)
	token, err := jwt.GenerateToken(userData.ID, userData.Email, userData.Role)
	if err != nil {
		log.Printf("❌ REGISTER: Error generating JWT token: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	log.Printf("✅ REGISTER: JWT token generated successfully for user %s", req.Email)

	// Return token and user info
	response := RegisterResponse{
		Token: token,
	}
	response.User.ID = userData.ID
	response.User.Email = userData.Email
	response.User.Role = userData.Role
	response.User.FullName = userData.FullName
	response.User.Phone = userData.Phone

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("❌ REGISTER: Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ REGISTER: Registration successful for user %s", req.Email)
}

// GoogleAuthRequest represents Google OAuth request
type GoogleAuthRequest struct {
	Email     string `json:"email"`
	FullName  string `json:"full_name,omitempty"`
	PhotoURL  string `json:"photo_url,omitempty"`
	GoogleID  string `json:"google_id,omitempty"`
}

// GoogleAuth handles POST /auth/google
// This endpoint handles both login and registration for Google OAuth users
func (h *Handler) GoogleAuth(w http.ResponseWriter, r *http.Request) {
	log.Printf("🔐 GOOGLE AUTH: Google auth endpoint hit - Method: %s", r.Method)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req GoogleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("❌ GOOGLE AUTH: Error decoding request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Email == "" {
		log.Printf("❌ GOOGLE AUTH: Missing email")
		http.Error(w, "Email is required", http.StatusBadRequest)
		return
	}

	log.Printf("🔍 GOOGLE AUTH: Processing Google auth for email: %s", req.Email)

	// Try to get existing user by email
	userData, err := h.userRepo.GetByEmail(r.Context(), req.Email)
	if err != nil {
		// User doesn't exist, create new user with Google credentials
		log.Printf("📝 GOOGLE AUTH: User not found, creating new user: %s", req.Email)
		
		// Generate a random password (won't be used for Google users, but required for database)
		// In production, you might want to add a flag to indicate Google-authenticated users
		tempPassword := "google_" + req.GoogleID + "_" + req.Email
		userData, err = h.userRepo.Create(r.Context(), req.Email, "client", req.FullName, "", tempPassword)
		if err != nil {
			log.Printf("❌ GOOGLE AUTH: Failed to create user %s: %v", req.Email, err)
			http.Error(w, "Failed to create user", http.StatusInternalServerError)
			return
		}
		log.Printf("✅ GOOGLE AUTH: User created - ID: %s, Email: %s", userData.ID, userData.Email)
	} else {
		log.Printf("✅ GOOGLE AUTH: Existing user found - ID: %s, Email: %s, Role: %s", userData.ID, userData.Email, userData.Role)
	}

	// Generate JWT token
	token, err := jwt.GenerateToken(userData.ID, userData.Email, userData.Role)
	if err != nil {
		log.Printf("❌ GOOGLE AUTH: Error generating JWT token: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Return token and user info
	response := map[string]interface{}{
		"token": token,
		"user": map[string]interface{}{
			"id":        userData.ID,
			"email":     userData.Email,
			"role":      userData.Role,
			"full_name": userData.FullName,
			"phone":     userData.Phone,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("❌ GOOGLE AUTH: Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ GOOGLE AUTH: Google authentication successful for user %s", req.Email)
}

// MeResponse represents the /auth/me response
type MeResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

// Me handles GET /auth/me
func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context (set by JWT middleware)
	userID := authcontext.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get user from database
	userData, err := h.userRepo.GetByID(r.Context(), userID)
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Return user info
	response := MeResponse{
		ID:    userData.ID,
		Email: userData.Email,
		Role:  userData.Role,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

