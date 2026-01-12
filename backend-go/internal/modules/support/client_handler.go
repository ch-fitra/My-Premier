package support

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/modules/user"
)

// ClientHandler handles client-specific support operations from the mobile app.
type ClientHandler struct {
	supportRepo *Repository
	messageRepo *MessageRepository
}

// NewClientHandler creates a new ClientHandler with required repositories.
func NewClientHandler() (*ClientHandler, error) {
	supportRepo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	messageRepo, err := NewMessageRepository()
	if err != nil {
		return nil, err
	}

	return &ClientHandler{
		supportRepo: supportRepo,
		messageRepo: messageRepo,
	}, nil
}

// CreateClientSupport handles POST /client/supports
// It requires an authenticated client user and extracts email from JWT token.
func (h *ClientHandler) CreateClientSupport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input SalesCreateSupportInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding client support body: %v", err)
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

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Create support ticket with default status = 'open'
	support, err := h.supportRepo.CreateSalesSupport(r.Context(), userEmail, input.Subject)
	if err != nil {
		log.Printf("Error creating client support: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Create first message as 'client'
	_, err = h.messageRepo.Create(r.Context(), support.ID, "client", input.Message)
	if err != nil {
		log.Printf("Error creating initial client support message: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(support); err != nil {
		log.Printf("Error encoding client support response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetClientSupports handles GET /client/supports
// It requires an authenticated client user and returns only supports for that user's email.
func (h *ClientHandler) GetClientSupports(w http.ResponseWriter, r *http.Request) {
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

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	supports, err := h.supportRepo.GetClientSupportsByEmail(r.Context(), userEmail)
	if err != nil {
		log.Printf("Error fetching client supports: %v", err)
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
		log.Printf("Error encoding client supports response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetClientSupportByID handles GET /client/supports/{id}
// It requires an authenticated client user and returns support details.
// Returns JSON in exact format:
// {
//   "id": "uuid",
//   "subject": "string",
//   "status": "string",
//   "created_at": "ISO8601 string",
//   "messages": [
//     {
//       "id": "uuid",
//       "sender": "client | sales | admin",
//       "message": "string",
//       "created_at": "ISO8601 string"
//     }
//   ]
// }
func (h *ClientHandler) GetClientSupportByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /client/supports/{id}
	path := strings.TrimPrefix(r.URL.Path, "/client/supports/")
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

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Query supports table by id
	support, err := h.supportRepo.GetByIDAndEmail(r.Context(), supportID, userEmail)
	if err != nil {
		log.Printf("Error fetching support: %v", err)

		// If not found -> 404 JSON {"message":"Support not found"}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"message": "Support not found",
		})
		return
	}

	// Query support_messages by support_id
	messages, err := h.messageRepo.GetBySupportID(r.Context(), supportID)
	if err != nil {
		log.Printf("Error fetching support messages: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Build explicit response struct - SupportDetailResponse
	type SupportMessageResponse struct {
		ID        string    `json:"id"`
		Sender    string    `json:"sender"`
		Message   string    `json:"message"`
		CreatedAt time.Time `json:"created_at"`
	}

	type SupportDetailResponse struct {
		ID        string                 `json:"id"`
		Subject   string                 `json:"subject"`
		Status    string                 `json:"status"`
		CreatedAt time.Time              `json:"created_at"`
		Messages  []SupportMessageResponse `json:"messages"`
	}

	// Map SQL rows manually into this struct
	// ALWAYS return messages as array, never null
	responseMessages := make([]SupportMessageResponse, 0)
	if messages != nil {
		for _, m := range messages {
			responseMessages = append(responseMessages, SupportMessageResponse{
				ID:        m.ID,
				Sender:    m.SenderType, // Map sender_type to sender
				Message:   m.Message,
				CreatedAt: m.CreatedAt,
			})
		}
	}

	// Build response object (NOT array)
	response := SupportDetailResponse{
		ID:        support.ID,
		Subject:   support.Subject,
		Status:    support.Status,
		CreatedAt: support.CreatedAt,
		Messages:  responseMessages, // Always an array, even if empty
	}

	// ALWAYS return: c.JSON(200, responseStruct)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding client support detail response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetClientSupportMessages handles GET /client/supports/{id}/messages
// It requires an authenticated client user and validates ownership.
func (h *ClientHandler) GetClientSupportMessages(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /client/supports/{id}/messages
	path := strings.TrimPrefix(r.URL.Path, "/client/supports/")
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

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Ensure support exists and is owned by this client
	if _, err := h.supportRepo.GetByIDAndEmail(r.Context(), supportID, userEmail); err != nil {
		log.Printf("Error fetching support for messages: %v", err)
		http.Error(w, "Support not found", http.StatusNotFound)
		return
	}

	// Get messages for this support
	messages, err := h.messageRepo.GetBySupportID(r.Context(), supportID)
	if err != nil {
		log.Printf("Error fetching support messages: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Ensure we always return an array, never null
	if messages == nil {
		messages = []SupportMessage{}
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(messages); err != nil {
		log.Printf("Error encoding client support messages response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// CreateClientSupportMessage handles POST /client/supports/{id}/messages
// It requires an authenticated client user and validates ownership.
func (h *ClientHandler) CreateClientSupportMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /client/supports/{id}/messages
	path := strings.TrimPrefix(r.URL.Path, "/client/supports/")
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

	// Role check is handled by middleware, but we verify it's client (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleClient {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Ensure support exists and is owned by this client
	if _, err := h.supportRepo.GetByIDAndEmail(r.Context(), supportID, userEmail); err != nil {
		log.Printf("Error fetching support for message creation: %v", err)
		http.Error(w, "Support not found", http.StatusNotFound)
		return
	}

	// Create message with sender = 'client'
	msg, err := h.messageRepo.CreateAndReturn(r.Context(), supportID, "client", input.Message)
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


