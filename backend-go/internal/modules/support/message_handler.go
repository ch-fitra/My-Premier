package support

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"mypremier-backend/internal/common/authcontext"
)

type MessageHandler struct {
	repo *MessageRepository
}

func NewMessageHandler() (*MessageHandler, error) {
	repo, err := NewMessageRepository()
	if err != nil {
		return nil, err
	}

	return &MessageHandler{
		repo: repo,
	}, nil
}

func (h *MessageHandler) GetMessages(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /supports/{id}/messages
	path := strings.TrimPrefix(r.URL.Path, "/supports/")
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

	messages, err := h.repo.GetBySupportID(r.Context(), supportID)
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
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *MessageHandler) CreateMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract support ID from path /supports/{id}/messages
	path := strings.TrimPrefix(r.URL.Path, "/supports/")
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
		http.Error(w, "Message is required", http.StatusBadRequest)
		return
	}

	// Verify user is authenticated (ID is already validated by AuthRequired middleware)
	_ = authcontext.GetUserID(r.Context())

	// Validate and set sender type
	// Default to "client" if not provided
	senderType := input.SenderType
	if senderType == "" {
		senderType = "client"
	}

	// Validate sender type - allowed values: "client", "sales", "admin"
	if senderType != "client" && senderType != "sales" && senderType != "admin" {
		http.Error(w, "Invalid sender_type. Must be 'client', 'sales', or 'admin'", http.StatusBadRequest)
		return
	}

	id, err := h.repo.Create(r.Context(), supportID, senderType, input.Message)
	if err != nil {
		log.Printf("Error creating support message: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Fetch the created message to return full details with timestamp
	// For now, we'll return a simplified response and let the client refetch if needed
	response := CreateMessageResponse{
		ID:         id,
		SupportID:  supportID,
		SenderType: senderType,
		Message:    input.Message,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

