#!/usr/bin/env bash
#
# create.sh — call the personal create.sleet.near API to create a new NEAR account.
#
# Usage:
#   ./scripts/create.sh <api_url> <new_account_id> [new_public_key]
#
# Env overrides:
#   SLEET_API_URL         base URL of the sleet-api service (skips argv[1])
#   SLEET_DEFAULT_PUBKEY  default ed25519 public key (skips argv[3])
#
# Examples:
#   ./scripts/create.sh https://create.sleet.example.com alice.near
#   ./scripts/create.sh https://create.sleet.example.com alice.near ed25519:OTHER_KEY
#   SLEET_API_URL=https://create.sleet.example.com ./scripts/create.sh "" alice.near
#
# Exit codes:
#   0   success
#   64  usage error
#   22  HTTP / network error
#   1   API returned ok:false

set -euo pipefail

DEFAULT_PUBKEY_FALLBACK="ed25519:6rPrBb6vpVHEVcwsCQPAKBmPvPPsREsbEvnQZtHRFL4"

# -------- args --------
API_URL="${1:-${SLEET_API_URL:-}}"
NEW_ACCOUNT_ID="${2:-}"
NEW_PUBKEY="${3:-${SLEET_DEFAULT_PUBKEY:-$DEFAULT_PUBKEY_FALLBACK}}"

if [[ -z "$API_URL" ]]; then
  echo "Usage: $0 <api_url> <new_account_id> [new_public_key]" >&2
  echo "  api_url:          base URL of the sleet-api service (e.g. http://localhost:3000)" >&2
  echo "  new_account_id:   account to create, e.g. alice.near or alice.testnet" >&2
  echo "  new_public_key:   ed25519:... full-access key (default: sleet's key baked into this skill)" >&2
  echo "" >&2
  echo "Or set SLEET_API_URL and/or SLEET_DEFAULT_PUBKEY in the environment." >&2
  exit 64
fi

if [[ -z "$NEW_ACCOUNT_ID" ]]; then
  echo "Error: new_account_id is required" >&2
  exit 64
fi

# strip trailing slash from api_url so we don't end up with //create
API_URL="${API_URL%/}"
URL="${API_URL}/create"

# -------- pre-flight sanity checks (mirror what the server does) --------
if [[ ! "$NEW_ACCOUNT_ID" =~ ^[a-z0-9][a-z0-9_-]{1,63}\.(near|testnet)$ ]]; then
  echo "Warning: new_account_id '$NEW_ACCOUNT_ID' does not match the expected 'name.near|name.testnet' pattern. The server will reject it if malformed." >&2
fi

if [[ ! "$NEW_PUBKEY" =~ ^ed25519: ]]; then
  echo "Error: new_public_key must start with 'ed25519:' (got: $NEW_PUBKEY)" >&2
  exit 64
fi

# -------- call --------
# --fail:      surface non-2xx as a curl error (exit 22)
# --silent:    no progress meter
# --show-error: real error messages on stderr
HTTP_CODE=$(curl --fail --silent --show-error \
  --output /tmp/sleet_create_response.$$ \
  --write-out '%{http_code}' \
  -X POST \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg id "$NEW_ACCOUNT_ID" --arg pk "$NEW_PUBKEY" \
        '{new_account_id:$id, new_public_key:$pk}')" \
  "$URL") || {
    echo "HTTP request failed (curl exit $?)" >&2
    [[ -f /tmp/sleet_create_response.$$ ]] && cat /tmp/sleet_create_response.$$ >&2 && echo >&2
    rm -f /tmp/sleet_create_response.$$
    exit 22
  }

BODY=$(cat /tmp/sleet_create_response.$$)
rm -f /tmp/sleet_create_response.$$

# Pretty-print and check ok flag
echo "$BODY" | jq . >&2  # full payload to stderr so the agent can read it

if [[ "$HTTP_CODE" != "200" ]] || [[ "$(echo "$BODY" | jq -r '.ok // false')" != "true" ]]; then
  ERR=$(echo "$BODY" | jq -r '.error // "unknown error"')
  echo "API returned error: $ERR" >&2
  exit 1
fi

# Extract the result on stdout for easy piping
echo "$BODY" | jq -c '.result'
exit 0