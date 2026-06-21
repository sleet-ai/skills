#!/usr/bin/env bash
#
# top100.sh — fetch the top 100 holders of a fungible token on NEAR
# via the FastNear API, and re-emit the response with 1-based ranks.
#
# Usage:
#   ./scripts/top100.sh <token-contract-account.near>
#
# Example:
#   ./scripts/top100.sh token.pumpopoly.near
#
# Exit codes:
#   0  success
#   64 usage error (no argument)
#   22 HTTP / network error (curl non-2xx)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <token-contract-account.near>" >&2
  echo "Example: $0 token.pumpopoly.near" >&2
  exit 64
fi

TOKEN_CA="$1"
URL="https://api.fastnear.com/v1/ft/${TOKEN_CA}/top"

# --fail: surface non-2xx as an error instead of silently printing HTML
# --silent --show-error: clean stderr, real error messages
curl --fail --silent --show-error "$URL" \
  | jq '{
      token_id: .token_id,
      count:    (.accounts | length),
      holders: (
        .accounts
        | to_entries
        | map({
            rank:    (.key + 1),
            account: .value.account_id,
            balance: .value.balance
          })
      )
    }'
