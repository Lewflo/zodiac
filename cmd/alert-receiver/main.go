package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

// GrafanaAlert represents the payload sent by Grafana Webhooks
type GrafanaAlert struct {
	Receiver          string            `json:"receiver"`
	Status            string            `json:"status"`
	Alerts            []Alert           `json:"alerts"`
	GroupLabels       map[string]string `json:"groupLabels"`
	CommonLabels      map[string]string `json:"commonLabels"`
	CommonAnnotations map[string]string `json:"commonAnnotations"`
	ExternalURL       string            `json:"externalURL"`
}

type Alert struct {
	Status       string            `json:"status"`
	Labels       map[string]string `json:"labels"`
	Annotations  map[string]string `json:"annotations"`
	StartsAt     time.Time         `json:"startsAt"`
	EndsAt       time.Time         `json:"endsAt"`
	GeneratorURL string            `json:"generatorURL"`
	Fingerprint  string            `json:"fingerprint"`
}

func alertHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error reading body: %v", err)
		http.Error(w, "Can't read body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var alertPayload GrafanaAlert
	if err := json.Unmarshal(body, &alertPayload); err != nil {
		log.Printf("Error unmarshaling JSON: %v", err)
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	log.Printf("Received Webhook from Grafana! Status: %s", alertPayload.Status)
	
	for i, alert := range alertPayload.Alerts {
		log.Printf("--- Alert %d ---", i+1)
		log.Printf("Status: %s", alert.Status)
		log.Printf("Summary: %s", alert.Annotations["summary"])
		log.Printf("Description: %s", alert.Annotations["description"])
		log.Printf("Labels: %v", alert.Labels)
		log.Printf("Started at: %s", alert.StartsAt.Format(time.RFC3339))
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Alert received successfully")
}

func main() {
	port := "9091"
	
	http.HandleFunc("/alert", alertHandler)
	
	log.Printf("Starting Zodiac Alert Webhook Receiver on port %s...", port)
	log.Printf("Configure Grafana to send POST requests to http://<your-ip>:%s/alert", port)
	
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}
