package request

import (
	"encoding/json"
	"log"
	"net/http"
)

type Handler struct {
	repo *Repository
}

func NewHandler() (*Handler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &Handler{
		repo: repo,
	}, nil
}

func (h *Handler) CreateRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input CreateRequestInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.UserEmail == "" {
		http.Error(w, "user_email is required", http.StatusBadRequest)
		return
	}

	if input.ProductName == "" {
		http.Error(w, "product_name is required", http.StatusBadRequest)
		return
	}

	id, err := h.repo.Create(r.Context(), input.UserEmail, input.ProductName, input.Message)
	if err != nil {
		log.Printf("Error creating request: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	response := CreateRequestResponse{
		ID: id,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

