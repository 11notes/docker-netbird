package main

import (
	"os"
	"path/filepath"
	"io/ioutil"
	"strings"
  "github.com/11notes/go-eleven"
)

// server settings
const APP_SERVER_CONFIG_ENV = "NETBIRD_CONFIG"
const APP_SERVER_CONFIG string = "/netbird/etc/default.yml"
const APP_SERVER_DEFAULT_ENCRYPTION_KEY string = "APP_SERVER_DEFAULT_ENCRYPTION_KEY"
const APP_SERVER_DEFAULT_AUTH_SECRET string = "APP_SERVER_DEFAULT_AUTH_SECRET"
const APP_SERVER_DEFAULT_SESSION_COOKIE_ENCRYPTION_KEY string = "APP_SERVER_DEFAULT_SESSION_COOKIE_ENCRYPTION_KEY"

// dashboard settings
const APP_DASHBOARD_TRUSTED_DOMAINS_TEMPLATE = "/nginx/var/OidcTrustedDomains.js.tmpl"
const APP_DASHBOARD_TRUSTED_DOMAINS = "/nginx/var/OidcTrustedDomains.js"

func main(){
	if(len(os.Args) > 1){
		args := os.Args[1:]
		switch args[0] {
			case "--dashboard":
				dashboard()

			default:
				server()
		}
	}else{
		server()
	}
}

func server(){
	// write env to file if set
	eleven.Container.EnvToFile(APP_SERVER_CONFIG_ENV, APP_SERVER_CONFIG)

	// replace all environment variables present in the file ${VAR} or $VAR
	eleven.Container.FileContentReplaceEnv(APP_SERVER_CONFIG)

	// replace default values with randomized values if using default config
  encryptionKey, err := eleven.Util.GenerateRandomBase64(32)
	authSecret, err := eleven.Util.GenerateRandomBase64(16)
	sessionCookieencryptionKey, err := eleven.Util.GenerateRandomBase64(32)
	_, err = eleven.Util.FileReplaceStrings(APP_SERVER_CONFIG, map[string]any{APP_SERVER_DEFAULT_ENCRYPTION_KEY:encryptionKey, APP_SERVER_DEFAULT_AUTH_SECRET:authSecret, APP_SERVER_DEFAULT_SESSION_COOKIE_ENCRYPTION_KEY:sessionCookieencryptionKey})
	if err != nil {
		eleven.LogFatal("could not replace default values!", err)
	}

	// start netbird
	eleven.Container.Run("/usr/local/bin", "netbird", []string{"--config", "/netbird/etc/default.yml"})
}

func dashboard(){
	// find all the files that contain AUTH_SUPPORTED_SCOPES and replace all environment variables in them
	err := filepath.Walk("/nginx/var",
		func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		text, _ := ioutil.ReadFile(path)
		if strings.Contains(string(text), "AUTH_SUPPORTED_SCOPES") {
			err := eleven.Container.FileContentReplaceEnv(path)
			if err != nil {
				eleven.LogFatal("could not setup file %s", path, err)
			}
		}
		return nil
	})
	if err != nil {
		eleven.LogFatal("could not start dasshboard!", err)
	}

	// replace all environment variables in a list of custom files
	custom := []string{APP_DASHBOARD_TRUSTED_DOMAINS_TEMPLATE}
	for _, path := range custom {
		err := eleven.Container.FileContentReplaceEnv(path)
		if err != nil {
			eleven.LogFatal("could not setup file %s", path, err)
		}
	}

	// rename tmpl if not already done
	if _, err := os.Stat(APP_DASHBOARD_TRUSTED_DOMAINS_TEMPLATE); !os.IsNotExist(err) {
		os.Rename(APP_DASHBOARD_TRUSTED_DOMAINS_TEMPLATE, APP_DASHBOARD_TRUSTED_DOMAINS)
	}

	// start nginx
	eleven.Container.Run("/usr/local/bin", "nginx", []string{})
}