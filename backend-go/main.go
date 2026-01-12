package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"

	"mypremier-backend/internal/common/authcontext"
	"mypremier-backend/internal/common/jwt"
	"mypremier-backend/internal/config"
	"mypremier-backend/internal/middleware"
	"mypremier-backend/internal/modules/audit"
	"mypremier-backend/internal/modules/auth"
	"mypremier-backend/internal/modules/category"
	"mypremier-backend/internal/modules/product"
	"mypremier-backend/internal/modules/report"
	"mypremier-backend/internal/modules/promo"
	"mypremier-backend/internal/modules/request"
	"mypremier-backend/internal/modules/stats"
	"mypremier-backend/internal/modules/support"
	"mypremier-backend/internal/modules/user"
	"mypremier-backend/internal/modules/upload"
)

func main() {
	// Load environment variables from .env at startup (optional, Railway uses env vars directly).
	if err := godotenv.Load(); err != nil {
		log.Printf("⚠️  Could not load .env file: %v", err)
	}

	// Fail fast if DATABASE_URL is not set.
	if strings.TrimSpace(os.Getenv("DATABASE_URL")) == "" {
		log.Fatal("DATABASE_URL environment variable is not set; cannot start server")
	}

	// Initialize the database once at application startup, before any repositories,
	// handlers, or routers are created.
	ctx := context.Background()
	config.InitDatabase(ctx)
	defer config.CloseDatabase()

	// Ensure password_hash column exists (for existing databases)
	ensurePasswordHashColumn(ctx)

	// Force reset admin password to "admin123"
	if err := resetAdminPassword(ctx); err != nil {
		log.Printf("⚠️  Warning: Failed to reset admin password: %v", err)
	}

	// Initialize JWT
	if err := jwt.Init(); err != nil {
		log.Fatalf("Failed to initialize JWT: %v", err)
	}

	mux := http.NewServeMux()

	// Serve static files from uploads directory
	fs := http.FileServer(http.Dir("uploads"))
	mux.Handle("/uploads/", http.StripPrefix("/uploads/", fs))

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("MY PREMIER API is running"))
	})

	// Auth endpoints
	authHandler, err := auth.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize auth handler: %v", err)
	}
	mux.HandleFunc("/auth/login", authHandler.Login)
	mux.HandleFunc("/auth/register", authHandler.Register)
	mux.HandleFunc("/auth/google", authHandler.GoogleAuth)
	authMeHandler := http.HandlerFunc(authHandler.Me)
	mux.Handle("/auth/me", middleware.AuthRequired(authMeHandler))

	// protected test endpoint
	protected := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := authcontext.GetUserID(r.Context())
		w.Write([]byte("Hello User ID: " + userID))
	})

	mux.Handle("/protected", middleware.AuthRequired(protected))

	// Category endpoints
	categoryHandler, err := category.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize category handler: %v", err)
	}
	mux.HandleFunc("/categories", categoryHandler.GetCategories)

	// Admin Category endpoints
	adminCategoryHandler, err := category.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin category handler: %v", err)
	}
	// Method router for /admin/categories (GET, POST)
	adminCategoriesRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			adminCategoryHandler.GetCategories(w, r)
		case http.MethodPost:
			adminCategoryHandler.CreateCategory(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/categories", middleware.AuthRequired(adminCategoriesRouter))
	// Method router for /admin/categories/{id} (PUT, DELETE)
	adminCategoryRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			adminCategoryHandler.UpdateCategory(w, r)
		case http.MethodDelete:
			adminCategoryHandler.DeleteCategory(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/categories/", middleware.AuthRequired(adminCategoryRouter))

	// Product endpoints
	productHandler, err := product.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize product handler: %v", err)
	}
	mux.HandleFunc("/products", productHandler.GetProducts)
	mux.HandleFunc("/products/", productHandler.GetProduct)

	// Admin Product endpoints
	adminProductHandler, err := product.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin product handler: %v", err)
	}
	// Method router for /admin/products (GET, POST)
	adminProductsRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			adminProductHandler.GetProducts(w, r)
		case http.MethodPost:
			adminProductHandler.CreateProduct(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/products", middleware.AuthRequired(adminProductsRouter))
	// Method router for /admin/products/{id} (PUT, DELETE)
	adminProductRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			adminProductHandler.UpdateProduct(w, r)
		case http.MethodDelete:
			adminProductHandler.DeleteProduct(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/products/", middleware.AuthRequired(adminProductRouter))

	// Request Info endpoints
	requestHandler, err := request.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize request handler: %v", err)
	}
	mux.HandleFunc("/request-info", requestHandler.CreateRequest)

	// Sales Request endpoints (Sales mobile app)
	salesRequestHandler, err := request.NewSalesHandler()
	if err != nil {
		log.Fatalf("Failed to initialize sales request handler: %v", err)
	}
	// Method router for /sales/requests (GET, POST)
	salesRequestsRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			salesRequestHandler.GetSalesRequests(w, r)
		case http.MethodPost:
			salesRequestHandler.CreateSalesRequest(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/sales/requests",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleSales)(salesRequestsRouter),
			),
		),
	)

	// Sales Support endpoints (Sales mobile app)
	salesSupportHandler, err := support.NewSalesHandler()
	if err != nil {
		log.Fatalf("Failed to initialize sales support handler: %v", err)
	}
	// Method router for /sales/supports (GET only - sales cannot create tickets)
	salesSupportsRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			salesSupportHandler.GetSalesSupports(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/sales/supports",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleSales)(salesSupportsRouter),
			),
		),
	)

	// Client Request endpoints (Client mobile app)
	clientRequestHandler, err := request.NewClientHandler()
	if err != nil {
		log.Fatalf("Failed to initialize client request handler: %v", err)
	}
	// Method router for /client/requests (GET, POST)
	clientRequestsRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			clientRequestHandler.GetClientRequests(w, r)
		case http.MethodPost:
			clientRequestHandler.CreateClientRequest(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/client/requests",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleClient)(clientRequestsRouter),
			),
		),
	)
	// Method router for /sales/supports/{id} (GET) and /sales/supports/{id}/messages (POST)
	salesSupportRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if strings.HasSuffix(path, "/messages") {
			// POST /sales/supports/{id}/messages
			if r.Method == http.MethodPost {
				salesSupportHandler.SendSalesMessage(w, r)
			} else {
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		} else {
			// GET /sales/supports/{id}
			if r.Method == http.MethodGet {
				salesSupportHandler.GetSalesSupportDetail(w, r)
			} else {
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		}
	})
	mux.Handle("/sales/supports/",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleSales)(salesSupportRouter),
			),
		),
	)

	// Admin Request endpoints
	adminRequestHandler, err := request.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin request handler: %v", err)
	}
	adminGetRequests := http.HandlerFunc(adminRequestHandler.GetRequests)
	mux.Handle("/admin/requests", middleware.AuthRequired(adminGetRequests))

	// Support endpoints
	supportHandler, err := support.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize support handler: %v", err)
	}
	mux.HandleFunc("/support", supportHandler.CreateSupport)

	// Client Support endpoints (role-restricted to clients only)
	clientSupportHandler, err := support.NewClientHandler()
	if err != nil {
		log.Fatalf("Failed to initialize client support handler: %v", err)
	}
	clientSupportRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPost:
			clientSupportHandler.CreateClientSupport(w, r)
		case http.MethodGet:
			clientSupportHandler.GetClientSupports(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/client/supports",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleClient)(clientSupportRouter),
			),
		),
	)

	// Client Support detail and messages endpoints:
	// GET  /client/supports/{id}
	// GET  /client/supports/{id}/messages
	// POST /client/supports/{id}/messages
	clientSupportDetailRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if strings.HasSuffix(path, "/messages") {
			switch r.Method {
			case http.MethodGet:
				clientSupportHandler.GetClientSupportMessages(w, r)
			case http.MethodPost:
				clientSupportHandler.CreateClientSupportMessage(w, r)
			default:
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		} else {
			if r.Method == http.MethodGet {
				clientSupportHandler.GetClientSupportByID(w, r)
			} else {
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		}
	})
	mux.Handle("/client/supports/",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleClient)(clientSupportDetailRouter),
			),
		),
	)

	// Admin Support endpoints
	adminSupportHandler, err := support.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin support handler: %v", err)
	}
	adminGetSupports := http.HandlerFunc(adminSupportHandler.GetSupports)
	mux.Handle("/admin/supports", middleware.AuthRequired(adminGetSupports))
	adminUpdateSupport := http.HandlerFunc(adminSupportHandler.UpdateSupportStatus)
	mux.Handle("/admin/support/", middleware.AuthRequired(adminUpdateSupport))

	// Support Message endpoints
	messageHandler, err := support.NewMessageHandler()
	if err != nil {
		log.Fatalf("Failed to initialize message handler: %v", err)
	}
	// Method router for /supports/{id}/messages (GET, POST)
	supportMessagesRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			messageHandler.GetMessages(w, r)
		case http.MethodPost:
			messageHandler.CreateMessage(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/supports/", middleware.AuthRequired(supportMessagesRouter))

	// Admin User endpoints
	adminUserHandler, err := user.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin user handler: %v", err)
	}
	// Method router for /admin/users (GET, POST)
	adminUsersRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			adminUserHandler.GetUsers(w, r)
		case http.MethodPost:
			adminUserHandler.CreateUser(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/users", middleware.AuthRequired(adminUsersRouter))
	// Method router for /admin/users/{id} (PUT, DELETE) and /admin/users/{id}/role, /admin/users/{id}/status (PATCH)
	adminUserRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if strings.HasSuffix(path, "/role") {
			if r.Method == http.MethodPatch {
				adminUserHandler.UpdateUserRole(w, r)
			} else {
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		} else if strings.HasSuffix(path, "/status") {
			if r.Method == http.MethodPatch {
				adminUserHandler.UpdateUserStatus(w, r)
			} else {
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		} else {
			// /admin/users/{id} - PUT or DELETE
			switch r.Method {
			case http.MethodPut:
				adminUserHandler.UpdateUser(w, r)
			case http.MethodDelete:
				adminUserHandler.DeleteUser(w, r)
			default:
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			}
		}
	})
	mux.Handle("/admin/users/", middleware.AuthRequired(adminUserRouter))

	// Admin Me endpoint - returns current user info (id, email, role) from PostgreSQL using JWT claims
	meHandler, err := user.NewMeHandler()
	if err != nil {
		log.Fatalf("Failed to initialize me handler: %v", err)
	}
	adminMeHandler := http.HandlerFunc(meHandler.GetMe)
	mux.Handle("/admin/me", middleware.AuthRequired(adminMeHandler))

	// Me endpoint for all roles - GET /me, PUT /me, PUT /me/password
	// Handle /me/password first (more specific route)
	mePasswordHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPut {
			meHandler.UpdatePassword(w, r)
		} else {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/me/password", middleware.AuthRequired(mePasswordHandler))

	// Handle /me (GET and PUT)
	meRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			meHandler.GetMe(w, r)
		case http.MethodPut:
			meHandler.UpdateProfile(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/me", middleware.AuthRequired(meRouter))

	// Admin Stats endpoints
	statsHandler, err := stats.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize stats handler: %v", err)
	}
	adminStatsSummary := http.HandlerFunc(statsHandler.GetSummary)
	mux.Handle("/admin/stats/summary", middleware.AuthRequired(adminStatsSummary))

	// Client dashboard summary endpoint (client role only)
	clientSummaryHandler := http.HandlerFunc(statsHandler.GetClientSummary)
	mux.Handle("/client/dashboard/summary",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleClient)(clientSummaryHandler),
			),
		),
	)

	// Promo endpoints
	promoAdminHandler, err := promo.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize promo admin handler: %v", err)
	}
	promoClientHandler, err := promo.NewClientHandler()
	if err != nil {
		log.Fatalf("Failed to initialize promo client handler: %v", err)
	}

	// /admin/promos (GET, POST)
	adminPromosRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			promoAdminHandler.GetPromos(w, r)
		case http.MethodPost:
			promoAdminHandler.CreatePromo(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/promos",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleAdmin)(adminPromosRouter),
			),
		),
	)

	// /admin/promos/{id} (PUT, DELETE)
	adminPromoRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			promoAdminHandler.UpdatePromo(w, r)
		case http.MethodDelete:
			promoAdminHandler.DeletePromo(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/admin/promos/",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleAdmin)(adminPromoRouter),
			),
		),
	)

	// /client/promos (GET active promos for clients only)
	clientPromosRouter := http.HandlerFunc(promoClientHandler.GetClientPromos)
	mux.Handle("/client/promos",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleClient)(clientPromosRouter),
			),
		),
	)

	// Generic upload endpoint for admin (used by promo image upload)
	uploadHandler := http.HandlerFunc(upload.HandleUpload)
	mux.Handle("/upload",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleAdmin)(uploadHandler),
			),
		),
	)

	// Admin Audit Logs endpoints
	auditHandler, err := audit.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize audit handler: %v", err)
	}
	adminAuditLogs := http.HandlerFunc(auditHandler.GetAuditLogs)
	mux.Handle("/admin/audit-logs", middleware.AuthRequired(adminAuditLogs))

	// Engineer Report endpoints (Engineer mobile app)
	engineerReportHandler, err := report.NewHandler()
	if err != nil {
		log.Fatalf("Failed to initialize engineer report handler: %v", err)
	}
	// Method router for /engineer/reports (GET, POST)
	engineerReportsRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			engineerReportHandler.GetReports(w, r)
		case http.MethodPost:
			engineerReportHandler.CreateReport(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/engineer/reports",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleEngineer)(engineerReportsRouter),
			),
		),
	)
	// Method router for /engineer/reports/{id} (GET, DELETE)
	engineerReportRouter := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			engineerReportHandler.GetReportByID(w, r)
		case http.MethodDelete:
			engineerReportHandler.DeleteReport(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.Handle("/engineer/reports/",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleEngineer)(engineerReportRouter),
			),
		),
	)

	// Admin Engineer Report endpoints (Admin web)
	adminEngineerReportHandler, err := report.NewAdminHandler()
	if err != nil {
		log.Fatalf("Failed to initialize admin engineer report handler: %v", err)
	}
	adminEngineerReportsSummary := http.HandlerFunc(adminEngineerReportHandler.GetReportsSummary)
	mux.Handle("/admin/engineer-reports/summary",
		middleware.AuthRequired(
			user.LoadUserRole(
				user.RequireRole(user.RoleAdmin)(adminEngineerReportsSummary),
			),
		),
	)

	// Apply CORS middleware globally
	handler := middleware.CORS(mux)

	// Get PORT from environment variable (Railway provides PORT)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default port for local development
	}
	addr := ":" + port

	server := &http.Server{
		Addr:    addr,
		Handler: handler,
	}

	log.Printf("🚀 Server running on %s", addr)
	log.Fatal(server.ListenAndServe())
}

