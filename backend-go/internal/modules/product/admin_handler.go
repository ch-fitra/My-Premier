package product

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"mypremier-backend/internal/common"
	"mypremier-backend/internal/modules/audit"
)

type AdminHandler struct {
	repo        *Repository
	auditHandler *audit.Handler
	uploadDir   string
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

	// Create upload directories
	uploadDir := "uploads"
	imageDir := filepath.Join(uploadDir, "products", "images")
	datasheetDir := filepath.Join(uploadDir, "products", "datasheets")

	if err := os.MkdirAll(imageDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create image directory: %w", err)
	}
	if err := os.MkdirAll(datasheetDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create datasheet directory: %w", err)
	}

	return &AdminHandler{
		repo:        repo,
		auditHandler: auditHandler,
		uploadDir:   uploadDir,
	}, nil
}

func (h *AdminHandler) GetProducts(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		common.WriteJSONError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	products, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Error fetching products: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to fetch products: %v", err))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(products); err != nil {
		log.Printf("Error encoding response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

// generateUniqueFilename generates a unique filename using random bytes
func generateUniqueFilename(originalName string) string {
	ext := filepath.Ext(originalName)
	randomBytes := make([]byte, 16)
	rand.Read(randomBytes)
	randomHex := hex.EncodeToString(randomBytes)
	return randomHex + ext
}

// saveFile saves an uploaded file and returns the relative path
func (h *AdminHandler) saveFile(fileHeader *multipart.FileHeader, subdir string) (string, error) {
	file, err := fileHeader.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	// Generate unique filename
	filename := generateUniqueFilename(fileHeader.Filename)
	filePath := filepath.Join(h.uploadDir, "products", subdir, filename)

	// Create the file
	dst, err := os.Create(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("failed to copy file: %w", err)
	}

	// Return relative path (e.g., /uploads/products/images/abc123.jpg)
	return "/" + strings.ReplaceAll(filePath, "\\", "/"), nil
}

func (h *AdminHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var name, brand, series, categoryID, technicalOverview, typicalApplication, datasheetURL string
	// Default to true if not explicitly provided, to respect DB default and requirements
	isActive := true
	var imageURLs []string

	// Check if request is JSON or FormData
	contentType := r.Header.Get("Content-Type")
	if strings.Contains(contentType, "application/json") {
		// Handle JSON request
		var jsonData map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&jsonData); err != nil {
			log.Printf("Error decoding JSON: %v", err)
			common.WriteJSONError(w, http.StatusBadRequest, "Invalid JSON")
			return
		}

		// Extract all fields from JSON
		if val, ok := jsonData["name"].(string); ok {
			name = strings.TrimSpace(val)
		}
		if name == "" {
			common.WriteJSONError(w, http.StatusBadRequest, "Name is required")
			return
		}
		if val, ok := jsonData["brand"].(string); ok {
			brand = strings.TrimSpace(val)
		}
		if val, ok := jsonData["series"].(string); ok {
			series = strings.TrimSpace(val)
		}
		if val, ok := jsonData["category_id"].(string); ok {
			categoryID = strings.TrimSpace(val)
		}
		if val, ok := jsonData["technical_overview"].(string); ok {
			technicalOverview = strings.TrimSpace(val)
		}
		if val, ok := jsonData["typical_application"].(string); ok {
			typicalApplication = strings.TrimSpace(val)
		}
		if val, ok := jsonData["datasheet_url"].(string); ok {
			datasheetURL = strings.TrimSpace(val)
		}
		if val, ok := jsonData["is_active"].(bool); ok {
			isActive = val
		}

		// Extract images array from JSON - array of strings (URLs)
		if images, ok := jsonData["images"].([]interface{}); ok {
			for _, img := range images {
				if imgStr, ok := img.(string); ok && strings.TrimSpace(imgStr) != "" {
					imageURLs = append(imageURLs, strings.TrimSpace(imgStr))
				}
			}
		}
	} else {
		// Handle FormData request (multipart/form-data) - kept for backward compatibility
		if err := r.ParseMultipartForm(32 << 20); err != nil {
			log.Printf("Error parsing multipart form: %v", err)
			common.WriteJSONError(w, http.StatusBadRequest, "Failed to parse form data")
			return
		}

		// Extract form values
		name = strings.TrimSpace(r.FormValue("name"))
		if name == "" {
			common.WriteJSONError(w, http.StatusBadRequest, "Name is required")
			return
		}
		brand = strings.TrimSpace(r.FormValue("brand"))
		series = strings.TrimSpace(r.FormValue("series"))
		categoryID = strings.TrimSpace(r.FormValue("category_id"))
		technicalOverview = strings.TrimSpace(r.FormValue("technical_overview"))
		typicalApplication = strings.TrimSpace(r.FormValue("typical_application"))
		datasheetURL = strings.TrimSpace(r.FormValue("datasheet_url"))
		// Respect explicit is_active/active form values; otherwise keep default true
		isActiveStr := r.FormValue("is_active")
		if isActiveStr == "" {
			isActiveStr = r.FormValue("active")
		}
		if isActiveStr != "" {
			isActive = isActiveStr == "true"
		}

		// Collect image URLs from form
		existingImages := r.Form["images[]"]
		for _, img := range existingImages {
			if trimmed := strings.TrimSpace(img); trimmed != "" {
				imageURLs = append(imageURLs, trimmed)
			}
		}

		// Handle uploaded image files
		imageFiles := r.MultipartForm.File["images[]"]
		if imageFiles != nil {
			for _, fileHeader := range imageFiles {
				path, err := h.saveFile(fileHeader, "images")
				if err != nil {
					log.Printf("Error saving image file: %v", err)
					http.Error(w, fmt.Sprintf("Failed to save image: %v", err), http.StatusInternalServerError)
					return
				}
				imageURLs = append(imageURLs, path)
			}
		}

		// Handle datasheet file upload if provided
		if datasheetFile, _, err := r.FormFile("datasheet"); err == nil {
			datasheetFile.Close()
			fileHeader := r.MultipartForm.File["datasheet"][0]
			path, err := h.saveFile(fileHeader, "datasheets")
			if err != nil {
				log.Printf("Error saving datasheet file: %v", err)
				http.Error(w, fmt.Sprintf("Failed to save datasheet: %v", err), http.StatusInternalServerError)
				return
			}
			datasheetURL = path
		}
	}

	product := Product{
		Name:               name,
		Brand:              brand,
		Series:             series,
		CategoryID:         categoryID,
		TechnicalOverview:  technicalOverview,
		TypicalApplication: typicalApplication,
		IsActive:           isActive,
		DatasheetURL:       datasheetURL,
	}

	// Create product with images in transaction
	id, err := h.repo.Create(r.Context(), product, imageURLs)
	if err != nil {
		log.Printf("Error creating product: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to create product: %v", err))
		return
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "created", "product", id)

	// Fetch created product to return with images
	createdProduct, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		log.Printf("Error fetching created product: %v", err)
		// Still return 201 with basic info
		product.ID = id
		createdProduct = &product
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(createdProduct); err != nil {
		log.Printf("Error encoding response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

func (h *AdminHandler) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract product ID from path /admin/products/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/products/")
	productID := path
	
	if path == "" || path == r.URL.Path {
		common.WriteJSONError(w, http.StatusBadRequest, "Product ID is required")
		return
	}

	var name, brand, series, categoryID, technicalOverview, typicalApplication, datasheetURL string
	// Default to true if not explicitly provided, to respect DB default and requirements
	active := true
	var imageURLs []string

	// Check if request is JSON or FormData
	contentType := r.Header.Get("Content-Type")
	if strings.Contains(contentType, "application/json") {
		// Handle JSON request
		var jsonData map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&jsonData); err != nil {
			log.Printf("Error decoding JSON: %v", err)
			common.WriteJSONError(w, http.StatusBadRequest, "Invalid JSON")
			return
		}

		// Extract all fields from JSON
		if val, ok := jsonData["name"].(string); ok {
			name = strings.TrimSpace(val)
		}
		if val, ok := jsonData["brand"].(string); ok {
			brand = strings.TrimSpace(val)
		}
		if val, ok := jsonData["series"].(string); ok {
			series = strings.TrimSpace(val)
		}
		if val, ok := jsonData["category_id"].(string); ok {
			categoryID = strings.TrimSpace(val)
		}
		if val, ok := jsonData["technical_overview"].(string); ok {
			technicalOverview = strings.TrimSpace(val)
		}
		if val, ok := jsonData["typical_application"].(string); ok {
			typicalApplication = strings.TrimSpace(val)
		}
		if val, ok := jsonData["datasheet_url"].(string); ok {
			datasheetURL = strings.TrimSpace(val)
		}
		if val, ok := jsonData["active"].(bool); ok {
			active = val
		} else if val, ok := jsonData["is_active"].(bool); ok {
			active = val
		}

		// Extract images array from JSON - array of strings (URLs)
		if images, ok := jsonData["images"].([]interface{}); ok {
			for _, img := range images {
				if imgStr, ok := img.(string); ok && strings.TrimSpace(imgStr) != "" {
					imageURLs = append(imageURLs, strings.TrimSpace(imgStr))
				}
			}
		}
	} else {
		// Handle FormData request (multipart/form-data)
		if err := r.ParseMultipartForm(32 << 20); err != nil {
			log.Printf("Error parsing multipart form: %v", err)
			common.WriteJSONError(w, http.StatusBadRequest, "Failed to parse form data")
			return
		}

		// Extract all form values
		name = strings.TrimSpace(r.FormValue("name"))
		brand = strings.TrimSpace(r.FormValue("brand"))
		series = strings.TrimSpace(r.FormValue("series"))
		categoryID = strings.TrimSpace(r.FormValue("category_id"))
		technicalOverview = strings.TrimSpace(r.FormValue("technical_overview"))
		typicalApplication = strings.TrimSpace(r.FormValue("typical_application"))
		datasheetURL = strings.TrimSpace(r.FormValue("datasheet_url"))
		activeStr := r.FormValue("active")
		if activeStr == "" {
			activeStr = r.FormValue("is_active")
		}
		// Only override default when an explicit value is provided
		if activeStr != "" {
			active = activeStr == "true"
		}

		// Collect existing image URLs from form
		existingImages := r.Form["existing_images[]"]
		for _, img := range existingImages {
			if trimmed := strings.TrimSpace(img); trimmed != "" {
				imageURLs = append(imageURLs, trimmed)
			}
		}

		// Also check images[] form field for URLs
		imageFormValues := r.Form["images[]"]
		for _, img := range imageFormValues {
			if trimmed := strings.TrimSpace(img); trimmed != "" {
				imageURLs = append(imageURLs, trimmed)
			}
		}

		// Handle uploaded image files
		imageFiles := r.MultipartForm.File["images[]"]
		if imageFiles != nil {
			for _, fileHeader := range imageFiles {
				path, err := h.saveFile(fileHeader, "images")
				if err != nil {
					log.Printf("Error saving image file: %v", err)
					http.Error(w, fmt.Sprintf("Failed to save image: %v", err), http.StatusInternalServerError)
					return
				}
				imageURLs = append(imageURLs, path)
			}
		}

		// Handle datasheet file upload if provided
		if datasheetFile, _, err := r.FormFile("datasheet"); err == nil {
			datasheetFile.Close()
			fileHeader := r.MultipartForm.File["datasheet"][0]
			path, err := h.saveFile(fileHeader, "datasheets")
			if err != nil {
				log.Printf("Error saving datasheet file: %v", err)
				http.Error(w, fmt.Sprintf("Failed to save datasheet: %v", err), http.StatusInternalServerError)
				return
			}
			datasheetURL = path
		}
	}

	product := Product{
		Name:               name,
		Brand:              brand,
		Series:             series,
		CategoryID:         categoryID,
		TechnicalOverview:  technicalOverview,
		TypicalApplication: typicalApplication,
		IsActive:           active,
		DatasheetURL:       datasheetURL,
	}

	// Update product with images using transaction
	err := h.repo.Update(r.Context(), productID, product, imageURLs)
	if err != nil {
		log.Printf("Error updating product %s: %v", productID, err)
		if strings.Contains(err.Error(), "not found") {
			common.WriteJSONError(w, http.StatusNotFound, fmt.Sprintf("Product not found: %s", productID))
			return
		}
		common.WriteJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to update product: %v", err))
		return
	}

	// Fetch updated product to return
	updatedProduct, err := h.repo.GetByID(r.Context(), productID)
	if err != nil {
		log.Printf("Error fetching updated product: %v", err)
		// Still return 200 with what we have
		product.ID = productID
		updatedProduct = &product
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "updated", "product", productID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(updatedProduct); err != nil {
		log.Printf("Error encoding response: %v", err)
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
}

func (h *AdminHandler) DeleteProduct(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract product ID from path /admin/products/{id}
	path := strings.TrimPrefix(r.URL.Path, "/admin/products/")
	if path == "" || path == r.URL.Path {
		common.WriteJSONError(w, http.StatusBadRequest, "Product ID is required")
		return
	}

	err := h.repo.Delete(r.Context(), path)
	if err != nil {
		log.Printf("Error deleting product: %v", err)
		if strings.Contains(err.Error(), "not found") {
			common.WriteJSONError(w, http.StatusNotFound, "Product not found")
			return
		}
		common.WriteJSONError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	// Log audit action
	_ = h.auditHandler.LogAction(r.Context(), "deleted", "product", path)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]interface{}{
		"id":      path,
		"message": "Product deleted successfully",
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}
