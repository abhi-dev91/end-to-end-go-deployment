package formatter

import (
	"encoding/json"
	"net/http"
)

/**
 * @description FormatResponse function
 * @param w http.ResponseWriter
 * @param data interface{}
 * @return void
 */
func FormatResponse(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

/**
 * @description FormatResponseNotResults function
 * @param w http.ResponseWriter
 * @param err error
 * @return void
 */
func FormatResponseNotResults(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusInternalServerError)
	json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
}
