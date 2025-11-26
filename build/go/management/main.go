package main

import (
	"fmt"
	"io/ioutil"
	"strings"
	"os"
	"regexp"
	"syscall"
)

func main() {
	custom := []string{"/netbird/etc/management.json"}
	for _, path := range custom {
		text, _ := ioutil.ReadFile(path)
		replaceEnv(path, string(text))
	}
	if err := syscall.Exec("/usr/local/bin/netbird", []string{"management", "management", "--config", "/netbird/etc/management.json", "--log-file", "console", "--log-level", "info", "--disable-anonymous-metrics", "--disable-geolite-update", "--dns-domain", getEnv("NETBIRD_MGMT_DNS_DOMAIN", "netbird.selfhosted")}, os.Environ()); err != nil {
		os.Exit(1)
	}
}

func replaceEnv(path string, text string){
	// replace all environment variables in file
	for _, e := range os.Environ() {
		key := strings.Split(e, "=")[0]
		value := os.Getenv(key)
		text = string(regexp.MustCompile(fmt.Sprintf(`\${%s}`, key)).ReplaceAllString(text, value))
	}

	// replace all not set environment variables in file
	uenv := regexp.MustCompile(`\$\{[A-Z_a-z]+\}`).FindAllString(text, -1)
	for _, e := range uenv {
		fmt.Printf("variable %s not set, will be set to empty string!\n", e)
		text = string(regexp.MustCompile(fmt.Sprintf(`%s`, e)).ReplaceAllString(text, ""))
	}

	err := ioutil.WriteFile(path, []byte(text), os.ModePerm)
	if err != nil {
		os.Exit(3)
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}