package support

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/modules/user"
)

// SalesHandler handles sales-specific support operations from the mobile app.
type SalesHandler struct {
	supportRepo *Repository
	messageRepo *MessageRepository
}

// NewSalesHandler creates a new SalesHandler with required repositories.
func NewSalesHandler() (*SalesHandler, error) {
	supportRepo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	messageRepo, err := NewMessageRepository()
	if err != nil {
		return nil, err
	}

	return &SalesHandler{
		supportRepo: supportRepo,
		messageRepo: messageRepo,
	}, nil
}

// CreateSalesSupport handles POST /sales/supports
// It requires an authenticated sales user and extracts email from JWT token.
func (h *SalesHandler) CreateSalesSupport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input SalesCreateSupportInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding sales support body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Subject == "" {
		http.Error(w, "subject is required", http.StatusBadRequest)
		return
	}

	if input.Message == "" {
		http.Error(w, "message is required", http.StatusBadRequest)
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

	// Create support ticket
	support, err := h.supportRepo.CreateSalesSupport(r.Context(), userEmail, input.Subject)
	if err != nil {
		log.Printf("Error creating sales support: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Create first message
	_, err = h.messageRepo.Create(r.Context(), support.ID, "sales", input.Message)
	if err != nil {
		log.Printf("Error creating initial support message: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(support); err != nil {
		log.Printf("Error encoding sales support response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetSalesSupports handles GET /sales/supports
// It requires an authenticated sales user and returns only supports for that user's email.
func (h *SalesHandler) GetSalesSupports(w http.ResponseWriter, r *http.Request) {
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

	supports, err := h.supportRepo.GetSalesSupportsByEmail(r.Context(), userEmail)
	if err != nil {
		log.Printf("Error fetching sales supports: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Ensure we always return an array, never null (defensive check)
	if supports == nil {
		supports = []Support{}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(supports); err != nil {
		log.Printf("Error encoding sales supports response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetSalesSupportDetail handles GET /sales/supports/{id}
// It requires an authenticated sales user and returns support with messages.
func (h *SalesHandler) GetSalesSupportDetail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /sales/supports/{id}
	path := strings.TrimPrefix(r.URL.Path, "/sales/supports/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Support ID is required", http.StatusBadRequest)
		return
	}
	supportID := path

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

	// Get support by ID
	support, err := h.supportRepo.GetByID(r.Context(), supportID)
	if err != nil {
		log.Printf("Error fetching support: %v", err)
		http.Error(w, "Support not found", http.StatusNotFound)
		return
	}

	// Validate that support belongs to the user
	if support.UserEmail != userEmail {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}

	// Get messages for this support
	messages, err := h.messageRepo.GetBySupportID(r.Context(), supportID)
	if err != nil {
		log.Printf("Error fetching support messages: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	response := SupportDetailResponse{
		Support:  *support,
		Messages: messages,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding support detail response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// SendSalesMessage handles POST /sales/supports/{id}/messages
// It requires an authenticated sales user and validates ownership.
func (h *SalesHandler) SendSalesMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /sales/supports/{id}/messages
	path := strings.TrimPrefix(r.URL.Path, "/sales/supports/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Support ID is required", http.StatusBadRequest)
		return
	}

	// Remove "/messages" suffix
	supportID := strings.TrimSuffix(path, "/messages")
	if supportID == "" || supportID == path {
		http.Error(w, "Support ID is required", http.StatusBadRequest)
		return
	}

	var input CreateMessageInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Message == "" {
		http.Error(w, "message is required", http.StatusBadRequest)
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

	// Validate that support belongs to the user
	support, err := h.supportRepo.GetByID(r.Context(), supportID)
	if err != nil {
		log.Printf("Error fetching support: %v", err)
		http.Error(w, "Support not found", http.StatusNotFound)
		return
	}

	if support.UserEmail != userEmail {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}

	// Create message with sender_type = 'sales'
	msg, err := h.messageRepo.CreateAndReturn(r.Context(), supportID, "sales", input.Message)
	if err != nil {
		log.Printf("Error creating support message: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Return full message details
	response := CreateMessageResponse{
		ID:         msg.ID,
		SupportID:  msg.SupportID,
		SenderType: msg.SenderType,
		Message:    msg.Message,
		CreatedAt:  msg.CreatedAt,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

