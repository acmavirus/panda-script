package ssl

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

const (
	CertbotLivePath = "/etc/letsencrypt/live"
)

type CertificateInfo struct {
	Domain    string    `json:"domain"`
	Issuer    string    `json:"issuer"`
	ExpiresAt time.Time `json:"expires_at"`
	DaysLeft  int       `json:"days_left"`
	Path      string    `json:"path"`
	IsValid   bool      `json:"is_valid"`
}

func getCertPath() string {
	if runtime.GOOS == "windows" {
		return "certs"
	}
	return CertbotLivePath
}

func checkLinux() error {
	if runtime.GOOS == "windows" {
		return fmt.Errorf("SSL management requires Linux with certbot installed")
	}
	return nil
}

// InstallCertbot installs certbot if not present
func InstallCertbot() error {
	if err := checkLinux(); err != nil {
		return err
	}

	// Check if certbot is already installed
	if _, err := system.Execute("which certbot"); err == nil {
		return nil // Already installed
	}

	// Detect package manager and install
	if _, err := system.Execute("which apt-get"); err == nil {
		_, err := system.Execute("apt-get install -y certbot python3-certbot-nginx")
		return err
	}

	if _, err := system.Execute("which dnf"); err == nil {
		_, err := system.Execute("dnf install -y certbot python3-certbot-nginx")
		return err
	}

	return fmt.Errorf("unable to install certbot: unsupported package manager")
}

// ObtainCertificate obtains a new SSL certificate from Let's Encrypt
func ObtainCertificate(domain, email string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	if err := InstallCertbot(); err != nil {
		return fmt.Errorf("failed to install certbot: %v", err)
	}

	if email == "" {
		email = "admin@" + domain
	}

	cmd := fmt.Sprintf("certbot --nginx -d %s -d www.%s --non-interactive --agree-tos --email %s --redirect",
		domain, domain, email)

	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to obtain certificate: %v", err)
	}

	// Setup auto-renewal cron
	SetupAutoRenew()

	return nil
}

// RenewCertificate renews a specific certificate
func RenewCertificate(domain string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	cmd := fmt.Sprintf("certbot renew --cert-name %s --quiet", domain)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to renew certificate: %v", err)
	}

	return nil
}

// RenewAll renews all certificates that are due
func RenewAll() error {
	if err := checkLinux(); err != nil {
		return err
	}

	if _, err := system.Execute("certbot renew --quiet"); err != nil {
		return fmt.Errorf("failed to renew certificates: %v", err)
	}

	return nil
}

// CheckExpiry checks the expiry date of a certificate
func CheckExpiry(domain string) (*CertificateInfo, error) {
	certPath := filepath.Join(getCertPath(), domain, "cert.pem")

	if runtime.GOOS == "windows" {
		// Return mock data for Windows
		return &CertificateInfo{
			Domain:    domain,
			Issuer:    "Mock Issuer (Windows)",
			ExpiresAt: time.Now().AddDate(0, 3, 0),
			DaysLeft:  90,
			Path:      certPath,
			IsValid:   true,
		}, nil
	}

	certPEM, err := os.ReadFile(certPath)
	if err != nil {
		return nil, fmt.Errorf("certificate not found for %s", domain)
	}

	block, _ := pem.Decode(certPEM)
	if block == nil {
		return nil, fmt.Errorf("failed to parse certificate PEM")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse certificate: %v", err)
	}

	daysLeft := int(time.Until(cert.NotAfter).Hours() / 24)

	return &CertificateInfo{
		Domain:    domain,
		Issuer:    cert.Issuer.CommonName,
		ExpiresAt: cert.NotAfter,
		DaysLeft:  daysLeft,
		Path:      filepath.Join(getCertPath(), domain),
		IsValid:   time.Now().Before(cert.NotAfter),
	}, nil
}

// ListCertificates lists all SSL certificates
func ListCertificates() ([]CertificateInfo, error) {
	certPath := getCertPath()

	if runtime.GOOS == "windows" {
		os.MkdirAll(certPath, 0755)
		return []CertificateInfo{}, nil
	}

	// Use certbot to list certificates
	out, err := system.Execute("certbot certificates 2>/dev/null")
	if err != nil {
		// Try to read from directory if certbot fails
		return listCertsFromDir()
	}

	var certs []CertificateInfo
	lines := strings.Split(out, "\n")
	var currentDomain string

	for _, line := range lines {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "Certificate Name:") {
			currentDomain = strings.TrimPrefix(line, "Certificate Name:")
			currentDomain = strings.TrimSpace(currentDomain)
		}

		if strings.HasPrefix(line, "Expiry Date:") && currentDomain != "" {
			// Parse expiry info
			info, err := CheckExpiry(currentDomain)
			if err == nil {
				certs = append(certs, *info)
			}
			currentDomain = ""
		}
	}

	return certs, nil
}

func listCertsFromDir() ([]CertificateInfo, error) {
	certPath := getCertPath()

	entries, err := os.ReadDir(certPath)
	if err != nil {
		return []CertificateInfo{}, nil
	}

	var certs []CertificateInfo
	for _, entry := range entries {
		if entry.IsDir() {
			info, err := CheckExpiry(entry.Name())
			if err == nil {
				certs = append(certs, *info)
			}
		}
	}

	return certs, nil
}

// RevokeCertificate revokes and deletes a certificate
func RevokeCertificate(domain string) error {
	if err := checkLinux(); err != nil {
		return err
	}

	// Revoke
	cmd := fmt.Sprintf("certbot revoke --cert-name %s --non-interactive", domain)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to revoke certificate: %v", err)
	}

	// Delete
	cmd = fmt.Sprintf("certbot delete --cert-name %s --non-interactive", domain)
	if _, err := system.Execute(cmd); err != nil {
		return fmt.Errorf("failed to delete certificate: %v", err)
	}

	return nil
}

// SetupAutoRenew configures automatic certificate renewal
func SetupAutoRenew() error {
	if err := checkLinux(); err != nil {
		return err
	}

	// Add cron job for auto-renewal
	cronCmd := "0 3 * * * /usr/bin/certbot renew --quiet"
	cmd := fmt.Sprintf("(crontab -l 2>/dev/null | grep -v certbot; echo '%s') | crontab -", cronCmd)
	_, err := system.Execute(cmd)
	return err
}

// TestCertificate tests if a domain has a valid SSL certificate
func TestCertificate(domain string) (bool, error) {
	info, err := CheckExpiry(domain)
	if err != nil {
		return false, err
	}
	return info.IsValid && info.DaysLeft > 0, nil
}
