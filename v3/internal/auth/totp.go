package auth

import (
	"crypto/rand"
	"encoding/base32"
	"fmt"
	"time"

	"github.com/pquerna/otp"
	"github.com/pquerna/otp/totp"
)

// GenerateTOTPSecret creates a new TOTP secret for a user
func GenerateTOTPSecret(username string) (*otp.Key, error) {
	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "Panda Panel",
		AccountName: username,
		Period:      30,
		SecretSize:  20,
		Digits:      otp.DigitsSix,
		Algorithm:   otp.AlgorithmSHA1,
	})
	if err != nil {
		return nil, err
	}
	return key, nil
}

// ValidateTOTP validates a TOTP code against a secret
func ValidateTOTP(secret, code string) bool {
	return totp.Validate(code, secret)
}

// GetTOTPQRCodeURL returns the URL for QR code generation
func GetTOTPQRCodeURL(key *otp.Key) string {
	return key.URL()
}

// GenerateRandomToken generates a secure random token
func GenerateRandomToken(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base32.StdEncoding.EncodeToString(bytes)[:length], nil
}

// GenerateLoginToken creates a one-time login token
func GenerateLoginToken() (string, time.Time, error) {
	token, err := GenerateRandomToken(32)
	if err != nil {
		return "", time.Time{}, err
	}
	expiresAt := time.Now().Add(5 * time.Minute)
	return token, expiresAt, nil
}

// GetQRCodeDataURL returns a data URL for the QR code image
func GetQRCodeDataURL(key *otp.Key) (string, error) {
	// The frontend will use a QR code library to generate from the URL
	return fmt.Sprintf("otpauth://totp/%s:%s?secret=%s&issuer=%s&algorithm=SHA1&digits=6&period=30",
		"Panda%20Panel", key.AccountName(), key.Secret(), "Panda%20Panel"), nil
}
