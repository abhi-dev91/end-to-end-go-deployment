package router

import (
	"davidggdev/api/data/user"
	"net/http"
)

/**
 * @description Route struct
 */
type Route struct {
	Name        string
	Method      string
	Pattern     string
	HandlerFunc http.HandlerFunc
}

/**
 * @description Routes function
 * @return []Route
 */
func routes() []Route {
	return []Route{
		{
			Name:        "Index",
			Method:      "GET",
			Pattern:     "/",
			HandlerFunc: user.All,
		},
		{
			Name:        "Index2",
			Method:      "GET",
			Pattern:     "/user/get/all",
			HandlerFunc: user.All,
		},
		{
			Name:        "Index3",
			Method:      "GET",
			Pattern:     "/user/get/id/{id}",
			HandlerFunc: user.GetByID,
		},
	}
}
