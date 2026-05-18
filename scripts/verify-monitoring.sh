#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] SNMP Exporter direct scrape"
curl -fsS "http://localhost:9116/snmp?target=192.168.10.10&module=if_mib&auth=public_v2" | sed -n '1,12p'

echo
echo "[2/5] Prometheus readiness"
curl -fsS "http://localhost:9090/-/ready"

echo
echo "[3/5] Prometheus SNMP target values"
curl -fsS "http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22snmp-cisco-ios%22%7D"

echo
echo "[4/5] Grafana health"
curl -fsS "http://localhost:3000/api/health"

echo
echo "[5/5] Grafana Cisco dashboard lookup"
curl -fsS -u admin:admin "http://localhost:3000/api/search?query=Cisco"
echo
