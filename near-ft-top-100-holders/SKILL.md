---
name: near-ft-top-100-holders
description: Get the top 100 holders of a fungible token on NEAR using the FastNear API. Use when you need to query token holder data, analyze token distribution, or look up holders for tokens like "token.pumpopoly.near" or "ironclaw-1956.meme-cooking.near".
compatibility: Public, free FastNear API. No API key required. No auth. Single HTTPS GET. Returns JSON. Requires `curl` and `jq`.
---

# FastNear FT Top 100 Holders API

Wrapper for the [FastNear API](https://api.fastnear.com) endpoint to retrieve the top 100 holders of any fungible token on NEAR.

## API Endpoint

```
GET https://api.fastnear.com/v1/ft/{token_ca}/top
```

- `token_ca`: the NEAR account id of the fungible token contract, e.g. `token.pumpopoly.near`.
- No authentication. No API key.
- Response is JSON, `Content-Type: application/json`.

## Quick Run

A ready-to-use shell wrapper lives at [`scripts/top100.sh`](scripts/top100.sh). It takes the token contract account id as its first argument, calls the API, and prints a ranked list with `token_id`, `count`, and `holders[]` (each with `rank`, `account`, `balance`).

```bash
./scripts/top100.sh token.pumpopoly.near
./scripts/top100.sh ironclaw-1956.meme-cooking.near
```

## Direct curl

For a one-off query without the wrapper:

```bash
curl --fail --silent "https://api.fastnear.com/v1/ft/token.pumpopoly.near/top"
```

## JavaScript

```javascript
async function getTopHolders(tokenCa) {
  const response = await fetch(`https://api.fastnear.com/v1/ft/${tokenCa}/top`);
  if (!response.ok) throw new Error(`FastNear ${response.status}: ${await response.text()}`);
  return response.json();
}

getTopHolders('token.pumpopoly.near').then(console.log);
```

## Python

```python
import requests

def get_top_holders(token_ca: str) -> dict:
    url = f"https://api.fastnear.com/v1/ft/{token_ca}/top"
    r = requests.get(url, timeout=15)
    r.raise_for_status()
    return r.json()

print(get_top_holders('token.pumpopoly.near'))
```

## Response Shape

```json
{
  "token_id": "shit-1170.meme-cooking.near",
  "count": 100,
  "holders": [
    { "rank": 1, "account": "v2.ref-finance.near",     "balance": "370407158691774838759672414" },
    { "rank": 2, "account": "vault.huggies.near",      "balance": "100000000004066802850898668" }
  ]
}
```

- `token_id`: the token contract account id that was queried.
- `count`: number of holders returned (≤ 100).
- `holders[]`: ranked descending by `balance`.
  - `account`: NEAR account id of the holder.
  - `balance`: raw on-chain balance as a decimal string (big number). Divide by `10^decimals` from the token's `ft_metadata` for a human-readable figure.

## Notes

- **Decimals.** `balance` is in raw integer units. Fetch the token's `ft_metadata` (e.g. `near view <token_ca> ft_metadata`) and divide `balance` by `10^decimals` to get a human-readable amount. The raw string is kept as-is because it is lossless.
- **Errors.** A nonexistent or non-FT account id yields a 4xx response. The wrapper script exits with a curl error and a non-zero status in that case; the JS/Python snippets throw.
- **Rate limits.** The public FastNear endpoints are unmetered for low-volume callers; no key is required for normal use.
- **Pagination.** The endpoint returns at most 100 holders. There is no offset/page parameter — for deeper holder lists, iterate per-account via the FastNear account/FT endpoints instead.
