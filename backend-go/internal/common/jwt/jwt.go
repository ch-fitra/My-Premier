package jwt

import (
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte

// Claims represents the JWT token claims
type Claims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// Init initializes the JWT secret from environment variable
func Init() error {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return errors.New("JWT_SECRET environment variable is not set")
	}
	jwtSecret = []byte(secret)
	return nil
}

// GenerateToken generates a JWT token for a user
func GenerateToken(userID, email, role string) (string, error) {
	if jwtSecret == nil {
		if err := Init(); err != nil {
			return "", err
		}
	}

	claims := Claims{
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID, // Standard JWT "sub" claim
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "mypremier-backend",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// ValidateToken validates a JWT token and returns the claims
func ValidateToken(tokenString string) (*Claims, error) {
	if jwtSecret == nil {
		if err := Init(); err != nil {
			return nil, err
		}
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Explicitly check for HS256 signing method
		if token.Method != jwt.SigningMethodHS256 {
			return nil, errors.New("invalid signing method: expected HS256")
		}
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

