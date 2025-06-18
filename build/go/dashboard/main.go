package main

import (
	"fmt"
	"io/ioutil"
	"strings"
	"path/filepath"
	"io"
	"os"
	"regexp"
	"syscall"
	"time"
)

const TrustedDomainsTemplate = "/nginx/var/OidcTrustedDomains.js.tmpl"
const TrustedDomains = "/nginx/var/OidcTrustedDomains.js"

func logInfo(s string){
	log(os.Stdout, fmt.Sprintf("INFO %s", s))
}

func logError(s string){
	log(os.Stderr, fmt.Sprintf("ERROR %s", s))
}

func log(r io.Writer, s string) {
	fmt.Fprintf(r, "%s %s\n", time.Now().Format(time.RFC3339), s)
}

func main() {
	// find all the files that contain AUTH_SUPPORTED_SCOPES
	err := filepath.Walk("/nginx/var",
		func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		text, _ := ioutil.ReadFile(path)
		if strings.Contains(string(text), "AUTH_SUPPORTED_SCOPES") {
			replaceEnv(path, string(text))
		}		
		return nil
	})
	if err != nil {
		logError(fmt.Sprintf("filepath.Walk(\"/nginx/var\"): %s", err))
		os.Exit(1)
	}

	// replace custom files
	custom := []string{TrustedDomainsTemplate}
	for _, path := range custom {
		text, _ := ioutil.ReadFile(path)
		replaceEnv(path, string(text))
	}

	// rename tmpl
	os.Rename(TrustedDomainsTemplate, TrustedDomains)

	logInfo("starting dashboard")
	if err = syscall.Exec("/usr/local/bin/nginx", []string{}, os.Environ()); err != nil {
		os.Exit(1)
	}
}

func replaceEnv(path string, text string){
	nextjs := []string{"USE_AUTH0", "AUTH_AUDIENCE", "AUTH_AUTHORITY", "AUTH_CLIENT_ID", "AUTH_CLIENT_SECRET", "AUTH_SUPPORTED_SCOPES", "NETBIRD_MGMT_API_ENDPOINT", "NETBIRD_MGMT_GRPC_API_ENDPOINT", "NETBIRD_HOTJAR_TRACK_ID", "NETBIRD_GOOGLE_ANALYTICS_ID", "NETBIRD_GOOGLE_TAG_MANAGER_ID", "AUTH_REDIRECT_URI", "AUTH_SILENT_REDIRECT_URI", "NETBIRD_TOKEN_SOURCE", "NETBIRD_DRAG_QUERY_PARAMS"}

	// replace all environment variables in file
	for _, e := range os.Environ() {
		key := strings.Split(e, "=")[0]
		value := os.Getenv(key)
		text = string(regexp.MustCompile(fmt.Sprintf(`\$%s`, key)).ReplaceAllString(text, value))
	}

	// replace all not set environment variables in file
	for _, e := range nextjs {
		text = string(regexp.MustCompile(fmt.Sprintf(`\$%s`, e)).ReplaceAllString(text, ""))
	}

	err := ioutil.WriteFile(path, []byte(text), os.ModePerm)
	if err != nil {
		logError(fmt.Sprintf("ioutil.WriteFile(%s): %s", path, err))
		os.Exit(3)
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}