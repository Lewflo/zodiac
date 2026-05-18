#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MONITORING_DIR="${PROJECT_DIR}/monitoring"

compose() {
  if docker ps >/dev/null 2>&1; then
    docker compose "$@"
  else
    sudo docker compose "$@"
  fi
}

cd "${MONITORING_DIR}"

echo "[1/3] Validating Docker Compose configuration"
compose config >/dev/null

echo "[2/3] Starting monitoring stack"
compose up -d

echo "[3/3] Current container status"
compose ps

cat <<'EOF'

Monitoring URLs:
  SNMP Exporter: http://192.168.10.100:9116
  Prometheus:    http://192.168.10.100:9090
  Grafana:       http://192.168.10.100:3000

Grafana login:
  username: admin
  password: admin

EOF
