package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

// Product represents a product in the catalog
type Product struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	Stock       int       `json:"stock"`
	Category    string    `json:"category"`
	ImageURL    string    `json:"image_url"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Config holds application configuration
type Config struct {
	Port            string
	DBHost          string
	DBPort          string
	DBUser          string
	DBPassword      string
	DBName          string
	RedisHost       string
	RedisPort       string
	JaegerEndpoint  string
	LogLevel        string
}

// App holds application dependencies
type App struct {
	config      *Config
	db          *sql.DB
	redis       *redis.Client
	router      *mux.Router
	httpMetrics *HTTPMetrics
}

// HTTPMetrics holds Prometheus metrics
type HTTPMetrics struct {
	requests *prometheus.CounterVec
	duration *prometheus.HistogramVec
	errors   *prometheus.CounterVec
}

// Initialize Prometheus metrics
func newHTTPMetrics() *HTTPMetrics {
	return &HTTPMetrics{
		requests: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_requests_total",
				Help: "Total number of HTTP requests",
			},
			[]string{"method", "endpoint", "status"},
		),
		duration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_duration_seconds",
				Help:    "HTTP request latency distributions",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"method", "endpoint"},
		),
		errors: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_errors_total",
				Help: "Total number of HTTP errors",
			},
			[]string{"method", "endpoint", "error_type"},
		),
	}
}

// Load configuration from environment variables
func loadConfig() *Config {
	return &Config{
		Port:           getEnv("PORT", "8080"),
		DBHost:         getEnv("DB_HOST", "localhost"),
		DBPort:         getEnv("DB_PORT", "5432"),
		DBUser:         getEnv("DB_USER", "postgres"),
		DBPassword:     getEnv("DB_PASSWORD", "postgres"),
		DBName:         getEnv("DB_NAME", "products"),
		RedisHost:      getEnv("REDIS_HOST", "localhost"),
		RedisPort:      getEnv("REDIS_PORT", "6379"),
		JaegerEndpoint: getEnv("JAEGER_ENDPOINT", "http://jaeger-collector:14268/api/traces"),
		LogLevel:       getEnv("LOG_LEVEL", "info"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Initialize Jaeger tracer
func initTracer(serviceName string, jaegerEndpoint string) (*tracesdk.TracerProvider, error) {
	exporter, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(jaegerEndpoint)))
	if err != nil {
		return nil, err
	}

	tp := tracesdk.NewTracerProvider(
		tracesdk.WithBatcher(exporter),
		tracesdk.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(serviceName),
			attribute.String("environment", getEnv("ENVIRONMENT", "development")),
		)),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}

// Initialize database connection
func initDB(config *Config) (*sql.DB, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		config.DBHost, config.DBPort, config.DBUser, config.DBPassword, config.DBName,
	)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, err
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, err
	}

	// Initialize schema
	if err := initSchema(db); err != nil {
		return nil, err
	}

	return db, nil
}

// Initialize database schema
func initSchema(db *sql.DB) error {
	schema := `
	CREATE TABLE IF NOT EXISTS products (
		id SERIAL PRIMARY KEY,
		name VARCHAR(255) NOT NULL,
		description TEXT,
		price DECIMAL(10, 2) NOT NULL,
		stock INTEGER NOT NULL DEFAULT 0,
		category VARCHAR(100),
		image_url VARCHAR(500),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
	CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
	`

	_, err := db.Exec(schema)
	return err
}

// Initialize Redis connection
func initRedis(config *Config) *redis.Client {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", config.RedisHost, config.RedisPort),
		Password: "",
		DB:       0,
	})

	return client
}

// NewApp creates a new application instance
func NewApp() (*App, error) {
	config := loadConfig()

	// Initialize tracer
	tp, err := initTracer("product-service", config.JaegerEndpoint)
	if err != nil {
		log.Printf("Failed to initialize tracer: %v", err)
	} else {
		defer func() {
			if err := tp.Shutdown(context.Background()); err != nil {
				log.Printf("Error shutting down tracer provider: %v", err)
			}
		}()
	}

	// Initialize database
	db, err := initDB(config)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize database: %w", err)
	}

	// Initialize Redis
	redisClient := initRedis(config)

	// Test Redis connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Printf("Warning: Redis connection failed: %v", err)
	}

	app := &App{
		config:      config,
		db:          db,
		redis:       redisClient,
		router:      mux.NewRouter(),
		httpMetrics: newHTTPMetrics(),
	}

	app.setupRoutes()
	return app, nil
}

// Setup HTTP routes
func (a *App) setupRoutes() {
	// Health checks
	a.router.HandleFunc("/health/live", a.handleLiveness).Methods("GET")
	a.router.HandleFunc("/health/ready", a.handleReadiness).Methods("GET")
	a.router.HandleFunc("/health/startup", a.handleStartup).Methods("GET")

	// Metrics
	a.router.Handle("/metrics", promhttp.Handler())

	// API routes
	api := a.router.PathPrefix("/api/v1").Subrouter()
	api.Use(a.metricsMiddleware)
	api.Use(a.loggingMiddleware)

	api.HandleFunc("/products", a.handleGetProducts).Methods("GET")
	api.HandleFunc("/products/{id:[0-9]+}", a.handleGetProduct).Methods("GET")
	api.HandleFunc("/products", a.handleCreateProduct).Methods("POST")
	api.HandleFunc("/products/{id:[0-9]+}", a.handleUpdateProduct).Methods("PUT")
	api.HandleFunc("/products/{id:[0-9]+}", a.handleDeleteProduct).Methods("DELETE")
	api.HandleFunc("/products/search", a.handleSearchProducts).Methods("GET")
}

// Middleware for metrics collection
func (a *App) metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Wrap response writer to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		duration := time.Since(start).Seconds()
		endpoint := r.URL.Path

		// Record metrics
		a.httpMetrics.requests.WithLabelValues(r.Method, endpoint, fmt.Sprintf("%d", wrapped.statusCode)).Inc()
		a.httpMetrics.duration.WithLabelValues(r.Method, endpoint).Observe(duration)

		if wrapped.statusCode >= 400 {
			a.httpMetrics.errors.WithLabelValues(r.Method, endpoint, "http_error").Inc()
		}
	})
}

// Middleware for logging
func (a *App) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		log.Printf(
			"%s %s %d %s",
			r.Method,
			r.RequestURI,
			wrapped.statusCode,
			time.Since(start),
		)
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Health check handlers
func (a *App) handleLiveness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "alive"})
}

func (a *App) handleReadiness(w http.ResponseWriter, r *http.Request) {
	// Check database connection
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := a.db.PingContext(ctx); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]string{"status": "not ready", "error": err.Error()})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
}

func (a *App) handleStartup(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "started"})
}

// Product handlers
func (a *App) handleGetProducts(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	tracer := otel.Tracer("product-service")
	ctx, span := tracer.Start(ctx, "GetProducts")
	defer span.End()

	// Try cache first
	cacheKey := "products:all"
	cached, err := a.redis.Get(ctx, cacheKey).Result()
	if err == nil {
		var products []Product
		if err := json.Unmarshal([]byte(cached), &products); err == nil {
			span.SetAttributes(attribute.Bool("cache_hit", true))
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(products)
			return
		}
	}

	span.SetAttributes(attribute.Bool("cache_hit", false))

	// Query database
	rows, err := a.db.QueryContext(ctx, `
		SELECT id, name, description, price, stock, category, image_url, created_at, updated_at
		FROM products
		ORDER BY created_at DESC
		LIMIT 100
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var p Product
		err := rows.Scan(&p.ID, &p.Name, &p.Description, &p.Price, &p.Stock, &p.Category, &p.ImageURL, &p.CreatedAt, &p.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		products = append(products, p)
	}

	// Cache the result for 5 minutes
	if data, err := json.Marshal(products); err == nil {
		a.redis.Set(ctx, cacheKey, data, 5*time.Minute)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

func (a *App) handleGetProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	ctx := r.Context()
	tracer := otel.Tracer("product-service")
	ctx, span := tracer.Start(ctx, "GetProduct")
	defer span.End()
	span.SetAttributes(attribute.String("product.id", id))

	// Try cache
	cacheKey := fmt.Sprintf("product:%s", id)
	cached, err := a.redis.Get(ctx, cacheKey).Result()
	if err == nil {
		var product Product
		if err := json.Unmarshal([]byte(cached), &product); err == nil {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(product)
			return
		}
	}

	var product Product
	err = a.db.QueryRowContext(ctx, `
		SELECT id, name, description, price, stock, category, image_url, created_at, updated_at
		FROM products WHERE id = $1
	`, id).Scan(&product.ID, &product.Name, &product.Description, &product.Price, &product.Stock, &product.Category, &product.ImageURL, &product.CreatedAt, &product.UpdatedAt)

	if err == sql.ErrNoRows {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Cache for 10 minutes
	if data, err := json.Marshal(product); err == nil {
		a.redis.Set(ctx, cacheKey, data, 10*time.Minute)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func (a *App) handleCreateProduct(w http.ResponseWriter, r *http.Request) {
	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	err := a.db.QueryRowContext(ctx, `
		INSERT INTO products (name, description, price, stock, category, image_url)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`, product.Name, product.Description, product.Price, product.Stock, product.Category, product.ImageURL).
		Scan(&product.ID, &product.CreatedAt, &product.UpdatedAt)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Invalidate cache
	a.redis.Del(ctx, "products:all")

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(product)
}

func (a *App) handleUpdateProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	result, err := a.db.ExecContext(ctx, `
		UPDATE products
		SET name = $1, description = $2, price = $3, stock = $4, category = $5, image_url = $6, updated_at = CURRENT_TIMESTAMP
		WHERE id = $7
	`, product.Name, product.Description, product.Price, product.Stock, product.Category, product.ImageURL, id)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	// Invalidate cache
	a.redis.Del(ctx, fmt.Sprintf("product:%s", id), "products:all")

	w.WriteHeader(http.StatusOK)
}

func (a *App) handleDeleteProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	ctx := r.Context()
	result, err := a.db.ExecContext(ctx, "DELETE FROM products WHERE id = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	// Invalidate cache
	a.redis.Del(ctx, fmt.Sprintf("product:%s", id), "products:all")

	w.WriteHeader(http.StatusNoContent)
}

func (a *App) handleSearchProducts(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	category := r.URL.Query().Get("category")

	ctx := r.Context()
	sqlQuery := `
		SELECT id, name, description, price, stock, category, image_url, created_at, updated_at
		FROM products
		WHERE 1=1
	`
	args := []interface{}{}
	argCount := 1

	if query != "" {
		sqlQuery += fmt.Sprintf(" AND (name ILIKE $%d OR description ILIKE $%d)", argCount, argCount)
		args = append(args, "%"+query+"%")
		argCount++
	}

	if category != "" {
		sqlQuery += fmt.Sprintf(" AND category = $%d", argCount)
		args = append(args, category)
		argCount++
	}

	sqlQuery += " ORDER BY created_at DESC LIMIT 100"

	rows, err := a.db.QueryContext(ctx, sqlQuery, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var p Product
		err := rows.Scan(&p.ID, &p.Name, &p.Description, &p.Price, &p.Stock, &p.Category, &p.ImageURL, &p.CreatedAt, &p.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		products = append(products, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

// Start the HTTP server
func (a *App) Start() error {
	srv := &http.Server{
		Addr:         ":" + a.config.Port,
		Handler:      a.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		log.Println("Shutting down server...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := srv.Shutdown(ctx); err != nil {
			log.Printf("HTTP server shutdown error: %v", err)
		}

		a.db.Close()
		a.redis.Close()
	}()

	log.Printf("Server starting on port %s", a.config.Port)
	return srv.ListenAndServe()
}

func main() {
	app, err := NewApp()
	if err != nil {
		log.Fatalf("Failed to initialize app: %v", err)
	}

	if err := app.Start(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}
