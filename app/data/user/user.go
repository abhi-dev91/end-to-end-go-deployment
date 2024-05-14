package user

import (
	"database/sql"
	"davidggdev/api/core/database"
	"davidggdev/api/core/formatter"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

/**
 * @description User struct
 */
type User struct {
	ID    int    `json:"id"`
	Email string `json:"email"`
}

/**
 * @description All function
 * @param w http.ResponseWriter
 * @param r *http.Request
 * @return void
 */
func All(w http.ResponseWriter, r *http.Request) {
	var users []User

	query := "SELECT id, email FROM users"
	rows, err := database.Query(query)
	if err != nil {
		log.Printf("Error executing query: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var u User
		if err := rows.Scan(&u.ID, &u.Email); err != nil {
			log.Printf("Error scanning row: %v", err)
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			return
		}
		users = append(users, u)
	}

	if err = rows.Err(); err != nil {
		log.Printf("Error after iterating over rows: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	formatter.FormatResponse(w, users)
}

/**
 * @description GetByID function
 * @param w http.ResponseWriter
 * @param r *http.Request
 * @return void
 */
func GetByID(w http.ResponseWriter, r *http.Request) {
	var u User
	vars := mux.Vars(r)
	id := vars["id"]

	query := "SELECT id, email FROM users WHERE id = ?"
	row := database.QueryRow(query, id)
	err := row.Scan(&u.ID, &u.Email)
	if err != nil {
		log.Printf("Error en GetByID: %v", err)
		if err == sql.ErrNoRows {
			formatter.FormatResponseNotResults(w, err)
		} else {
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		}
		return
	}

	formatter.FormatResponse(w, u)
}
