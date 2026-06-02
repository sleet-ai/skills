---
name: ft-top-100-holders
description: Get the top 100 holders of a fungible token on NEAR using the FastNear API. Use when you need to query token holder data, analyze token distribution, or look up holders for tokens like "token.pumpopoly.near" or "ironclaw-1956.meme-cooking.near".
---

# FastNear FT Top 100 Holders

Wrapper for the [FastNear API](https://api.fastnear.com) to retrieve top 100 holders of any fungible token on NEAR.

## API Endpoint

```
GET https://api.fastnear.com/v1/ft/{token_ca}/top
```

## curl Example

```bash
# Generic fungible token
curl "https://api.fastnear.com/v1/ft/shit-1170.meme-cooking.near/top"

# token.pumpopoly.near
curl "https://api.fastnear.com/v1/ft/token.pumpopoly.near/top"

# ironclaw-1956.meme-cooking.near
curl "https://api.fastnear.com/v1/ft/ironclaw-1956.meme-cooking.near/top"
```

## JavaScript Fetch Example

```javascript
async function getTopHolders(tokenCa) {
  const response = await fetch(`https://api.fastnear.com/v1/ft/${tokenCa}/top`);
  const data = await response.json();
  return data;
}

// Usage
getTopHolders('token.pumpopoly.near').then(console.log);
getTopHolders('ironclaw-1956.meme-cooking.near').then(console.log);
```

## Python Requests Example

```python
import requests

def get_top_holders(token_ca):
    url = f"https://api.fastnear.com/v1/ft/{token_ca}/top"
    response = requests.get(url)
    return response.json()

# Usage
result = get_top_holders('token.pumpopoly.near')
print(result)
```

## Response Shape

Returns an array of holder objects with fields like `account_id`, `balance`, and `百分位` (percentage).
