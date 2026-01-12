package promo

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"mypremier-backend/internal/common"
)

type AdminHandler struct {
	repo *Repository
}

type ClientHandler struct {
	repo *Repository
}

func NewAdminHandler() (*AdminHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}
	return &AdminHandler{repo: repo}, nil
}

func NewClientHandler() (*ClientHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}
	return &ClientHandler{repo: repo}, nil
}

// ---- Admin Handlers ----

func (h *AdminHandler) GetPromos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	promos, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Error fetching promos: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(promos); err != nil {
		log.Printf("Error encoding promos response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

type PromoInput struct {
	Title       string     `json:"title"`
	Description string     `json:"description"`
	ImageURL    string     `json:"image_url"`
	IsActive    bool       `json:"is_active"`
	StartDate   *time.Time `json:"start_date"`
	EndDate     *time.Time `json:"end_date"`
}

func (h *AdminHandler) CreatePromo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input PromoInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		common.WriteJSONError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if strings.TrimSpace(input.Title) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "title is required")
		return
	}
	if strings.TrimSpace(input.Description) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "description is required")
		return
	}
	if strings.TrimSpace(input.ImageURL) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "image_url is required")
		return
	}

	// Normalize image URL to absolute before storing.
	imageURL := strings.TrimSpace(input.ImageURL)
	if imageURL != "" && !(strings.HasPrefix(imageURL, "http://") || strings.HasPrefix(imageURL, "https://")) {
		scheme := "http"
		if r.TLS != nil {
			scheme = "https"
		}
		host := r.Host
		if !strings.HasPrefix(imageURL, "/") {
			imageURL = "/" + imageURL
		}
		imageURL = scheme + "://" + host + imageURL
	}

	p := &Promo{
		Title:       input.Title,
		Description: input.Description,
		ImageURL:    imageURL,
		IsActive:    input.IsActive,
		StartDate:   input.StartDate,
		EndDate:     input.EndDate,
	}

	created, err := h.repo.Create(r.Context(), p)
	if err != nil {
		log.Printf("Error creating promo: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(created); err != nil {
		log.Printf("Error encoding created promo response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

func (h *AdminHandler) UpdatePromo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/admin/promos/")
	if id == "" || id == r.URL.Path {
		common.WriteJSONError(w, http.StatusBadRequest, "Promo ID is required")
		return
	}

	var input PromoInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		common.WriteJSONError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if strings.TrimSpace(input.Title) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "title is required")
		return
	}
	if strings.TrimSpace(input.Description) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "description is required")
		return
	}
	if strings.TrimSpace(input.ImageURL) == "" {
		common.WriteJSONError(w, http.StatusBadRequest, "image_url is required")
		return
	}

	imageURL := strings.TrimSpace(input.ImageURL)
	if imageURL != "" && !(strings.HasPrefix(imageURL, "http://") || strings.HasPrefix(imageURL, "https://")) {
		scheme := "http"
		if r.TLS != nil {
			scheme = "https"
		}
		host := r.Host
		if !strings.HasPrefix(imageURL, "/") {
			imageURL = "/" + imageURL
		}
		imageURL = scheme + "://" + host + imageURL
	}

	p := &Promo{
		Title:       input.Title,
		Description: input.Description,
		ImageURL:    imageURL,
		IsActive:    input.IsActive,
		StartDate:   input.StartDate,
		EndDate:     input.EndDate,
	}

	updated, err := h.repo.Update(r.Context(), id, p)
	if err != nil {
		log.Printf("Error updating promo: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(updated); err != nil {
		log.Printf("Error encoding updated promo response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

func (h *AdminHandler) DeletePromo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/admin/promos/")
	if id == "" || id == r.URL.Path {
		common.WriteJSONError(w, http.StatusBadRequest, "Promo ID is required")
		return
	}

	if err := h.repo.Delete(r.Context(), id); err != nil {
		log.Printf("Error deleting promo: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ---- Client Handler ----

func (h *ClientHandler) GetClientPromos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	now := time.Now()
	promos, err := h.repo.GetActiveForClient(r.Context(), now)
	if err != nil {
		log.Printf("Error fetching client promos: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	// Normalize image URLs to absolute using request host so mobile clients can load them.
	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	host := r.Host
	baseURL := scheme + "://" + host

	for i := range promos {
		promos[i].ImageURL = normalizeImageURL(promos[i].ImageURL, baseURL)
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(promos); err != nil {
		log.Printf("Error encoding client promos response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// normalizeImageURL ensures the URL is absolute. If it's relative or uses a different host, it rewrites to baseURL.
func normalizeImageURL(url, baseURL string) string {
	url = strings.TrimSpace(url)
	if url == "" {
		return ""
	}

	// If already absolute with http(s), extract path and rebuild with baseURL to ensure correct host.
	if strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://") {
		// Extract path portion (after host)
		idx := strings.Index(url, "/uploads/")
		if idx != -1 {
			return baseURL + url[idx:]
		}
		// If no /uploads/ found, return as is (external URL)
		return url
	}

	// Relative path: prepend baseURL
	if !strings.HasPrefix(url, "/") {
		url = "/" + url
	}
	return baseURL + url
}


