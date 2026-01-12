package request

import (
	"encoding/json"
	"log"
	"net/http"

	"mypremier-backend/internal/common"
	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/modules/user"
)

// SalesHandler handles sales-specific request creation from the mobile app.
type SalesHandler struct {
	requestRepo *Repository
}

// NewSalesHandler creates a new SalesHandler with required repositories.
func NewSalesHandler() (*SalesHandler, error) {
	reqRepo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &SalesHandler{
		requestRepo: reqRepo,
	}, nil
}

// CreateSalesRequest handles POST /sales/requests
// It requires an authenticated sales user and extracts email from JWT token.
func (h *SalesHandler) CreateSalesRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input SalesCreateRequestInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding sales request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.ProductName == "" {
		http.Error(w, "product_name is required", http.StatusBadRequest)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's sales (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleSales {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	req, err := h.requestRepo.CreateSalesRequest(r.Context(), userEmail, input.ProductName, input.Message)
	if err != nil {
		log.Printf("Error creating sales request: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(req); err != nil {
		log.Printf("Error encoding sales request response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// GetSalesRequests handles GET /sales/requests
// It requires an authenticated sales user and returns only requests for that user's email.
func (h *SalesHandler) GetSalesRequests(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's sales (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleSales {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	requests, err := h.requestRepo.GetSalesRequestsByEmail(r.Context(), userEmail)
	if err != nil {
		log.Printf("Error fetching sales requests: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(requests); err != nil {
		log.Printf("Error encoding sales requests response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}


