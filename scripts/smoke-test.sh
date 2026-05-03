#!/usr/bin/env bash
set -uo pipefail

# CDN Simulator Post-Boot Smoke Test Suite
# Deterministic validation of all components after deployment or reboot.
# Usage: ./smoke-test.sh <public-ip> [--ssh]
#   Default:  HTTP-only tests (application endpoints via curl)
#   --ssh:    additionally runs SSH infrastructure tests (requires SSH key)
# Exit codes: 0 = all pass, 1 = failures detected

IP="${1:?Usage: $0 <public-ip> [--ssh]}"
SSH_MODE=false
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
  --ssh) SSH_MODE=true ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
  shift
done

BASE="http://${IP}"
PASS=0
FAIL=0
RESULTS=()

check() {
  local name="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    RESULTS+=("PASS  $name")
    PASS=$((PASS + 1))
  else
    RESULTS+=("FAIL  $name (expected=$expected got=$actual)")
    FAIL=$((FAIL + 1))
  fi
}

check_contains() {
  local name="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    RESULTS+=("PASS  $name")
    PASS=$((PASS + 1))
  else
    RESULTS+=("FAIL  $name (missing: $needle)")
    FAIL=$((FAIL + 1))
  fi
}

check_gte() {
  local name="$1" minimum="$2" actual="$3"
  if [ "$actual" -ge "$minimum" ] 2>/dev/null; then
    RESULTS+=("PASS  $name (value=$actual)")
    PASS=$((PASS + 1))
  else
    RESULTS+=("FAIL  $name (expected>=$minimum got=$actual)")
    FAIL=$((FAIL + 1))
  fi
}

ssh_cmd() {
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "azureuser@${IP}" "$@" 2>/dev/null
}

echo "============================================"
echo "  CDN Simulator Smoke Test Suite"
echo "  Target: ${BASE}"
echo "  Mode:   $(if $SSH_MODE; then echo 'Full (HTTP + SSH)'; else echo 'HTTP-only'; fi)"
echo "  Time:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"
echo ""

# ── 1. Health Endpoint ──────────────────────────────

echo "── Health Endpoint ──"

HEALTH=$(curl -sf --max-time 10 "${BASE}/health" 2>/dev/null || echo "UNREACHABLE")
check "health-endpoint-reachable" "true" "$([ "$HEALTH" != "UNREACHABLE" ] && echo true || echo false)"
check_contains "health-status-healthy" '"status":"healthy"' "$HEALTH"
check_contains "health-component-cdn-edge" '"component":"cdn-edge"' "$HEALTH"

# ── 2. Vendor Profiles ───────────────────────────────

echo "── Vendor Profiles ──"

check_contains "health-vendor-akamai" '"akamai"' "$HEALTH"
check_contains "health-vendor-cloudflare" '"cloudflare"' "$HEALTH"
check_contains "health-vendor-cloudfront" '"cloudfront"' "$HEALTH"
check_contains "health-vendor-fastly" '"fastly"' "$HEALTH"
check_contains "health-vendor-azure-front-door" '"azure-front-door"' "$HEALTH"

# ── 3. Response Headers ──────────────────────────────

echo "── Response Headers ──"

HEADERS=$(curl -s --max-time 10 -I "${BASE}/" 2>/dev/null || echo "")

check_contains "header-x-cache-status" "X-Cache-Status" "$HEADERS"
check_contains "header-x-cdn-edge" "X-CDN-Edge" "$HEADERS"
check_contains "header-x-cdn-pop" "X-CDN-POP" "$HEADERS"
check_contains "header-x-served-by" "X-Served-By" "$HEADERS"
check_contains "header-x-request-id" "X-Request-ID" "$HEADERS"

CDN_EDGE_VAL=$(echo "$HEADERS" | grep -i "X-CDN-Edge:" | tr -d '\r' | awk '{print $2}')
check "header-x-cdn-edge-value" "cdn-simulator" "$CDN_EDGE_VAL"

# ── 4. Cache Pipeline ────────────────────────────────

echo "── Cache Pipeline ──"

CACHE_URL="${BASE}/cache-test-$(date +%s)"
CACHE1_HEADERS=$(curl -sf --max-time 10 -I "$CACHE_URL" 2>/dev/null || echo "")
check_contains "cache-first-request-has-status" "X-Cache-Status" "$CACHE1_HEADERS"

CACHE2_HEADERS=$(curl -sf --max-time 10 -I "$CACHE_URL" 2>/dev/null || echo "")
check_contains "cache-second-request-has-status" "X-Cache-Status" "$CACHE2_HEADERS"

# ── 5. Infrastructure (SSH) ──────────────────────────

if $SSH_MODE; then
  echo ""
  echo "── Infrastructure (SSH) ──"

  NGINX_ACTIVE=$(ssh_cmd "systemctl is-active nginx" || echo "unknown")
  check "ssh-nginx-active" "active" "$NGINX_ACTIVE"

  NGINX_TEST=$(ssh_cmd "sudo nginx -t 2>&1 && echo VALID || echo INVALID")
  check_contains "ssh-nginx-config-valid" "VALID" "$NGINX_TEST"

  IRQ_ACTIVE=$(ssh_cmd "systemctl is-active irqbalance" || echo "unknown")
  check "ssh-irqbalance-active" "active" "$IRQ_ACTIVE"

  PROGRESS_EXISTS=$(ssh_cmd "test -f /var/log/cloud-init-progress.log && echo yes || echo no")
  check "ssh-progress-log-exists" "yes" "$PROGRESS_EXISTS"

  PROGRESS_LOG=$(ssh_cmd "cat /var/log/cloud-init-progress.log 2>/dev/null" || echo "")
  check_contains "ssh-progress-log-init-phase" '\[init\]' "$PROGRESS_LOG"
  check_contains "ssh-progress-log-complete-phase" '\[complete\]' "$PROGRESS_LOG"

  SOMAXCONN=$(ssh_cmd "sysctl -n net.core.somaxconn" || echo "0")
  check_gte "ssh-sysctl-somaxconn" 262144 "$SOMAXCONN"

  TCP_REUSE=$(ssh_cmd "sysctl -n net.ipv4.tcp_tw_reuse" || echo "0")
  check "ssh-sysctl-tcp-tw-reuse" "1" "$TCP_REUSE"

  WORKER_CONNS=$(ssh_cmd "grep -oP 'worker_connections\s+\K[0-9]+' /etc/nginx/nginx.conf 2>/dev/null | head -1" || echo "0")
  check_gte "ssh-nginx-worker-connections" 32768 "$WORKER_CONNS"
fi

# ── Results ────────────────────────────────────────

echo ""
echo "============================================"
echo "  RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "SMOKE TEST: FAILED"
  exit 1
else
  echo "SMOKE TEST: PASSED"
  exit 0
fi