// ensurePasswordHashColumn ensures the password_hash column exists in the users table
func ensurePasswordHashColumn(ctx context.Context) {
	// Check if column exists by trying to query it
	var exists bool
	err := config.DB.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 
			FROM information_schema.columns 
			WHERE table_name = 'users' 
			AND column_name = 'password_hash'
		)
	`).Scan(&exists)
	
	if err != nil {
		log.Printf("⚠️  Warning: Could not check for password_hash column: %v", err)
		return
	}

	if !exists {
		log.Println("📝 Adding password_hash column to users table...")
		_, err := config.DB.Exec(ctx, `
			ALTER TABLE users 
			ADD COLUMN IF NOT EXISTS password_hash TEXT NOT NULL DEFAULT ''
		`)
		if err != nil {
			log.Printf("⚠️  Warning: Could not add password_hash column: %v", err)
			return
		}
		log.Println("✅ password_hash column added successfully")
	}
}

// resetAdminPassword resets the admin password to "admin123" using pgcrypto
func resetAdminPassword(ctx context.Context) error {
	adminEmail := "admin@mypremier.co.id"
	adminPassword := "admin123"

	// Use pgcrypto to generate and set the password hash
	_, err := config.DB.Exec(ctx, `
		UPDATE users
		SET password_hash = crypt($1, gen_salt('bf'))
		WHERE email = $2
	`, adminPassword, adminEmail)
	if err != nil {
		return err
	}

	// Check if any rows were affected
	var count int64
	err = config.DB.QueryRow(ctx, `
		SELECT COUNT(*) FROM users WHERE email = $1
	`, adminEmail).Scan(&count)
	if err != nil {
		return err
	}

	if count == 0 {
		log.Printf("⚠️  Warning: Admin user %s not found. Please create the user first.", adminEmail)
		return nil
	}

	log.Printf("✅ Admin password reset successfully for %s", adminEmail)
	return nil
}
