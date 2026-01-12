package support

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/modules/audit"
)

type AdminHandler struct {
	repo        *Repository
	auditHandler *audit.Handler
}

func NewAdminHandler() (*AdminHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	auditHandler, err := audit.NewHandler()
	if err != nil {
		return nil, err
	}

	return &AdminHandler{
		repo:        repo,
		auditHandler: auditHandler,
	}, nil
}

func (h *AdminHandler) GetSupports(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	supports, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Error fetching supports: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(supports); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) UpdateSupportStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch && r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /admin/support/{id}
	path := r.URL.Path
	supportID := strings.TrimPrefix(path, "/admin/support/")
	if supportID == "" || supportID == path {
		http.Error(w, "Support ID is required", http.StatusBadRequest)
		return
	}

	var input struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Status == "" {
		http.Error(w, "status is required", http.StatusBadRequest)
		return
	}

	err := h.repo.UpdateStatus(r.Context(), supportID, input.Status)
	if err != nil {
		log.Printf("Error updating support status: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Support status updated successfully"})
}

