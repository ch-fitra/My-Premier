package stats

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

type SummaryResponse struct {
	TotalProducts   int `json:"total_products"`
	TotalCategories int `json:"total_categories"`
	TotalRequests   int `json:"total_requests"`
	TotalSupports   int `json:"total_supports"`
}

type ClientSummaryResponse struct {
	TotalRequests int `json:"total_requests"`
	OpenRequests  int `json:"open_requests"`
	TotalSupports int `json:"total_supports"`
	OpenSupports  int `json:"open_supports"`
}

func (h *Handler) GetSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()

	totalProducts, err := h.repo.CountProducts(ctx)
	if err != nil {
		log.Printf("Error counting products: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	totalCategories, err := h.repo.CountCategories(ctx)
	if err != nil {
		log.Printf("Error counting categories: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	totalRequests, err := h.repo.CountRequests(ctx)
	if err != nil {
		log.Printf("Error counting requests: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	totalSupports, err := h.repo.CountSupports(ctx)
	if err != nil {
		log.Printf("Error counting supports: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	response := SummaryResponse{
		TotalProducts:   totalProducts,
		TotalCategories: totalCategories,
		TotalRequests:   totalRequests,
		TotalSupports:    totalSupports,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

// GetClientSummary handles GET /client/dashboard/summary
// It uses the authenticated client's email for scoping.
func (h *Handler) GetClientSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()

	summary, err := h.repo.GetClientSummary(ctx)
	if err != nil {
		log.Printf("Error fetching client dashboard summary: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	resp := ClientSummaryResponse(summary)

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("Error encoding client summary response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

