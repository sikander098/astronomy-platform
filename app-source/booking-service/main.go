package main

import (
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Ticket represents a seat in the database
type Ticket struct {
	ID        uint   `gorm:"primaryKey"`
	EventName string `json:"event_name"`
	Status    string `json:"status"` // "AVAILABLE", "SOLD"
	OwnerID   string `json:"owner_id"`
}

var db *gorm.DB
var log = logrus.New()

func initDB() {
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		// Default for local testing (will be overridden in K8s)
		dsn = "host=localhost user=postgres password=password dbname=tickets port=5432 sslmode=disable"
	}

	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Warn("Failed to connect to database, retrying in 5s...")
		time.Sleep(5 * time.Second)
		initDB() // Simple retry logic for Kubernetes startup
	}
	
	// Auto Migrate the schema
	db.AutoMigrate(&Ticket{})
}

func bookTicket(c *gin.Context) {
	var req struct {
		EventName string `json:"event_name"`
		UserID    string `json:"user_id"`
	}

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	log.Infof("Received booking request for event: %s by user: %s", req.EventName, req.UserID)

	// SIMULATE PROCESSING DELAY (The "Heavy Logic")
	// This helps us test Autoscaling later
	time.Sleep(2 * time.Second)

	// Database Transaction
	tx := db.Begin()

	// Find an available ticket
	var ticket Ticket
	result := tx.Where("event_name = ? AND status = ?", req.EventName, "AVAILABLE").First(&ticket)

	if result.Error != nil {
		tx.Rollback()
		log.Error("No tickets available")
		c.JSON(http.StatusConflict, gin.H{"error": "Sold out!"})
		return
	}

	// Update ticket status
	ticket.Status = "SOLD"
	ticket.OwnerID = req.UserID
	tx.Save(&ticket)
	tx.Commit()

	log.Infof("Ticket %d sold to %s", ticket.ID, req.UserID)
	c.JSON(http.StatusOK, gin.H{"message": "Booking confirmed!", "ticket_id": ticket.ID})
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "healthy"})
}

func main() {
	// Initialize JSON logging
	log.SetFormatter(&logrus.JSONFormatter{})
	
	// Initialize DB
	go initDB() // Run in background so app starts even if DB is slow

	r := gin.Default()
	
	// Routes
	r.GET("/health", healthCheck)
	r.POST("/book", bookTicket)

	// Start Server
	log.Info("Booking Service starting on :8080")
	r.Run(":8080")
}
