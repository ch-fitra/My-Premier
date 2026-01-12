package request

import (
	"encoding/json"
	"log"
	"net/http"

	"mypremier-backend/internal/common"
	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/modules/user"
)

// ClientHandler handles client-specific request creation from the mobile app.
type ClientHandler struct {
	requestRepo *Repository
}

// NewClientHandler creates a new ClientHandler with required repositories.
func NewClientHandler() (*ClientHandler, error) {
	reqRepo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &ClientHandler{
		requestRepo: reqRepo,
	}, nil
}

// CreateClientRequest handles POST /client/requests
// It requires an authenticated client user and extracts email from JWT token.
func (h *ClientHandler) CreateClientRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input SalesCreateRequestInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding client request body: %v", err)
		common.WriteJSONError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if input.ProductName == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "product_name is required")
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		common.WriteJSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		common.WriteJSONError(w, http.StatusForbidden, "Insufficient permissions")
		return
	}

	req, err := h.requestRepo.CreateSalesRequest(r.Context(), userEmail, input.ProductName, input.Message)
	if err != nil {
		log.Printf("Error creating client request: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(req); err != nil {
		log.Printf("Error encoding client request response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// GetClientRequests handles GET /client/requests
// It requires an authenticated client user and returns only requests for that user's email.
func (h *ClientHandler) GetClientRequests(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		common.WriteJSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		common.WriteJSONError(w, http.StatusForbidden, "Insufficient permissions")
		return
	}

	requests, err := h.requestRepo.GetSalesRequestsByEmail(r.Context(), userEmail)
	if err != nil {
		log.Printf("Error fetching client requests: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	// Always return an array (possibly empty)
	if err := json.NewEncoder(w).Encode(requests); err != nil {
		log.Printf("Error encoding client requests response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}


