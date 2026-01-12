package report

import (
	"encoding/json"
	"log"
	"net/http"
	"sort"
	"time"
)

// AdminHandler handles admin endpoints for engineer reports.
type AdminHandler struct {
	repo *Repository
}

// NewAdminHandler creates a new AdminHandler.
func NewAdminHandler() (*AdminHandler, error) {
	repo, err := NewRepository()
	if err != nil {
		return nil, err
	}

	return &AdminHandler{
		repo: repo,
	}, nil
}

// EngineerReportStat represents aggregated statistics per engineer.
type EngineerReportStat struct {
	UserEmail      string  `json:"user_email"`
	TotalReports   int     `json:"total_reports"`
	FirstReportAt  string  `json:"first_report_at"`  // ISO date
	LastReportAt   string  `json:"last_report_at"`   // ISO date
	ActiveDays     int     `json:"active_days"`      // days between first & last (inclusive)
	CompletionRate float64 `json:"completion_rate"`  // percentage based on active days
	Rank           int     `json:"rank"`             // 1 = highest total_reports
}

// AdminReportsSummaryResponse is the response structure for admin summary endpoint.
type AdminReportsSummaryResponse struct {
	Reports     []EngineerReport     `json:"reports"`
	Stats       []EngineerReportStat `json:"stats"`
	PeriodStart string               `json:"period_start"` // ISO date (start of month)
	PeriodEnd   string               `json:"period_end"`   // ISO date (exclusive end)
}

// GetReportsSummary handles:
//   GET /admin/engineer-reports/summary?month=YYYY-MM
//
// Query parameters:
//   - month: Optional. Format YYYY-MM (e.g., "2024-01" for January 2024). Defaults to current month.
//
// It returns all engineer reports plus aggregated statistics per engineer
// (total reports, active days, completion rate approximation, and rank).
func (h *AdminHandler) GetReportsSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse month parameter from query string (format: YYYY-MM)
	var monthStart, nextMonthStart time.Time
	monthParam := r.URL.Query().Get("month")
	
	if monthParam != "" {
		// Parse YYYY-MM format
		parsedTime, err := time.Parse("2006-01", monthParam)
		if err != nil {
			log.Printf("Invalid month parameter format: %v, using current month", err)
			// Fallback to current month
			now := time.Now()
			monthStart = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
			nextMonthStart = monthStart.AddDate(0, 1, 0)
		} else {
			// Use parsed month
			monthStart = time.Date(parsedTime.Year(), parsedTime.Month(), 1, 0, 0, 0, 0, parsedTime.Location())
			nextMonthStart = monthStart.AddDate(0, 1, 0)
		}
	} else {
		// Default to current month
		now := time.Now()
		monthStart = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		nextMonthStart = monthStart.AddDate(0, 1, 0)
	}

	reports, err := h.repo.GetReportsByPeriod(r.Context(), monthStart, nextMonthStart)
	if err != nil {
		log.Printf("Error fetching all engineer reports for admin: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Build per-engineer aggregates
	type agg struct {
		Count        int
		First        time.Time
		Last         time.Time
		UniqueDays   map[string]bool // Track unique days with reports (format: YYYY-MM-DD)
	}

	aggregates := make(map[string]*agg)

	for _, rep := range reports {
		a, ok := aggregates[rep.UserEmail]
		// Format date as YYYY-MM-DD for unique day tracking
		reportDay := rep.CreatedAt.Format("2006-01-02")
		
		if !ok {
			uniqueDays := make(map[string]bool)
			uniqueDays[reportDay] = true
			aggregates[rep.UserEmail] = &agg{
				Count:      1,
				First:      rep.CreatedAt,
				Last:       rep.CreatedAt,
				UniqueDays: uniqueDays,
			}
			continue
		}

		a.Count++
		if rep.CreatedAt.Before(a.First) {
			a.First = rep.CreatedAt
		}
		if rep.CreatedAt.After(a.Last) {
			a.Last = rep.CreatedAt
		}
		// Track unique days
		a.UniqueDays[reportDay] = true
	}

	// Calculate days in the selected month
	daysInMonth := time.Date(monthStart.Year(), monthStart.Month()+1, 0, 0, 0, 0, 0, monthStart.Location()).Day()

	stats := make([]EngineerReportStat, 0, len(aggregates))
	for email, a := range aggregates {
		// Active days between first and last report (inclusive) within the month
		activeDays := int(a.Last.Sub(a.First).Hours()/24) + 1
		if activeDays < 1 {
			activeDays = 1
		}

		// Completion rate based on unique days with reports (not total reports)
		// This shows what percentage of the month the engineer submitted at least one report
		// Maximum is 100% (all days in month have at least one report)
		uniqueDaysCount := len(a.UniqueDays)
		completionRate := 0.0
		if daysInMonth > 0 {
			completionRate = (float64(uniqueDaysCount) / float64(daysInMonth)) * 100.0
			// Cap at 100%
			if completionRate > 100.0 {
				completionRate = 100.0
			}
		}

		stats = append(stats, EngineerReportStat{
			UserEmail:      email,
			TotalReports:   a.Count,
			FirstReportAt:  a.First.Format(time.RFC3339),
			LastReportAt:   a.Last.Format(time.RFC3339),
			ActiveDays:     activeDays,
			CompletionRate: completionRate,
			Rank:           0, // filled after sorting
		})
	}

	// Sort by TotalReports descending, then by UserEmail for stability
	sort.Slice(stats, func(i, j int) bool {
		if stats[i].TotalReports == stats[j].TotalReports {
			return stats[i].UserEmail < stats[j].UserEmail
		}
		return stats[i].TotalReports > stats[j].TotalReports
	})

	// Assign rank
	for i := range stats {
		stats[i].Rank = i + 1
	}

	resp := AdminReportsSummaryResponse{
		Reports:     reports,
		Stats:       stats,
		PeriodStart: monthStart.Format(time.RFC3339),
		PeriodEnd:   nextMonthStart.Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("Error encoding admin engineer reports summary response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}

