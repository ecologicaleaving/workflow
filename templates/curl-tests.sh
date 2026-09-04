#!/bin/bash
# Smoke tests — curl-based API verification
# Uso: ./tests/curl-tests.sh [BASE_URL]
# Default: https://test-<repo>.8020solutions.org

BASE_URL="${1:-https://test-REPO.8020solutions.org}"
PASS=0
FAIL=0

check() {
  local desc="$1" url="$2" expected="$3"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" = "$expected" ]; then
    echo "✅ $desc (HTTP $status)"
    ((PASS++))
  else
    echo "❌ $desc — expected $expected, got $status"
    ((FAIL++))
  fi
}

# --- Test ---
check "Homepage loads" "$BASE_URL/" "200"
check "API senza auth → 401" "$BASE_URL/api/events" "401"
check "Login redirect" "$BASE_URL/auth/login" "200"

echo ""
echo "=== Risultati: $PASS passed, $FAIL failed ==="
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
