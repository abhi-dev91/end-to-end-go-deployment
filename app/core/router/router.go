package router

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func Listen() {
	r := mux.NewRouter()

	// Check routes
	for _, route := range routes() {
		r.HandleFunc(route.Pattern, func(w http.ResponseWriter, r *http.Request) {
			route.HandlerFunc(w, r)
		}).Methods(route.Method)
	}

	// 404 Not Found
	r.PathPrefix("/").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.NotFound(w, r)
	})

	err := http.ListenAndServe("localhost:9090", r)
	if err != nil {
		log.Panic(err)
	}
}
