#!/bin/bash

# Optional: specify nmap ports or flags, or default to top 1000 ports
NMAP_FLAGS=${1:--Pn -sS --top-ports 100}

# Check dependencies
for cmd in kubectl nmap; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "[ERROR] Required command '$cmd' not found. Please install it."
    exit 1
  fi
done

echo "[INFO] Fetching pod IPs from Kubernetes..."

# Get pod IPs where status is Running
POD_IPS=$(kubectl get pods -A -o jsonpath="{range .items[?(@.status.phase=='Running')]}{.status.podIP}{'\n'}{end}" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ -z "$POD_IPS" ]; then
  echo "[WARN] No running pods with valid IPs found."
  exit 0
fi

# Timestamped log file
LOG="nmap_k8s_pod_scan_$(date +%F_%T).log"
echo "[INFO] Starting Nmap scans... Output: $LOG"

for ip in $POD_IPS; do
  echo -e "\n[INFO] Scanning pod IP: $ip" | tee -a "$LOG"
  nmap $NMAP_FLAGS "$ip" | tee -a "$LOG"
done

echo -e "\n[INFO] Scan complete. Results saved to $LOG"
