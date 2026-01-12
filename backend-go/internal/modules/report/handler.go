package report

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"mypremier-backend/internal/common"
	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/modules/user"
)

// Handler handles engineer report endpoints.
type Handler struct {
	repo *Repository
}

// NewHandler creates a new Handler with required repositories.
func NewHandler() (*Handler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &Handler{
		repo: repo,
	}, nil
}

// CreateReport handles POST /engineer/reports
// It requires an authenticated engineer user and extracts email from JWT token.
func (h *Handler) CreateReport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var input CreateReportInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		log.Printf("Error decoding report body: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if input.Title == "" {
		http.Error(w, "title is required", http.StatusBadRequest)
		return
	}

	if input.Description == "" {
		http.Error(w, "description is required", http.StatusBadRequest)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's engineer (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleEngineer {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Parse date string (YYYY-MM-DD) to time.Time at start of day in local timezone
	var reportDate *time.Time
	if input.Date != nil && *input.Date != "" {
		parsedDate, err := time.Parse("2006-01-02", *input.Date)
		if err != nil {
			http.Error(w, "Invalid date format. Expected YYYY-MM-DD", http.StatusBadRequest)
			return
		}
		// Set to start of day in local timezone (or UTC if server uses UTC)
		// Use time.Date to create a date at 00:00:00 in the local timezone
		dateAtStartOfDay := time.Date(parsedDate.Year(), parsedDate.Month(), parsedDate.Day(), 0, 0, 0, 0, time.UTC)
		reportDate = &dateAtStartOfDay
	}

	report, err := h.repo.CreateReport(r.Context(), userEmail, input.Title, input.Description, input.Notes, reportDate)
	if err != nil {
		log.Printf("Error creating engineer report: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(report); err != nil {
		log.Printf("Error encoding report response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// GetReports handles GET /engineer/reports
// It requires an authenticated engineer user and returns only reports for that user's email.
func (h *Handler) GetReports(w http.ResponseWriter, r *http.Request) {
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

	// Role check is handled by middleware, but we verify it's engineer (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleEngineer {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	reports, err := h.repo.GetReportsByEmail(r.Context(), userEmail)
	if err != nil {
		log.Printf("Error fetching engineer reports: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(reports); err != nil {
		log.Printf("Error encoding reports response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// GetReportByID handles GET /engineer/reports/{id}
// It requires an authenticated engineer user and returns the report if it belongs to that user.
func (h *Handler) GetReportByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract report ID from path /engineer/reports/{id}
	path := strings.TrimPrefix(r.URL.Path, "/engineer/reports/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Report ID is required", http.StatusBadRequest)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's engineer (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleEngineer {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	report, err := h.repo.GetReportByID(r.Context(), path)
	if err != nil {
		log.Printf("Error fetching engineer report: %v", err)
		http.Error(w, "Report not found", http.StatusNotFound)
		return
	}

	// Verify the report belongs to the requesting user
	if report.UserEmail != userEmail {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(report); err != nil {
		log.Printf("Error encoding report response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// DeleteReport handles DELETE /engineer/reports/{id}
// It requires an authenticated engineer user and deletes the report if it belongs to that user.
func (h *Handler) DeleteReport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract report ID from path /engineer/reports/{id}
	path := strings.TrimPrefix(r.URL.Path, "/engineer/reports/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Report ID is required", http.StatusBadRequest)
		return
	}

	// Extract email from JWT token (set by AuthRequired middleware)
	userEmail := authcontext.GetUserEmail(r.Context())
	if userEmail == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Role check is handled by middleware, but we verify it's engineer (defensive)
	role := authcontext.GetUserRole(r.Context())
	if role != user.RoleEngineer {
		http.Error(w, "Insufficient permissions", http.StatusForbidden)
		return
	}

	// Log report id and user_email before deletion
	log.Printf("Deleting engineer report: id=%s, user_email=%s", path, userEmail)

	rowsAffected, err := h.repo.DeleteReport(r.Context(), path, userEmail)
	if err != nil {
		log.Printf("Error deleting engineer report: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Log rows affected
	log.Printf("Engineer report deletion result: id=%s, user_email=%s, rows_affected=%d", path, userEmail, rowsAffected)

	// If no rows affected, return 404
	if rowsAffected == 0 {
		http.Error(w, "Report not found", http.StatusNotFound)
		return
	}

	// Success - return 204 No Content
	w.WriteHeader(http.StatusNoContent)
}

