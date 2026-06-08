package main

import (
	"bytes"
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"
)

func main() {
	dir := "/usr/local/share/ca-certificates"
	if len(os.Args) > 1 {
		dir = os.Args[1]
	}

	os.MkdirAll(dir, 0755)

	if err := os.Chdir(dir); err != nil {
		fmt.Fprintf(os.Stderr, "chdir failed: %v\n", err)
		os.Exit(1)
	}

	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reading stdin failed: %v\n", err)
		os.Exit(1)
	}

	rest := data
	for {
		block, remaining := pem.Decode(rest)
		if block == nil {
			break
		}

		rest = remaining

		if block.Type != "CERTIFICATE" {
			continue
		}

		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			continue
		}

		if !isRootCA(cert) {
			continue
		}

		name := makeCertFileName(cert)
		data := pem.EncodeToMemory(block)

		err = os.WriteFile(name, data, 0644)
		if err != nil {
			fmt.Fprintf(os.Stderr, "creating %s failed: %v\n", name, err)
			os.Exit(1)
		}
	}
}

func isRootCA(cert *x509.Certificate) bool {
	if !cert.IsCA {
		return false
	}

	if !bytes.Equal(cert.RawSubject, cert.RawIssuer) {
		return false
	}

	if cert.CheckSignatureFrom(cert) != nil {
		return false
	}

	return true
}

func makeCertFileName(cert *x509.Certificate) string {
	datePart := cert.NotBefore.UTC().Format("20060102")
	sum := sha256.Sum256(cert.Raw)
	hashPart := strings.ToUpper(hex.EncodeToString(sum[:4]))
	subjectPart := sanitizeSubject(cert.Subject.String())

	if subjectPart == "" {
		subjectPart = "UNKNOWN"
	}

	return fmt.Sprintf("ca-cert-%s-%s-%s.crt", datePart, hashPart, subjectPart)
}

var niceRE = regexp.MustCompile(`[A-Z]+=`)
var nicerRE = regexp.MustCompile(`[^A-Z0-9]+`)

func sanitizeSubject(s string) string {
	s = strings.ToUpper(s)
	s = niceRE.ReplaceAllString(s, "")
	s = nicerRE.ReplaceAllString(s, "-")
	s = strings.Trim(s, "-")
	if s == "" {
		return "UNKNOWN"
	}

	return s
}
