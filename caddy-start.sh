#!/bin/sh

set -e

# --- 1. Start Caddy in the background (or foreground with basic config) ---

# This starts Caddy using the initial Caddyfile, allowing the Admin API (port 2019) to become available.
# We must use the original Caddy CMD but execute it in the background (&).
echo "Starting Caddy server..."
# Using the original command from the Dockerfile's CMD
/usr/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Get the PID of the background Caddy process
CADDY_PID=$!

# --- 2. Wait for the Admin API to become ready ---

echo "Waiting for Caddy Admin API (localhost:2019)..."
API_ENDPOINT="http://localhost:2019/load"
CADDYFILE_PATH="/etc/caddy/Caddyfile"
MAX_ATTEMPTS=15

for i in $(seq 1 $MAX_ATTEMPTS); do
  if curl --fail -s -o /dev/null "$API_ENDPOINT"; then
    echo "Caddy Admin API is ready."
    break
  fi
  echo "Attempt $i of $MAX_ATTEMPTS: API not ready, waiting..."
  sleep 1
done

if [ $i -ge $MAX_ATTEMPTS ]; then
  echo "Error: Caddy Admin API failed to become available. Exiting."
  kill $CADDY_PID
  exit 1
fi

# --- 3. Perform the Reload via Admin API ---

echo "Attempting to reload Caddyfile via Admin API..."

# The API call: POST the Caddyfile content with the Caddyfile Content-Type
RESPONSE=$(curl -X POST \
  -H "Content-Type: text/caddyfile" \
  --data-binary "@$CADDYFILE_PATH" \
  "$API_ENDPOINT" 2>&1) # Redirect stderr to stdout for capture

CURL_STATUS=$?

if [ $CURL_STATUS -eq 0 ]; then
  echo "API Reload successful (New config applied)."
else
  echo "API Reload FAILED! Status: $CURL_STATUS"
  echo "Caddy API Response/Error: $RESPONSE"
  # Don't exit 1 here, let the background process continue with the initial config
  # If the build/up was intended to fix a config, this will let the old config persist.
  echo "Continuing with the initially loaded Caddyfile."
fi

# --- 4. Keep the original Caddy process running ---

# Since the Caddy process is already running in the background,
# the script just needs to wait for it.
echo "Caddy is running with PID: $CADDY_PID. Holding terminal until exit."
wait $CADDY_PID