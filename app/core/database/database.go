package database

import (
	"database/sql"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

/**
 * @var db *sql.DB
 * @description Database connection
 */
var db *sql.DB

/**
 * @description InitDB function
 * @param dataSourceName string
 * @return void
 */
func InitDB(dataSourceName string) {

	var err error
	db, err = sql.Open("mysql", dataSourceName)
	if err != nil {
		log.Panic(err)
	}
}

/**
 * @description Close function
 * @return void
 */
func Close() {
	db.Close()
}

/**
 * @description Query function
 * @param query string
 * @param args ...interface{}
 * @return *sql.Rows
 */
func Query(query string, args ...interface{}) (*sql.Rows, error) {
	return db.Query(query, args...)
}

/**
 * @description QueryRow function
 * @param query string
 * @param args ...interface{}
 * @return *sql.Row
 */
func QueryRow(query string, args ...interface{}) *sql.Row {
	return db.QueryRow(query, args...)
}

/**
 * @description Exec function
 * @param query string
 * @param args ...interface{}
 * @return sql.Result
 */
func Exec(query string, args ...interface{}) (sql.Result, error) {
	return db.Exec(query, args...)
}
