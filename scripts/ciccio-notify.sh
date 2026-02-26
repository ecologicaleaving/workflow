#!/bin/bash
# ciccio-notify — invia un messaggio Telegram via OpenClaw gateway
# Installazione VPS: cp ciccio-notify.sh /usr/local/bin/ciccio-notify && chmod +x /usr/local/bin/ciccio-notify
#
# Usage: ciccio-notify "messaggio con \n per newline"

MSG="$1"
GATEWAY_TOKEN="${CICCIO_GATEWAY_TOKEN:-4776fd6a1aa8a14e006172b5da082a9994e29ea9fd936a2a}"
GATEWAY_URL="${CICCIO_GATEWAY_URL:-http://127.0.0.1:18789}"
TELEGRAM_TARGET="${CICCIO_TELEGRAM_TARGET:-1634377998}"

curl -s -X POST "${GATEWAY_URL}/tools/invoke" \
  -H "Authorization: Bearer ${GATEWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "{\"tool\":\"message\",\"args\":{\"action\":\"send\",\"channel\":\"telegram\",\"target\":\"${TELEGRAM_TARGET}\",\"message\":\"${MSG}\"}}" \
  > /dev/null 2>&1
