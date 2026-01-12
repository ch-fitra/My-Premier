package category

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

func (h *AdminHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	categories, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Error fetching categories: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(categories); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) CreateCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input struct {
		Name string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}

	category := Category{
		Name: input.Name,
	}

	id, err := h.repo.Create(r.Context(), category)
	if err != nil {
		log.Printf("Error creating category: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "created", "category", id)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	response := map[string]interface{}{
		"id":   id,
		"name": category.Name,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) UpdateCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract category ID from path /admin/categories/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/categories/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Category ID is required", http.StatusBadRequest)
		return
	}

	var input struct {
		Name string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}

	category := Category{
		Name: input.Name,
	}

	err := h.repo.Update(r.Context(), path, category)
	if err != nil {
		log.Printf("Error updating category: %v", err)
		if strings.Contains(err.Error(), "not found") {
			http.Error(w, "Category not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "updated", "category", path)

	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"id":   path,
		"name": category.Name,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

func (h *AdminHandler) DeleteCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract category ID from path /admin/categories/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/categories/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Category ID is required", http.StatusBadRequest)
		return
	}

	err := h.repo.Delete(r.Context(), path)
	if err != nil {
		log.Printf("Error deleting category: %v", err)
		if strings.Contains(err.Error(), "not found") {
			http.Error(w, "Category not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "deleted", "category", path)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]interface{}{
		"id":      path,
		"message": "Category deleted successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

