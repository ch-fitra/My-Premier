package upload

import (
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"mypremier-backend/internal/common"
)

// init random seed for filename generation
func init() {
	rand.Seed(time.Now().UnixNano())
}

// generateUniqueFilename generates a unique filename using random bytes and timestamp.
func generateUniqueFilename(originalName string) string {
	ext := filepath.Ext(originalName)
	ts := time.Now().UnixNano()
	randomPart := rand.Int63()
	return fmt.Sprintf("%d_%d%s", ts, randomPart, ext)
}

// saveFile saves an uploaded file under uploads/promos/images and returns the relative URL path.
func saveFile(fileHeader *multipart.FileHeader) (string, error) {
	file, err := fileHeader.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	uploadDir := "uploads"
	imageDir := filepath.Join(uploadDir, "promos", "images")

	if err := os.MkdirAll(imageDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create promo image directory: %w", err)
	}

	filename := generateUniqueFilename(fileHeader.Filename)
	filePath := filepath.Join(imageDir, filename)

	dst, err := os.Create(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("failed to copy file: %w", err)
	}

	// Return relative path (e.g. /uploads/promos/images/abc123.jpg)
	return "/" + strings.ReplaceAll(filePath, "\\", "/"), nil
}

// HandleUpload handles POST /upload for promo images.
// Expects multipart/form-data with "file" field and returns JSON: { "url": "https://host/uploads/..." }.
func HandleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse multipart form (max 32MB)
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		common.WriteJSONError(w, http.StatusBadRequest, fmt.Sprintf("Failed to parse form data: %v", err))
		return
	}

	file, fileHeader, err := r.FormFile("file")
	if err != nil {
		common.WriteJSONError(w, http.StatusBadRequest, "file field is required")
		return
	}
	file.Close()

	relativeURL, err := saveFile(fileHeader)
	if err != nil {
		common.WriteJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to save file: %v", err))
		return
	}

	// Build absolute URL using request host, so clients can use it directly.
	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	host := r.Host
	absoluteURL := fmt.Sprintf("%s://%s%s", scheme, host, relativeURL)

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]string{
		"url": absoluteURL,
	}); err != nil {
		common.WriteJSONError(w, http.StatusInternalServerError, "Failed to encode response")
		return
	}
}


