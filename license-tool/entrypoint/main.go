package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

const authURL = "https://identity.vertigisstudio.com/authorize" +
	"?client_id=pTmBlZldlUaNrhFn" +
	"&redirect_uri=http%3A%2F%2Flocalhost%3A7780%2Fa5510196-002b-4e2e-ba4e-8fdb91ee5287%2Fonline-activate" +
	"&response_mode=form_post" +
	"&activate=no_grant"

func main() {
	done := make(chan struct{})

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			http.Redirect(w, r, authURL, http.StatusFound)
			return
		}

		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		if err := r.ParseForm(); err != nil {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		id := r.FormValue("id")
		idURL := r.FormValue("idUrl")

		if id == "" || idURL == "" {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		resp, err := http.Get(idURL + "?id=" + id)
		if err != nil {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		var result map[string]interface{}
		if err := json.Unmarshal(body, &result); err != nil {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		accountID, ok := result["accountId"].(string)
		if !ok || accountID == "" {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		fmt.Println("VertiGIS Account ID:", accountID)
		w.WriteHeader(http.StatusOK)

		go func() { close(done) }()
	})

	server := &http.Server{Addr: ":7780", Handler: mux}

	go func() {
		<-done
		server.Close()
	}()

	fmt.Println("Please visit: http://localhost:7780/")
	os.Stdout.Sync()

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		fmt.Fprintln(os.Stderr, "server error:", err)
		os.Exit(1)
	}
}
