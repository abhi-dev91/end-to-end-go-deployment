package main

import (
	"davidggdev/api/core/database"
	"davidggdev/api/core/router"
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

/**
 * @var version string
 * @description Version of the API
 */
var version = "0.1a"

/**
 * @description Init function
 * @return void
 */
func Init() {
	fmt.Println("API REST - DavidGGDev v" + version)
	LoadEnv()
	LoadDB()
	LoadRouter()
	CloseDB()
}

/**
 * @description LoadEnv function
 * @return void
 */
func LoadEnv() {
	err := godotenv.Load()
	if err != nil {
		fmt.Println("Error cargando el archivo .env")
	}
}

/**
 * @description LoadDB function
 * @return void
 */
func LoadDB() {
	dataSourceName := fmt.Sprintf("%s:%s@tcp(%s)/%s?charset=utf8mb4,utf8&parseTime=True&loc=Local",
		os.Getenv("DATABASE_USER"),
		os.Getenv("DATABASE_PASSWORD"),
		os.Getenv("DATABASE_URL"),
		os.Getenv("DATABASE_NAME"),
	)
	database.InitDB(dataSourceName)
}

/**
 * @description CloseDB function
 * @return void
 */
func CloseDB() {
	database.Close()
}

/**
 * @description LoadRouter function
 * @return void
 */
func LoadRouter() {
	router.Listen()
}

/**
 * @description Main function
 * @return void
 */
func main() {
	Init()
}
