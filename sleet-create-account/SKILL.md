---
name: sleet-create-account
description: Create a new top-level NEAR account for sleet.near via the personal sleet-api service (POST /create). Use when the user wants a new NEAR account for themselves and they have a deployed instance of the sleet-api running somewhere (URL required). Personal use only — the default ed25519 public key in this skill is sleet's own key and should not be reused for other people.
compatibility: Requires `curl` and `jq`. The user must supply the API URL of a deployed `create.sleet.near` service (or set one up themselves — see "Setting up the API" below). Network (mainnet/testnet) is determined by the server's `env_networkId` env var, which also fixes the required TLD.
---

# Sleet Create Account (personal)

Thin wrapper around the personal `create.sleet.near` API. Sends a single `POST /create` to the deployed instance and reports the result.

> **Personal use only.** The default public key baked into this skill (`ed25519:6rPrBb6vpVHEVcwsCQPAKBmPvPPsREsbEvnQZtHRFL4`) is sleet's own key. Do not use it to create accounts for anyone else. If the user supplies a different key, use theirs instead.

## Inputs the agent must collect

1. **`new_account_id`** — the account to create. Format: `name.tld`
   - TLD must match the API server's network: `.near` for mainnet, `.testnet` for testnet.
   - `name` is 2-64 chars, lowercase `a-z`, `0-9`, `_` or `-`, starting with letter or digit.
   - Only top-level accounts are allowed (no subaccounts like `foo.bar.near`).
2. **`new_public_key`** — `ed25519:` public key to set as the account's full-access key.
   - Defaults to `ed25519:6rPrBb6vpVHEVcwsCQPAKBmPvPPsREsbEvnQZtHRFL4` (sleet's key) unless the user supplies a different one.
3. **`api_url`** — the base URL of the deployed sleet-api service, e.g. `http://localhost:3000` or `https://create.sleet.example.com`.
   - If unset, **ask the user** before calling. They may also want to set it up themselves (see below).

## Quick Run

A ready-to-use shell wrapper lives at [`scripts/create.sh`](scripts/create.sh):

```bash
# Defaults: uses the baked-in sleet public key
./scripts/create.sh https://create.sleet.example.com alice.near

# Custom public key
./scripts/create.sh https://create.sleet.example.com alice.near ed25519:OTHER_KEY

# Override via env (handy in shells)
export SLEET_API_URL=https://create.sleet.example.com
export SLEET_DEFAULT_PUBKEY=ed25519:6rPrBb6vpVHEVcwsCQPAKBmPvPPsREsbEvnQZtHRFL4
./scripts/create.sh "$SLEET_API_URL" alice.near
```

The script appends `/create` to the base URL, POSTs the JSON body, and prints the JSON response. On non-2xx it exits non-zero with the error body on stderr.

## Direct curl

```bash
curl --fail --silent --show-error \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"new_account_id":"alice.near","new_public_key":"ed25519:6rPrBb6vpVHEVcwsCQPAKBmPvPPsREsbEvnQZtHRFL4"}' \
  https://create.sleet.example.com/create
```

## API Reference

```
POST {api_url}/create
Content-Type: application/json

{
  "new_account_id":   "alice.near",     // or alice.testnet, depending on server network
  "new_public_key":   "ed25519:..."     // full-access public key for the new account
}
```

**Success (`200`):**
```json
{ "ok": true, "result": <server-defined> }
```

**Error (`400`):**
```json
{ "ok": false, "error": "Account already exists: alice.near" }
```

Validation rules the server enforces (mirrored here so the agent can pre-check):
- `new_account_id` must end with the configured TLD (`.near` or `.testnet`).
- Must be exactly `name.tld` — subaccounts are rejected.
- `name` matches `/^[a-z0-9][a-z0-9_-]{1,63}$/`.
- `new_public_key` must be a string starting with `ed25519:`.
- The account must not already exist on chain (the server checks via RPC first).

If the server rejects, surface the `error` string verbatim to the user.

## Setting up the API

If the user does not already have an instance running, point them at the source repo and the env file. Quick reminder:

```sh
# clone
git clone https://gitlab.com/sleet-dev/sleet-api/create.sleet.near.git
cd create.sleet.near

# env
cp .env.example .env
$EDITOR .env       # set env_networkId (testnet|mainnet), env_accountId, env_publicKey, env_privateKey
set -a; source .env; set +a

# run locally
bun install
bun run src/serve_create_bun.ts            # listens on $PORT or 3000

# or via docker (exposes host port 30301 -> container 3000)
docker compose -f docker/run/docker-compose.yml up -d --build
```

Once it's reachable, set `SLEET_API_URL` to its base URL and the skill is ready to use.

## Notes

- **Network mismatch.** The TLD in `new_account_id` must match the server's `env_networkId`. A `.near` account id sent to a testnet-configured server will be rejected with `TLD must be .testnet`. If the user seems confused, ask which network they want and which server they have.
- **Default key.** Only used when the user does not provide their own `ed25519:` key and does not explicitly opt out. The default key is sleet's — when the user wants an account for a different person, **ask for a key**, do not silently reuse the default.
- **Idempotency / retries.** The server pre-checks account existence, so a successful response implies a freshly created account. The API does not queue; a network failure between request and response leaves an ambiguous state — suggest the user check the account on a block explorer before retrying.
- **Rate limits.** None documented. Don't spam; one call per account.
- **Logging.** The server logs every request to stdout with timestamp, method, path, and final status. Useful when debugging from the server side.