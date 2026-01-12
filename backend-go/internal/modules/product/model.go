package product

// Product represents a product matching the database schema
type Product struct {
	ID                 string   `json:"id"`
	Name               string   `json:"name"`
	Brand              string   `json:"brand"`
	Series             string   `json:"series"`
	CategoryID         string   `json:"category_id"`
	TechnicalOverview  string   `json:"technical_overview"`
	TypicalApplication string   `json:"typical_application"`
	IsActive           bool     `json:"is_active"`
	DatasheetURL       string   `json:"datasheet_url"`
	Images             []string `json:"images"`
}
