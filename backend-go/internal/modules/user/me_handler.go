package user

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/common/authcontext"
)

type MeHandler struct {
	repo *Repository
}

func NewMeHandler() (*MeHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &MeHandler{
		repo: repo,
	}, nil
}

func (h *MeHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context (set by AuthRequired middleware)
	userID := authcontext.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, "User ID not found", http.StatusUnauthorized)
		return
	}

	// Fetch user from database
	userData, err := h.repo.GetByIDForMe(r.Context(), userID)
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		http.Error(w, "User not found", http.StatusUnauthorized)
		return
	}

	// Return profile data
	response := map[string]interface{}{
		"email":      userData.Email,
		"role":       userData.Role,
		"full_name":  userData.FullName,
		"phone":      userData.Phone,
		"created_at": userData.CreatedAt,
		"updated_at": userData.UpdatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *MeHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID := authcontext.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, "User ID not found", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req struct {
		FullName string `json:"full_name"`
		Phone    string `json:"phone"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate that email and role are not being updated
	// (They are read-only, but we don't need to check since we only update full_name and phone)

	// Update profile
	if err := h.repo.UpdateProfile(r.Context(), userID, req.FullName, req.Phone); err != nil {
		log.Printf("Error updating profile: %v", err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
	}

	// Return success
	response := map[string]interface{}{
		"message": "Profile updated successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
	}
}

func (h *MeHandler) UpdatePassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID := authcontext.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, "User ID not found", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req struct {
		OldPassword string `json:"old_password"`
		NewPassword string `json:"new_password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate passwords
	if strings.TrimSpace(req.OldPassword) == "" {
		http.Error(w, "Old password is required", http.StatusBadRequest)
		return
	}
	if strings.TrimSpace(req.NewPassword) == "" {
		http.Error(w, "New password is required", http.StatusBadRequest)
		return
	}

	// Update password
	if err := h.repo.UpdatePasswordByID(r.Context(), userID, req.OldPassword, req.NewPassword); err != nil {
		if strings.Contains(err.Error(), "invalid old password") {
			http.Error(w, "Invalid old password", http.StatusBadRequest)
			return
		}
		log.Printf("Error updating password: %v", err)
		http.Error(w, "Failed to update password", http.StatusInternalServerError)
		return
	}

	// Return success
	response := map[string]interface{}{
		"message": "Password updated successfully",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
	}
}

