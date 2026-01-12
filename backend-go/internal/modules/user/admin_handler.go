package user

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
)

type AdminHandler struct {
	repo *Repository
}

func NewAdminHandler() (*AdminHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &AdminHandler{
		repo: repo,
	}, nil
}

func (h *AdminHandler) GetUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	users, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Error fetching users: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(users); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) UpdateUserRole(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract ID from path /admin/users/{id}/role
	path := strings.TrimPrefix(r.URL.Path, "/admin/users/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	// Remove /role suffix if present
	id := strings.TrimSuffix(path, "/role")
	if id == "" {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	var input struct {
		Role string `json:"role"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Role == "" {
		http.Error(w, "Role is required", http.StatusBadRequest)
		return
	}

	if !IsValidRole(input.Role) {
		http.Error(w, "Invalid role. Must be one of: admin, sales, client", http.StatusBadRequest)
		return
	}

	err := h.repo.UpdateRole(r.Context(), id, input.Role)
	if err != nil {
		log.Printf("Error updating user role: %v", err)
		if strings.Contains(err.Error(), "not found") {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		if strings.Contains(err.Error(), "invalid role") {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]interface{}{
		"id":   id,
		"role": input.Role,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) UpdateUserStatus(w http.ResponseWriter, r *http.Request) {
	// This endpoint is disabled - users table does not have is_active column
	http.Error(w, "User status update is not supported - is_active column does not exist", http.StatusBadRequest)
	return
}

// CreateUser handles POST /admin/users
func (h *AdminHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input struct {
		Email    string `json:"email"`
		Role     string `json:"role"`
		FullName string `json:"full_name,omitempty"`
		Phone    string `json:"phone,omitempty"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Email == "" {
		http.Error(w, "Email is required", http.StatusBadRequest)
		return
	}

	if input.Password == "" {
		http.Error(w, "Password is required", http.StatusBadRequest)
		return
	}

	if input.Role == "" {
		input.Role = RoleClient // Default role
	}

	if !IsValidRole(input.Role) {
		http.Error(w, "Invalid role. Must be one of: admin, sales, client, engineer", http.StatusBadRequest)
		return
	}

	user, err := h.repo.Create(r.Context(), input.Email, input.Role, input.FullName, input.Phone, input.Password)
	if err != nil {
		log.Printf("Error creating user: %v", err)
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "Email already exists", http.StatusConflict)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(user); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// UpdateUser handles PUT /admin/users/{id}
func (h *AdminHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract ID from path /admin/users/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/users/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	var input struct {
		Email    string `json:"email"`
		FullName string `json:"full_name,omitempty"`
		Phone    string `json:"phone,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Email == "" {
		http.Error(w, "Email is required", http.StatusBadRequest)
		return
	}

	err := h.repo.Update(r.Context(), path, input.Email, input.FullName, input.Phone)
	if err != nil {
		log.Printf("Error updating user: %v", err)
		if strings.Contains(err.Error(), "not found") {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Return updated user
	user, err := h.repo.GetByID(r.Context(), path)
	if err != nil {
		log.Printf("Error fetching updated user: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(user); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// DeleteUser handles DELETE /admin/users/{id}
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract ID from path /admin/users/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/users/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	err := h.repo.Delete(r.Context(), path)
	if err != nil {
		log.Printf("Error deleting user: %v", err)
		if strings.Contains(err.Error(), "not found") {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
