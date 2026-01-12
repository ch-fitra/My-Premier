package common

import (
	"encoding/json"
	"log"
	"net/http"
)

// WriteJSONError writes a JSON error response
func WriteJSONError(w http.ResponseWriter, statusCode int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	response := map[string]interface{}{
		"error":   true,
		"message": message,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding error response: %v", err)
	}
}

