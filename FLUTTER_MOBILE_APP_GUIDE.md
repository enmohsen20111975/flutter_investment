# EGX Investment Platform - Flutter Mobile Application Guide
* main website sorcue code : \\wsl.localhost\Ubuntu\home\meme\my apps\investment_fullstack-main
main live website : https://invist.m2y.net
admin emails : enmohsen20111975@gmail.com or ceo@m2y.net 
## Table of Contents

1. [Overview](#overview)
2. [API Configuration](#api-configuration)
3. [Authentication APIs](#authentication-apis)
4. [Stock APIs](#stock-apis)
5. [Market APIs](#market-apis)
6. [Portfolio APIs](#portfolio-apis)
7. [User Data APIs](#user-data-apis)
8. [Payment APIs](#payment-apis)
9. [Mobile App Features](#mobile-app-features)
10. [App UI Styling](#app-ui-styling-and-experience)
11. [Web-Mobile Connection](#web-mobile-connection)
12. [Flutter Implementation](#flutter-implementation)
13. [State Management](#state-management)
14. [Offline Support](#offline-support)
15. [Push Notifications](#push-notifications)
16. [Security Best Practices](#security-best-practices)
17. [Verified Mobile-Website Production Update (April 9, 2026)](#verified-mobile-website-production-update-april-9-2026)

---

## Overview

This guide provides comprehensive documentation for building a Flutter mobile application that connects to the EGX Investment Platform backend. The mobile app will enable users to:

- Track Egyptian stock market (EGX) investments
- Manage personal portfolios
- Receive real-time market alerts
- Access investment recommendations
- Track halal/compliant investments

### Technology Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter (Dart) |
| State Management | ChangeNotifier / custom controller |
| HTTP Client | Dio |
| Local Storage | SharedPreferences + flutter_secure_storage |
| Push Notifications | flutter_local_notifications |
| Charts | Custom painter / sparkline charts |

---

## API Configuration

### Base URLs

| Environment | Base URL |
|-------------|----------|
| **Local Development (Emulator)** | `http://10.0.2.2:8100/api` |
| **Local Development (Real Device)** | `http://192.168.x.x:8100/api` |
| **Production** | `https://invist.m2y.net/api` |

> **Verified on April 5, 2026:** the current backend routes come from `server.js` and `backend/routes/*.js`. Older examples that use port `8010` or removed endpoints are outdated.

### Authentication Header

Authenticated requests use:

```http
X-API-Key: your_api_key_here
Content-Type: application/json
```

### Development Note

- Use the `api_key` returned by `POST /api/auth/register` or `POST /api/auth/login`.
- Avoid hardcoding a development key in a production Flutter build.

### Verified Live Update Policy (April 8, 2026)

- **Stocks / market overview:** refresh every **5 minutes** only during **Sunday–Thursday, 9:00 AM to 3:00 PM** (`Africa/Cairo`).
- **Friday and Saturday:** no stock-market refresh jobs should run.
- **Gold and silver:** refresh every **5 minutes**, **24/7**.
- To check the active window from Flutter, call `GET /api/market/status` or `POST /api/market/check-update-allowed`.

### Current Data Architecture for Mobile (April 8, 2026)

The backend now uses a **layered datasource strategy**. The Flutter app should continue to call the **main Node API** only:

1. **Primary live stock source:** VPS-hosted `egxpy_service`
2. **Primary calculation/storage layer:** the main application database (`SQLite` locally / hosting DB in production)
3. **Fallback external sources:** `Mubasher`, `TwelveData`, and `EODHD` only when the preferred feed does not return a usable quote

### Backend datasource architecture

- The **Flutter app** calls the **main Node backend** on this project.
- The **Node backend** in turn may call the **VPS `egxpy_service`** to fetch live quotes, history, premium analytics, and market snapshots.
- The Node backend also enriches and stores data in the **database** and exposes normalized responses to the mobile frontend.
- This means Flutter stays frontend-only, while the backend handles the datasource switching, caching, and calculations.

#### Important mobile implications

- **Do not call the VPS EGXPY service directly from Flutter** in normal production use; the Node backend already proxies and normalizes it.
- **All portfolio, gain/loss, income/expense, and recommendation calculations depend on the database**, not raw UI-side math.
- **Live prices are used to refresh and enrich the DB**, then the app reads normalized API responses from the main backend.
- The mobile app should remain a frontend-only consumer of the main Node backend APIs: the backend delivers stock data, history, charts-ready payloads, analysis, and recommendations.
- The `egxpy_service` is a separate VPS datasource used by the Node backend; it is not intended to be called directly by the Flutter app in normal production.
- For charts, use `/api/stocks/:ticker/history` for stock price series and `/api/stocks/metals/history` for gold/silver history.
- For analysis, use `/api/stocks/:ticker/recommendation` and `/api/stocks/:ticker/premium` rather than computing metrics in Dart.
- For portfolio insights, use `/api/user/portfolio-impact`, `/api/user/financial-summary`, and `/api/user/portfolio-analysis`.
- For `/api/market/overview`, treat the summary fields as follows:
  - `summary.total_stocks`: the **active / recently tradable EGX subset** shown to the user
  - `summary.tracked_symbols_total`: the **full internally tracked symbol universe** in the database
- **Never hardcode a fixed number of listed Egyptian companies in Flutter**; always render the values returned by the backend.

---

## Verified API Reference (Current Backend)

> This section reflects the **actual Express routes currently mounted in `server.js`**. Older `/api/news/*` examples are legacy notes and should not be treated as the primary mobile integration surface.

### Core Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/health` | No | Health check and DB status |
| `GET` | `/api` | No | API info / mounted sections |

### Auth Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `POST` | `/api/auth/register` | No | Create user and return `api_key` |
| `POST` | `/api/auth/login` | No | Login and return a new `api_key` |
| `GET` | `/api/auth/me` | Yes | Current authenticated user |
| `POST` | `/api/auth/logout` | Yes | Invalidate current session key |
| `GET` | `/api/auth/google/config` | No | Google OAuth web config |
| `POST` | `/api/auth/google` | No | Login with Google ID token |

### Stock Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/api/stocks` | Optional | List stocks with paging/filtering |
| `GET` | `/api/stocks/metals` | Optional | Detailed gold/silver metrics |
| `GET` | `/api/stocks/metals/history?range=day` | Optional | Metals history for charts |
| `GET` | `/api/stocks/:ticker` | Optional | Single stock details with live quote fallback |
| `GET` | `/api/stocks/:ticker/history?days=30` | Optional | OHLCV history for charts and analytics |
| `GET` | `/api/stocks/:ticker/recommendation` | Optional | Recommendation / advanced stock analysis |
| `GET` | `/api/stocks/:ticker/premium` | Optional | Premium fundamentals and valuation data |
| `GET` | `/api/stocks/search/query?query=COMI` | Optional | Compatibility search route |
| `GET` | `/api/stocks/search/:query` | Optional | Canonical search route |

### Market Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/api/market/overview` | Optional | Market summary, top movers, indices, metals |
| `GET` | `/api/market/indices` | Optional | All EGX indices |
| `GET` | `/api/market/indices/:symbol` | Optional | One EGX index |
| `GET` | `/api/market/metals` | Optional | Gold and silver market snapshot |
| `GET` | `/api/market/status` | Optional | Current EGX schedule window |
| `GET` | `/api/market/update-status?update_type=stocks` | Optional | Last update status |
| `GET` | `/api/market/update-history?update_type=stocks&days=30` | Optional | Update history |
| `POST` | `/api/market/check-update-allowed` | Optional | Check whether updates are allowed now |
| `POST` | `/api/market/update-data` | Yes | Push stock data update payload |
| `GET` | `/api/market/refresh-check` | Optional | Determine if refresh is needed |
| `GET` | `/api/market/live-prices?tickers=COMI,ETEL` | Yes | Near-real-time live quotes |
| `GET` | `/api/market/recommendations/trusted-sources` | Yes | Trusted-source recommendations |
| `GET` | `/api/market/recommendations/ai-insights` | Yes | AI market insights |
| `POST` | `/api/market/recommendations/gemini-assistant` | Yes | Gemini assistant response |

> **Chart and price usage**: for stock charts use `/api/stocks/:ticker/history`; for metal charts use `/api/stocks/metals/history`. The backend already returns series data compatible with chart widgets.

### Portfolio Recommendation Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/api/portfolio/recommend` | Yes | Basic portfolio recommendation |
| `POST` | `/api/portfolio/recommend/advanced` | Yes | Advanced allocation recommendation |

### User Data Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/api/user/watchlist` | Yes | List watchlist |
| `POST` | `/api/user/watchlist` | Yes | Add watchlist item |
| `PUT` | `/api/user/watchlist/:itemId` | Yes | Update watchlist item |
| `DELETE` | `/api/user/watchlist/:itemId` | Yes | Remove watchlist item |
| `GET` | `/api/user/assets` | Yes | Portfolio assets including gold/silver |
| `POST` | `/api/user/assets` | Yes | Create new asset |
| `PUT` | `/api/user/assets/:assetId` | Yes | Update asset |
| `DELETE` | `/api/user/assets/:assetId` | Yes | Delete asset |
| `POST` | `/api/user/assets/sync-prices` | Yes | Sync stock and metals prices |
| `GET` | `/api/user/portfolio-impact` | Yes | Daily portfolio impact |
| `GET` | `/api/user/financial-summary` | Yes | Consolidated financial summary |
| `GET` | `/api/user/portfolio-analysis` | Yes | Detailed portfolio analysis and per-asset recommendations |
| `GET` | `/api/user/settings` | Yes | Load account profile/settings |
| `PUT` | `/api/user/settings` | Yes | Update email / username / risk tolerance |
| `GET` | `/api/user/income-expense` | Yes | List income/expense entries |
| `POST` | `/api/user/income-expense` | Yes | Add transaction |
| `PUT` | `/api/user/income-expense/:transactionId` | Yes | Update transaction |
| `DELETE` | `/api/user/income-expense/:transactionId` | Yes | Delete transaction |
| `POST` | `/api/user/share-portfolio` | Yes | Create shareable portfolio link |
| `GET` | `/api/user/shared-portfolio/:shareCode` | No | Public shared portfolio view |
| `GET` | `/api/user/my-shares` | Yes | List created share links |
| `DELETE` | `/api/user/share/:shareId` | Yes | Delete share link |

### Payment Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| `GET` | `/api/payment/plans` | No | Available plans |
| `GET` | `/api/payment/subscription` | Yes | Current subscription |
| `POST` | `/api/payment/initiate` | Yes | Start Paymob payment flow |
| `POST` | `/api/payment/callback` | No | Paymob callback |
| `GET` | `/api/payment/callback` | No | Browser callback landing |

### Flutter Integration Notes

- Use `X-API-Key` for all authenticated requests.
- For the **market home screen**, start with:
  1. `GET /api/market/overview`
  2. `GET /api/market/status`
  3. `GET /api/market/metals`
- For a **portfolio screen**, combine:
  - `GET /api/user/assets`
  - `GET /api/user/financial-summary`
  - `GET /api/user/portfolio-impact`
- For **search**, prefer `GET /api/stocks/search/:query`.

---

## Authentication APIs

### Base URL: `/api/auth`

> `GET /api/auth/me` and `POST /api/auth/logout` require a **user API key** created by `register` or `login`.

### 1. Register New User

```http
POST /api/auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "investor123",
  "password": "securePassword123",
  "default_risk_tolerance": "medium"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "investor123"
  },
  "api_key": "generated_api_key_here"
}
```

**Flutter Implementation:**
```dart
Future<AuthResult> register({
  required String email,
  required String username,
  required String password,
  String defaultRiskTolerance = 'medium',
}) async {
  final response = await _dio.post('/auth/register', data: {
    'email': email,
    'username': username,
    'password': password,
    'default_risk_tolerance': defaultRiskTolerance,
  });
  return AuthResult.fromJson(response.data);
}
```

---

### 2. Login

```http
POST /api/auth/login
```

**Request Body:**
```json
{
  "username_or_email": "investor123",
  "password": "securePassword123",
  "key_name": "Mobile App Session",
  "expires_in_days": 30
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "investor123",
    "default_risk_tolerance": "medium"
  },
  "api_key": "new_api_key_here"
}
```

**Flutter Implementation:**
```dart
Future<AuthResult> login({
  required String usernameOrEmail,
  required String password,
  String? keyName,
  int? expiresInDays,
}) async {
  final response = await _dio.post('/auth/login', data: {
    'username_or_email': usernameOrEmail,
    'password': password,
    if (keyName != null) 'key_name': keyName,
    if (expiresInDays != null) 'expires_in_days': expiresInDays,
  });
  
  // Store API key securely
  final apiKey = response.data['api_key'];
  await _secureStorage.write(key: 'api_key', value: apiKey);
  
  return AuthResult.fromJson(response.data);
}
```

---

### 3. Get Current User

```http
GET /api/auth/me
```

**Headers:**
```http
X-API-Key: your_api_key
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "investor123",
  "default_risk_tolerance": "medium",
  "created_at": "2026-01-15T10:00:00",
  "last_login": "2026-03-06T08:30:00"
}
```

---

### 4. Logout

```http
POST /api/auth/logout
```

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

### 5. Google OAuth Configuration

```http
GET /api/auth/google/config
```

**Response (200):**
```json
{
  "enabled": true,
  "client_id": "google_client_id.apps.googleusercontent.com"
}
```

---

### 6. Login with Google

```http
POST /api/auth/google
```

**Request Body:**
```json
{
  "id_token": "google_id_token_here"
}
```

**Response:** same shape as standard login, including the generated `api_key`.

---

## Stock APIs

### Base URL: `/api/stocks`

> These routes currently use `optionalAuth`. They work without a key, but passing `X-API-Key` is recommended from the mobile app.

### 1. List All Stocks

```http
GET /api/stocks?query=bank&search_field=all&sector=Banking&index=egx30&page=1&page_size=50
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| query | string | No | null | Search text across symbol, name, Arabic name, or sector |
| search_field | string | No | `all` | `all`, `symbol`, `name`, or `sector` |
| sector | string | No | null | Exact sector filter |
| index | string | No | null | `egx30`, `egx70`, or `egx100` |
| page | integer | No | 1 | Page number |
| page_size | integer | No | 50 | Items per page |

**Response (200):**
```json
{
  "stocks": [
    {
      "id": 1,
      "ticker": "ETEL",
      "name": "Telecom Egypt",
      "name_ar": "الاتصالات المصرية",
      "current_price": 25.50,
      "previous_close": 25.00,
      "price_change": 2.0,
      "sector": "Telecommunications",
      "egx30_member": true,
      "egx70_member": false,
      "egx100_member": true,
      "is_halal": true,
      "compliance_status": "halal"
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 50,
  "total_pages": 2,
  "source": "fallback"
}
```

> If the response contains `"source": "fallback"`, the API is serving generated fallback market data because live/database data was unavailable.

---

### 2. Get Stock by Ticker

```http
GET /api/stocks/{ticker}
```

**Example:**
```http
GET /api/stocks/ETEL
```

**Response (200):**
```json
{
  "data": {
    "ticker": "ETEL",
    "name": "Telecom Egypt",
    "name_ar": "الاتصالات المصرية",
    "current_price": 25.50,
    "previous_close": 25.00,
    "price_change": 2.0,
    "sector": "Telecommunications",
    "is_halal": true,
    "compliance_status": "halal"
  }
}
```

---

### 3. Search Stocks

```http
GET /api/stocks/search/{query}
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| sector | string | No | Sector filter |
| min_price | float | No | Minimum current price |
| max_price | float | No | Maximum current price |

**Example:**
```http
GET /api/stocks/search/telecom?sector=Telecommunications
```

**Response (200):**
```json
{
  "query": "telecom",
  "results": [
    {
      "ticker": "ETEL",
      "name": "Telecom Egypt",
      "current_price": 25.50,
      "sector": "Telecommunications",
      "is_halal": true,
      "compliance_status": "halal"
    }
  ],
  "total": 1
}
```

---

### 4. Get Stock Price History

```http
GET /api/stocks/{ticker}/history?days=30
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| days | integer | No | 30 | Number of days to return |

**Response (200):**
```json
{
  "success": true,
  "ticker": "ETEL",
  "data": [
    {
      "date": "2026-03-06",
      "open": 25.10,
      "high": 25.80,
      "low": 24.90,
      "close": 25.50,
      "volume": 1500000
    }
  ],
  "summary": {
    "start_price": 23.00,
    "end_price": 25.50,
    "high_price": 26.50,
    "low_price": 23.00,
    "avg_price": 24.75,
    "total_volume": 25000000,
    "price_change": 2.50,
    "price_change_percent": 10.86
  },
  "days": 30
}
```

---

### 5. Get Stock Recommendation / Deep Analysis Snapshot

```http
GET /api/stocks/{ticker}/recommendation
```

This returns the backend analysis payload for the stock, combining stock data, history, and the latest saved deep insight snapshot when available.

**New AI fields:** the response can now include `ai_summary`, `provider_used`, and `used_model`. If no external AI provider responds, `provider_used` will be `deterministic_fallback` and the app still receives an Arabic analysis summary.

---

### Flutter Notes

- Use the returned `is_halal` and `compliance_status` fields for a halal-only UI.
- The current backend does **not** implement `/api/stocks/halal/list` or `/api/stocks/haram/list`.
- If you want a “halal only” screen, fetch `/api/stocks` and filter client-side in Flutter.

---

## Market APIs

### Base URL: `/api/market`

### 1. Get Market Overview

```http
GET /api/market/overview
```

**Response (200):**
```json
{
  "market_status": {
    "is_open": false,
    "can_update": false,
    "is_trading_day": true,
    "is_market_hours": false,
    "current_time": "08:16 PM",
    "current_date": "Wednesday, April 8, 2026",
    "timezone": "Africa/Cairo",
    "trading_hours": {
      "start": "9:00 AM",
      "end": "3:00 PM"
    }
  },
  "summary": {
    "total_stocks": 255,
    "tracked_symbols_total": 406,
    "gainers": 175,
    "losers": 54,
    "unchanged": 26,
    "egx30_stocks": 23,
    "egx70_stocks": 11,
    "egx100_stocks": 39,
    "egx30_value": 10285.60
  },
  "indices": [
    {
      "symbol": "EGX30",
      "name": "EGX 30 Index",
      "value": 10285.60,
      "change_percent": 2.16,
      "last_updated": "2026-04-08T10:29:00Z"
    }
  ],
  "metals": {
    "gold": { "price": 7278.34 },
    "silver": { "price": 131.27 }
  },
  "top_gainers": [...],
  "top_losers": [...],
  "most_active": [...],
  "last_updated": "2026-04-08T18:16:21Z"
}
```

> **Mobile note:** use `summary.total_stocks` for the user-facing “active stocks” card. If you need the broader tracked universe for diagnostics/admin screens, use `summary.tracked_symbols_total`.

---

### 2. Get Market Indices

```http
GET /api/market/indices
```

Returns:

```json
{
  "indices": [
    {
      "symbol": "EGX30",
      "name": "EGX 30 Index",
      "value": 18500.50,
      "change": 50.50,
      "change_percent": 0.27,
      "last_updated": "2026-03-06T13:00:00"
    }
  ],
  "total": 3
}
```

---

### 3. Get Specific Index

```http
GET /api/market/indices/{symbol}
```

**Example:**
```http
GET /api/market/indices/EGX33
```

---

### 4. Get Market Status

```http
GET /api/market/status
```

**Response (200):**
```json
{
  "is_open": false,
  "can_update": false,
  "can_update_stocks": false,
  "can_update_metals": true,
  "is_trading_day": true,
  "is_market_hours": false,
  "current_time": "08:16 PM",
  "current_date": "Wednesday, April 8, 2026",
  "timezone": "Africa/Cairo",
  "trading_days": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"],
  "trading_hours": {
    "start": "9:00 AM",
    "end": "3:00 PM"
  },
  "next_trading_window": {
    "date": "Thursday, April 9",
    "time": "9:00 AM"
  }
}
```

---

### 5. Get Update Status

```http
GET /api/market/update-status?update_type=stocks&days=7
```

Returns the latest successful update, whether an update can run now, and recent history.

---

### 6. Get Update History

```http
GET /api/market/update-history?update_type=stocks&days=30
```

---

### 7. Check If Data Update Is Allowed

```http
POST /api/market/check-update-allowed
```

**Request Body:**
```json
{
  "force": false
}
```

---

### 8. Trigger Stock Data Update

```http
POST /api/market/update-data
```

**Headers:** `X-API-Key` required

**Request Body:**
```json
{
  "stocks": ["ETEL", "COMI"],
  "force": false,
  "source": "mobile_app"
}
```

---

### 9. Refresh Check

```http
GET /api/market/refresh-check?max_age_minutes=30
```

---

### 10. Get Live Prices

```http
GET /api/market/live-prices?tickers=ETEL,COMI
```

**Headers:** `X-API-Key` required

**Response (200):**
```json
{
  "requested": 2,
  "resolved": 2,
  "quotes": [
    {
      "ticker": "ETEL",
      "quote": {
        "price": 25.50
      }
    }
  ],
  "generated_at": "2026-03-06T13:00:00"
}
```

---

### 11. Get Trusted Sources Recommendations

```http
GET /api/market/recommendations/trusted-sources
```

**Headers:** `X-API-Key` required

---

### 12. Get AI Market Insights

```http
GET /api/market/recommendations/ai-insights
```

**Headers:** `X-API-Key` required

**Response (200):**
```json
{
  "market_sentiment": "bullish",
  "market_score": 68.4,
  "top_sectors": [
    {"name": "Telecommunications", "count": 15},
    {"name": "Banking", "count": 12}
  ],
  "risk_assessment": "medium",
  "ai_summary": "- ملخص عربي لحالة السوق...",
  "provider_used": "gemini أو grok أو deterministic_fallback",
  "used_model": "gemini-2.0-flash",
  "generated_at": "2026-03-06T13:00:00"
}
```

---

### 13. Gemini Portfolio Assistant

```http
POST /api/market/recommendations/gemini-assistant
```

**Headers:** user `X-API-Key` required

**Response:** includes `market_insights`, `portfolio_lots`, `deterministic_advice`, `ai_response`, `gemini_response` (compatibility field), `provider_used`, `used_model`, and `generated_at`.

---

## Portfolio APIs

### Base URL: `/api/portfolio`

> Portfolio recommendation routes require `X-API-Key`.

### 1. Get Portfolio Recommendations

```http
GET /api/portfolio/recommend?capital=100000&risk=medium&amount_per_stock=20000&sectors=Telecommunications,Banking
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| capital | float | Yes | - | Investment capital (EGP) |
| risk | string | No | medium | Risk level: `low`, `medium`, `high` |
| amount_per_stock | float | No | null | Preferred budget per opportunity; backend derives the stock count automatically |
| max_stocks | integer | No | derived | Optional legacy parameter; avoid exposing it to normal retail users in Flutter |
| sectors | string | No | null | Comma-separated sectors |

**Response (200):**
```json
{
  "capital": 100000.0,
  "risk_level": "medium",
  "amount_per_stock": 20000.0,
  "recommendations": [
    {
      "ticker": "ETEL",
      "name": "Telecom Egypt",
      "current_price": 91.0,
      "allocation_amount": 20000.0,
      "allocation_percent": 20.0,
      "recommended_shares": 219,
      "score": 85,
      "sector": "Telecommunications"
    }
  ],
  "total_stocks": 5,
  "generated_at": "2026-04-08T18:00:00"
}
```

> **UX recommendation for Flutter:** use a money-first field such as **"المبلغ لكل فرصة"** instead of asking the user for the number of stocks directly.

---

### 2. Advanced Portfolio Recommendations

```http
POST /api/portfolio/recommend/advanced
```

**Request Body:**
```json
{
  "capital": 100000,
  "risk": "medium",
  "amount_per_stock": 15000,
  "sectors": ["Telecommunications", "Healthcare"],
  "exclude_tickers": ["COMI"],
  "min_price": 10.0,
  "max_price": 100.0,
  "investment_horizon": "long"
}
```

**Response (200):**
```json
{
  "capital": 100000,
  "risk_level": "medium",
  "investment_horizon": "long",
  "recommendations": [...],
  "portfolio_metrics": {
    "average_pe_ratio": 12.5,
    "average_dividend_yield": 4.2,
    "total_stocks": 10
  },
  "generated_at": "2026-03-06T13:00:00"
}
```

### Flutter Notes

- The current backend does **not** implement `/api/portfolio/halal-stocks`, `/api/portfolio/haram-stocks`, or `/api/portfolio/wealth-plan`.
- If you need a halal-only recommendations screen, filter the stock list in Flutter using `is_halal` before presenting choices to the user.

---

## User Data APIs

### Base URL: `/api/user`

### 1. Watchlist Management

#### Get Watchlist

```http
GET /api/user/watchlist
```

**Response (200):**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "stock_id": 5,
    "alert_price_above": 30.0,
    "alert_price_below": 20.0,
    "alert_change_percent": 5.0,
    "notes": "Watch for breakout",
    "added_at": "2026-03-01T10:00:00",
    "stock": {
      "ticker": "ETEL",
      "name": "Telecom Egypt",
      "current_price": 25.50
    }
  }
]
```

#### Add to Watchlist

```http
POST /api/user/watchlist
```

**Request Body:**
```json
{
  "ticker": "ETEL",
  "alert_price_above": 30.0,
  "alert_price_below": 20.0,
  "alert_change_percent": 5.0,
  "notes": "Watch for breakout"
}
```

#### Update Watchlist Item

```http
PUT /api/user/watchlist/{itemId}
```

#### Remove from Watchlist

```http
DELETE /api/user/watchlist/{itemId}
```

---

### 2. Asset Management

#### Get Assets

```http
GET /api/user/assets?asset_type=stock
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| asset_type | string | Filter by type: stock, gold, silver, cash, crypto |

**Response (200):**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "asset_type": "stock",
    "asset_name": "Telecom Egypt",
    "asset_ticker": "ETEL",
    "stock_id": 5,
    "quantity": 100,
    "purchase_price": 22.0,
    "current_price": 25.50,
    "current_value": 2550.0,
    "purchase_date": "2026-01-15",
    "target_price": 30.0,
    "stop_loss_price": 20.0,
    "currency": "EGP",
    "gain_loss": 350.0,
    "gain_loss_percent": 15.9,
    "is_halal": true,
    "auto_sync": true
  }
]
```

#### Create Asset

```http
POST /api/user/assets
```

**Request Body:**
```json
{
  "asset_type": "stock",
  "asset_name": "Telecom Egypt",
  "asset_ticker": "ETEL",
  "stock_id": 5,
  "quantity": 100,
  "purchase_price": 22.0,
  "purchase_date": "2026-01-15",
  "target_price": 30.0,
  "stop_loss_price": 20.0,
  "currency": "EGP",
  "notes": "Long-term position"
}
```

#### Update Asset

```http
PUT /api/user/assets/{assetId}
```

#### Delete Asset

```http
DELETE /api/user/assets/{assetId}
```

#### Sync Asset Prices

```http
POST /api/user/assets/sync-prices
```

**Response (200):**
```json
{
  "message": "Prices synced",
  "updated_count": 5,
  "total_assets": 5
}
```

---

### 3. Financial Summary

```http
GET /api/user/financial-summary
```

**Response (200):**
```json
{
  "total_value": 150000.0,
  "total_cost": 130000.0,
  "total_gain_loss": 20000.0,
  "total_gain_loss_percent": 15.38,
  "by_type": {
    "stock": {"value": 100000.0, "count": 5},
    "gold": {"value": 30000.0, "count": 1},
    "cash": {"value": 20000.0, "count": 1}
  },
  "by_currency": {
    "EGP": 140000.0,
    "USD": 10000.0
  },
  "halal_value": 120000.0,
  "non_halal_value": 30000.0,
  "halal_percent": 80.0
}
```

---

### 4. Income/Expense Tracking

#### Get Transactions

```http
GET /api/user/income-expense?transaction_type=income&category=dividends&start_date=2026-01-01
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| transaction_type | string | income or expense |
| category | string | dividends, trading, fees, etc. |
| start_date | date | Filter from date |
| end_date | date | Filter to date |

#### Create Transaction

```http
POST /api/user/income-expense
```

**Request Body:**
```json
{
  "transaction_type": "income",
  "category": "dividends",
  "amount": 500.0,
  "currency": "EGP",
  "description": "ETEL Q4 dividend",
  "related_asset_id": 5,
  "transaction_date": "2026-03-06"
}
```

#### Update Transaction

```http
PUT /api/user/income-expense/{transactionId}
```

#### Delete Transaction

```http
DELETE /api/user/income-expense/{transactionId}
```

---

### 5. Portfolio Sharing

#### Share Portfolio

```http
POST /api/user/share-portfolio
```

**Request Body:**
```json
{
  "is_public": false,
  "allow_copy": false,
  "show_values": true,
  "show_gain_loss": true,
  "password": "optional_password",
  "max_views": 100,
  "expires_in_days": 30
}
```

**Response (201):**
```json
{
  "share_code": "A1B2C3D4",
  "share_url": "/shared/A1B2C3D4",
  "expires_at": "2026-04-05T00:00:00",
  "is_public": false
}
```

#### View Shared Portfolio

```http
GET /api/user/shared-portfolio/{shareCode}
```

**Headers (if password protected):**
```http
X-Share-Password: optional_password
```

#### Get My Shares

```http
GET /api/user/my-shares
```

#### Revoke Share

```http
DELETE /api/user/share/{shareId}
```

---

## Payment APIs

### Base URL: `/api/payment`

These routes support subscription billing from the mobile app.

### 1. Get Subscription Plans

```http
GET /api/payment/plans
```

**Response (200):**
```json
{
  "plans": [
    {
      "id": "free",
      "name": "مجاني",
      "price_monthly": 0,
      "price_yearly": 0,
      "features": ["..."],
      "limits": { "watchlist": 5, "portfolio": 1, "ai_analysis": 0 }
    }
  ]
}
```

### 2. Get Current Subscription

```http
GET /api/payment/subscription
```

**Headers:** user `X-API-Key` required

### 3. Initiate Payment

```http
POST /api/payment/initiate
```

**Headers:** user `X-API-Key` required

**Request Body:**
```json
{
  "plan": "pro-monthly"
}
```

**Valid values:** `pro-monthly`, `pro-yearly`, `premium-monthly`, `premium-yearly`

**Response (200):**
```json
{
  "iframe_url": "https://accept.paymob.com/...",
  "paymob_order_id": "123456",
  "amount_egp": 99,
  "plan": "pro-monthly"
}
```

### 4. Payment Callback

- `POST /api/payment/callback` — Paymob webhook
- `GET /api/payment/callback?success=true` — redirect back to the app/web flow

---

## Verified Mobile-Website Production Update (April 9, 2026)

This section records the **actual production work completed in the Flutter app** and the **remaining website/backend adjustment required** so Google login works reliably for both Android and the website.

### Current Status Summary

#### ✅ Finished

- The Flutter app now uses the **website backend** as the main authentication authority.
- The production login screen is **Google-only**.
- The app sends the Google `id_token` to **`POST /api/auth/google`** and then stores the returned platform `api_key` for authenticated requests.
- Firebase **runtime initialization** was removed from the Flutter app, and `firebase_core` was removed from `pubspec.yaml`.
- Subscription logic is already connected to the website APIs:
  - **paid user** → premium features unlocked + ads disabled
  - **new user** → 7-day full trial
  - **expired free user** → premium analysis and recommendations locked until subscription
- Payment plan loading and subscription status reading are already integrated with:
  - `GET /api/payment/plans`
  - `GET /api/payment/subscription`
  - `POST /api/payment/initiate`
- Production helper/test text was removed from the visible mobile UI.
- The Flutter project currently verifies cleanly with `flutter analyze`.

#### ✅ Finished in the backend as well

The remaining website/backend work has now been completed directly:

- `backend/config.js` now supports `GOOGLE_ANDROID_CLIENT_IDS`
- `backend/routes/auth.js` now accepts **multiple allowed Google audiences** in both:
  - `POST /api/auth/google`
  - `GET /api/auth/google/callback`
- The production auth contract remains unchanged:
  - Google sign-in on device
  - send `id_token` to the website backend
  - backend returns `api_key`
  - Flutter continues using `X-API-Key`
- The app was **not** switched back to Firebase-runtime auth and was **not** migrated to JWT-only auth

#### Verified backend checks

The website/backend side was verified on **localhost** with real checks:

- `GET http://127.0.0.1:8100/health` returned **healthy** with **database connected**
- `POST /api/auth/register` successfully created a fresh test account
- `GET /api/auth/me` worked correctly using the returned `X-API-Key`
- `GET /api/payment/subscription` returned the expected **trial** access state
- `GET /api/auth/google/config` returned:
  - `enabled: true`
  - `accepted_audiences_count: 1`
  - `android_client_ids_configured: 0`

> This means the backend code supports multi-audience Google verification, but the deployment environment still needs the actual Android client IDs configured before Google auth is fully ready for Android release deployment.

#### Optional next steps only

- Automatic "open website while already logged in" handoff is still a **recommended enhancement**, not a blocker
- Android legacy Google-services cleanup can still be done later if you want a fully website-only setup

### What is already completed in the Flutter app

- The app now treats the **website backend as the only auth authority**.
- The login UI is now **Google-only** in production; test/manual auth entry points were removed from the visible flow.
- A direct website button is available from the mobile login screen.
- Firebase runtime initialization is no longer required for the production mobile login flow.
- Website subscription data now drives the mobile premium rules:
  - **active paid subscription** → all premium features open and ads disabled
  - **new account without paid plan** → full **7-day free trial**
  - **after trial expiry** → premium features such as **analysis** and **investment recommendations** are locked until subscription

### Important note about the current auth model

The current EGX platform is already built around **`X-API-Key`** authentication, not JWT-only auth.

That means the current production mobile flow is:

1. Flutter signs in with Google and gets a Google `id_token`
2. Flutter sends that token to **`POST /api/auth/google`**
3. The Node backend verifies the Google token and returns the platform user + `api_key`
4. Flutter stores the returned `api_key` securely and uses it in **`X-API-Key`** for authenticated requests

> A full JWT unification layer can still be added later if desired, but it is **not required** for the current production Flutter integration.

### ✅ Mobile auth status (verified and ready)

The mobile auth flow is now documented to match the live backend behavior:

- `POST /api/auth/google` → verifies the Google `id_token` and returns the platform `api_key`
- `GET /api/auth/me` → returns the signed-in user plus `subscription_plan`, `subscription_status`, and `access`
- `GET /api/payment/subscription` → returns trial/premium state such as `trial_active`, `trial_days_left`, `has_full_access`, `ads_disabled`, and `features.analysis` / `features.recommendations`

For Flutter, the production rule is simple:

1. sign in with Google on the device
2. send the returned `id_token` to the backend
3. store the returned `api_key` securely
4. attach `X-API-Key: <api_key>` to every authenticated request

This matches the current website behavior and the existing premium/trial access model.

### Root cause of the recent Android Google auth failure

The recent failure was caused by an **OAuth audience mismatch** between the website Google client and the Android app Google OAuth client.

Current verified backend behavior in `backend/routes/auth.js`:

- `GET /api/auth/google/config` exposes `settings.GOOGLE_CLIENT_ID` plus safe audience metadata
- `POST /api/auth/google` verifies the incoming token against the allowed audience list
- `GET /api/auth/google/callback` also verifies against the same allowed audience list
- `backend/config.js` now supports both the web client and optional Android client IDs

This keeps the website redirect flow working while also allowing Android-issued Google ID tokens when their audience is approved.

The Flutter app has already been corrected so that **Android no longer forces the website client ID** and instead signs in normally on the device, then sends the Google `id_token` to your own website backend for verification.

### ✅ Node.js backend adjustment implemented

To support both **website Google login** and **Android Google sign-in** from the same backend, the Node backend now accepts **multiple allowed audiences**.

#### 1) Extend backend config

```javascript
// backend/config.js

// Google OAuth (Web + Android)
GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID,
GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET,
GOOGLE_REDIRECT_URI: process.env.GOOGLE_REDIRECT_URI,
GOOGLE_ANDROID_CLIENT_IDS: (process.env.GOOGLE_ANDROID_CLIENT_IDS || '')
    .split(',')
    .map(value => value.trim())
    .filter(Boolean),
```

Example environment value:

```env
GOOGLE_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_IDS=your_android_client_id.apps.googleusercontent.com
```

#### 2) Update Google token verification in `backend/routes/auth.js`

```javascript
const allowedGoogleAudiences = [
    settings.GOOGLE_CLIENT_ID,
    ...(settings.GOOGLE_ANDROID_CLIENT_IDS || [])
].filter(Boolean);

const client = new OAuth2Client(settings.GOOGLE_CLIENT_ID);

const ticket = await client.verifyIdToken({
    idToken: id_token,
    audience: allowedGoogleAudiences
});
```

Apply the same `allowedGoogleAudiences` logic to the Google redirect callback verification too:

```javascript
const ticket = await oauthClient.verifyIdToken({
    idToken,
    audience: allowedGoogleAudiences
});
```

### Mobile integration rule for the backend team

- **Keep `GET /api/auth/google/config` for the website flow**.
- **Do not require the Android app to use that returned `client_id` directly**.
- Android should use its native Google Sign-In flow on the device and send the returned `id_token` to your website backend.
- The backend should simply accept the web client and the approved Android client audiences when verifying the Google ID token.

### Subscription behavior now expected by mobile

The current backend already returns the correct subscription access contract from `GET /api/payment/subscription`, including:

- `plan`
- `status`
- `expires_at`
- `access.has_paid_subscription`
- `access.trial_active`
- `access.trial_days_left`
- `access.has_full_access`
- `access.ads_disabled`
- `trial_message_ar`
- `unlocked_features`

This matches the Flutter production behavior now implemented:

- paid users → **no ads** + **all premium screens unlocked**
- trial users → **7 days full access**
- expired free users → **analysis** and **recommendations** require subscription

### Recommended website handoff for “Open in Website”

If later we want the user to open the website from the app and remain signed in automatically, the recommended production-safe approach is:

1. mobile sends the authenticated `X-API-Key` to a new backend endpoint such as `POST /api/auth/mobile-handoff`
2. backend returns a **short-lived one-time code**
3. mobile opens `https://invist.m2y.net/auth/mobile/callback?code=...`
4. the website exchanges that one-time code for a normal web session / cookie

> Avoid putting a long-lived `api_key` or permanent auth token directly in the URL in production.

---

## Mobile App Features

### Core Features

Status legend for the current Flutter app audit:

- `[x]` Implemented in the current mobile app
- `[~]` Partially implemented / backend-ready but incomplete in the UI or flow
- `[ ]` Not implemented yet

#### 1. Authentication & Onboarding
- [x] User registration with email/username
- [x] Login with credentials
- [x] Google OAuth integration
- [x] Biometric authentication (Face ID / Touch ID)
- [~] PIN code for quick access
- [x] Password reset functionality
- [x] Session management

Current note:
- The app now supports Google sign-in and email/password authentication.
- Device biometric login is implemented; an app-level PIN entry screen remains a future enhancement.

#### 2. Dashboard
- [x] Market overview summary
- [x] Portfolio value at a glance
- [x] Today's gainers/losers
- [x] Quick actions (search, add to watchlist)
- [x] Market status indicator (open/closed)
- [x] Last data update timestamp

#### 3. Stock Search & Discovery
- [x] Search by ticker or company name
- [x] Arabic name search support
- [x] Filter by sector, halal status, price range
- [x] Sort by various metrics
- [x] Trending stocks

Current note:
- Search, sector filtering, halal-only filtering, and price range filtering are implemented in the current stock browser.
- Sorting options are available for ticker, name, price, and percentage change.
- Trending stocks are shown through a dedicated top movers section.

#### 4. Stock Detail View
- [x] Current price and change
- [x] Price chart (1D, 1W, 1M, 3M, 1Y)
- [~] Key statistics (P/E, ROE, dividend yield)
- [~] Technical indicators (RSI, MA)
- [x] Compliance status (Halal/Haram)
- [x] AI recommendation
- [x] Add to watchlist
- [x] Add to portfolio

Current note:
- Charting is implemented with custom painters and full-screen chart support.
- Stock detail analytics fields are shown when available from the backend; richer technical indicator coverage is still being refined.

#### 5. Watchlist
- [x] View all watched stocks
- [x] Set price alerts (above/below)
- [x] Set percentage change alerts
- [x] Add notes to each stock
- [x] Quick view of current prices
- [~] Push notifications for alerts

Current note:
- Watchlist management is complete.
- Local notification delivery for market and portfolio updates works; backend-triggered push alerts remain pending.

#### 6. Portfolio Management
- [x] Add/edit/delete assets
- [x] Track stocks, gold, silver, cash
- [x] View gain/loss per asset
- [ ] Portfolio diversification chart
- [ ] Asset allocation breakdown
- [~] Halal portfolio percentage
- [x] Sync prices with market data

Current note:
- Asset CRUD works and portfolio metrics refresh correctly.
- Analytics charts and deeper allocation breakdown remain future improvements.

#### 7. Portfolio Recommendations
- [x] Input investment capital
- [x] Select risk tolerance
- [x] Halal-only filter
- [x] View recommended allocations
- [x] Save recommendations
- [~] Compare with current portfolio

#### 8. Financial Tracking
- [x] Record income (dividends, profits)
- [x] Record expenses (fees, losses)
- [~] Category breakdown
- [ ] Monthly/yearly summaries
- [x] Export to CSV
- [ ] Export to PDF

Current note:
- CSV export is implemented.
- PDF reporting is not implemented yet.
- Category-aware analytics are present at a basic level, but a richer summary dashboard is pending.

#### 9. Alerts & Notifications
- [~] Price alerts
- [~] Percentage change alerts
- [~] Market open/close notifications
- [~] Portfolio milestone alerts
- [~] Daily market summary
- [ ] News notifications

Current note:
- Local notifications are present for market status and portfolio summary events.
- The full alerts ecosystem from the guide is still in progress.

#### 10. Settings & Preferences
- [x] Dark/Light theme
- [x] Language (English/Arabic)
- [x] Default risk tolerance
- [x] Halal-only preference
- [x] Notification preferences
- [x] Currency display
- [x] Data refresh interval

Current note:
- Settings and preferences are persisted correctly.
- Currency display and refresh interval controls are implemented and available in the current settings screen.

### Advanced Features

#### 11. Deep Analysis
- [~] Multi-source data aggregation
- [~] Technical analysis indicators
- [~] Risk assessment metrics
- [~] Trend signals
- [~] Historical performance

Current note:
- The backend provides premium analysis inputs and the mobile app consumes part of them.
- The current UI still does not expose the full depth of those signals consistently.

#### 12. Portfolio Health
- [~] Diversification score
- [~] Risk score
- [ ] Halal compliance score
- [ ] Performance score
- [~] Recommendations for improvement

Current note:
- Portfolio analysis is connected, but the complete “portfolio health dashboard” target is still pending.

#### 13. Social Features
- [x] Share portfolio (with privacy controls)
- [x] View shared portfolios
- [x] Password-protected sharing
- [x] Expiring share links

Current note:
- Users can create and manage share links.
- A richer mobile flow for viewing shared/public portfolios remains to be polished.

#### 14. Data Quality Indicators
- [x] Data freshness indicator
- [ ] Source reliability
- [~] Confidence scores
- [~] Warning for stale data

Current note:
- Update timestamps and fallback handling are present.
- A consistent app-wide data quality layer is still missing.

### App UI Styling and Experience
The current mobile app styling follows the reference investment dashboard design with:

- Gradient hero header on the dashboard, using teal/blue tones for a modern financial brand feel.
- Clear Arabic-first layout with right-to-left alignment, strong typography, and readable section spacing.
- Section cards with rounded corners and elevated surfaces for dashboard modules, market summary, and premium panels.
- Compact metric chips and status pills for quick status indicators such as market open/closed, subscription state, and update readiness.
- Icon-based shortcut tiles for fast navigation to market tools, watchlist, portfolio, alerts, gold price, and premium features.
- Responsive `ListView` layout that adapts to mobile screens and preserves padding for safe areas.
- Bottom navigation bar and drawer menu for stable app-wide navigation.
- Lightweight data cards for most active stocks, AI insights, trusted recommendations, and portfolio impact.
- Consistent call-to-action buttons for subscription, analysis access, and market updates.

Current note:
- The app now uses a polished dashboard experience instead of raw status text.
- Styling is aligned with the provided reference by using section cards, metric chips, consistent spacing, and a strong visual hierarchy.

---

## Web-Mobile Connection

### Architecture Overview

```
┌─────────────────┐     ┌──────────────────────────┐     ┌─────────────────┐
│   Web App       │     │   Node REST API          │     │  Mobile App     │
│   (Frontend)    │────▶│   invist.m2y.net/api     │◀────│   (Flutter)     │
└─────────────────┘     └──────────────────────────┘     └─────────────────┘
        │                          │                           │
        │                          │                           │
        ▼                          ▼                           ▼
┌──────────────────────┐   ┌───────────────────────────────┐
│ Shared App Database  │   │ EGXPY VPS Bridge (preferred) │
│ SQLite / hosting DB  │   │ http://72.61.137.86:8010     │
└──────────────────────┘   └───────────────────────────────┘
                                   │
                                   ▼
                        ┌───────────────────────────────┐
                        │ Fallback providers when needed│
                        │ Mubasher / TwelveData / EODHD │
                        └───────────────────────────────┘
```

> **Flutter should talk to the main Node API only.** The Node backend is responsible for choosing the datasource priority, updating the DB, and falling back if the VPS feed fails.

### Connection Methods

#### 1. Direct API Connection

The mobile app connects directly to the same REST API as the web application.

**Configuration:**
```dart
class ApiConfig {
  // Local development (Android emulator)
  static const String localEmulator = 'http://10.0.2.2:8100/api';
  
  // Local development (real device - use your computer's IP)
  static const String localDevice = 'http://192.168.1.x:8100/api';
  
  // Production
  static const String production = 'https://invist.m2y.net/api';
  
  static String get baseUrl {
    if (kDebugMode) {
      return localEmulator; // Switch to localDevice when testing on a phone
    }
    return production;
  }
}
```

#### 2. Shared Authentication

Both web and mobile use the same authentication system:

- Same user accounts
- Same API keys
- Same permissions

**Flow:**
1. User registers on web or mobile
2. Credentials stored in shared database
3. API key generated on login
4. API key works on both platforms

#### 3. Real-Time Data Sync

The current backend is **REST-first**. There is no WebSocket route implemented in `server.js` right now.

For near-real-time mobile updates, poll these endpoints while the screen is active:

- `GET /api/market/live-prices?tickers=ETEL,COMI` for quote widgets
- `GET /api/market/overview` for the dashboard
- `POST /api/user/assets/sync-prices` for portfolio screens

```dart
import 'dart:async';

class MarketPollingService {
  Timer? _timer;

  void start({
    required Future<void> Function() onRefresh,
    Duration interval = const Duration(seconds: 30),
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      await onRefresh();
    });
  }

  void stop() => _timer?.cancel();
}
```

#### 4. Deep Linking

Enable opening the app from web links:

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="invist.m2y.net" />
</intent-filter>
```

**iOS (ios/Runner/Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>egxinvestment</string>
        </array>
    </dict>
</array>
```

**Flutter Handling:**
```dart
// Use uni_links package
final initialLink = await getInitialLink();
if (initialLink != null) {
  // Parse link and navigate to relevant screen
  // e.g., egxinvestment://stock/ETEL
}
```

#### 5. Cross-Platform Session Sharing

For seamless experience between web and mobile:

**Option A: QR Code Login**
1. User logs in on web
2. Web generates QR code with temporary token
3. Mobile app scans QR code
4. Mobile exchanges token for API key

**Option B: Email Magic Link**
1. User requests login on mobile
2. Server sends email with magic link
3. Link opens mobile app with auth token

---

## Flutter Implementation

### Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── app_config.dart
│   ├── api_config.dart
│   └── theme_config.dart
├── models/
│   ├── stock.dart
│   ├── user.dart
│   ├── portfolio.dart
│   ├── watchlist_item.dart
│   └── market_index.dart
├── services/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── auth_api.dart
│   │   ├── stock_api.dart
│   │   ├── market_api.dart
│   │   ├── portfolio_api.dart
│   │   └── user_api.dart
│   ├── storage/
│   │   ├── secure_storage.dart
│   │   ├── local_storage.dart
│   │   └── cache_manager.dart
│   └── notifications/
│       └── push_notification_service.dart
├── providers/  # or blocs/
│   ├── auth_provider.dart
│   ├── stock_provider.dart
│   ├── market_provider.dart
│   ├── portfolio_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── main/
│   │   ├── home_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── splash_screen.dart
│   ├── stocks/
│   │   ├── stock_list_screen.dart
│   │   ├── stock_detail_screen.dart
│   │   ├── stock_search_screen.dart
│   │   └── stock_chart_screen.dart
│   ├── portfolio/
│   │   ├── portfolio_screen.dart
│   │   ├── add_asset_screen.dart
│   │   ├── recommendations_screen.dart
│   │   └── financial_summary_screen.dart
│   ├── watchlist/
│   │   └── watchlist_screen.dart
│   ├── market/
│   │   ├── market_overview_screen.dart
│   │   └── indices_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   ├── common/
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   └── empty_state_widget.dart
│   ├── stocks/
│   │   ├── stock_card.dart
│   │   ├── stock_price_chart.dart
│   │   └── stock_detail_header.dart
│   ├── portfolio/
│   │   ├── portfolio_summary_card.dart
│   │   ├── asset_list_tile.dart
│   │   └── allocation_chart.dart
│   └── market/
│       ├── index_card.dart
│       ├── top_movers_section.dart
│       └── market_status_indicator.dart
└── utils/
    ├── constants.dart
    ├── validators.dart
    ├── formatters.dart
    └── helpers.dart
```

### API Service Implementation

```dart
// lib/services/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static String get baseUrl => ApiConfig.baseUrl;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get stored API key
        final apiKey = await _secureStorage.read(key: 'api_key');
        if (apiKey != null) {
          options.headers['X-API-Key'] = apiKey;
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle unauthorized - redirect to login
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
}
```

```dart
// lib/services/api/stock_api.dart
class StockApi {
  final ApiClient _client;
  
  StockApi(this._client);
  
  Future<List<Stock>> getStocks({
    String? query,
    String searchField = 'all',
    String? sector,
    String? index,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _client.dio.get('/stocks', queryParameters: {
      if (query != null && query.isNotEmpty) 'query': query,
      'search_field': searchField,
      if (sector != null) 'sector': sector,
      if (index != null) 'index': index,
      'page': page,
      'page_size': pageSize,
    });
    
    final List<dynamic> stocksJson = response.data['stocks'];
    return stocksJson.map((json) => Stock.fromJson(json)).toList();
  }
  
  Future<Stock> getStock(String ticker) async {
    final response = await _client.dio.get('/stocks/$ticker');
    return Stock.fromJson(response.data['data']);
  }
  
  Future<List<Stock>> searchStocks(
    String query, {
    String? sector,
    double? minPrice,
    double? maxPrice,
  }) async {
    final response = await _client.dio.get('/stocks/search/$query', queryParameters: {
      if (sector != null) 'sector': sector,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    });
    
    final List<dynamic> results = response.data['results'];
    return results.map((json) => Stock.fromJson(json)).toList();
  }
  
  Future<StockHistory> getStockHistory(String ticker, {int days = 30}) async {
    final response = await _client.dio.get('/stocks/$ticker/history', queryParameters: {
      'days': days,
    });
    return StockHistory.fromJson(response.data);
  }
  
  Future<StockRecommendation> getRecommendation(String ticker) async {
    final response = await _client.dio.get('/stocks/$ticker/recommendation');
    return StockRecommendation.fromJson(response.data);
  }
}
```

### Data Models

```dart
// lib/models/stock.dart
class Stock {
  final int id;
  final String ticker;
  final String name;
  final String? nameAr;
  final double? currentPrice;
  final double? previousClose;
  final double? priceChange;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final int? volume;
  final double? marketCap;
  final double? peRatio;
  final double? pbRatio;
  final double? dividendYield;
  final double? eps;
  final double? roe;
  final double? debtToEquity;
  final String? sector;
  final String? industry;
  final bool isHalal;
  final String complianceStatus;
  final String? complianceNote;
  final DateTime? lastUpdate;
  
  Stock({
    required this.id,
    required this.ticker,
    required this.name,
    this.nameAr,
    this.currentPrice,
    this.previousClose,
    this.priceChange,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.marketCap,
    this.peRatio,
    this.pbRatio,
    this.dividendYield,
    this.eps,
    this.roe,
    this.debtToEquity,
    this.sector,
    this.industry,
    required this.isHalal,
    required this.complianceStatus,
    this.complianceNote,
    this.lastUpdate,
  });
  
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      ticker: json['ticker'],
      name: json['name'],
      nameAr: json['name_ar'],
      currentPrice: json['current_price']?.toDouble(),
      previousClose: json['previous_close']?.toDouble(),
      priceChange: json['price_change']?.toDouble(),
      openPrice: json['open_price']?.toDouble(),
      highPrice: json['high_price']?.toDouble(),
      lowPrice: json['low_price']?.toDouble(),
      volume: json['volume'],
      marketCap: json['market_cap']?.toDouble(),
      peRatio: json['pe_ratio']?.toDouble(),
      pbRatio: json['pb_ratio']?.toDouble(),
      dividendYield: json['dividend_yield']?.toDouble(),
      eps: json['eps']?.toDouble(),
      roe: json['roe']?.toDouble(),
      debtToEquity: json['debt_to_equity']?.toDouble(),
      sector: json['sector'],
      industry: json['industry'],
      isHalal: json['is_halal'] ?? false,
      complianceStatus: json['compliance_status'] ?? 'unknown',
      complianceNote: json['compliance_note'],
      lastUpdate: json['last_update'] != null 
          ? DateTime.parse(json['last_update']) 
          : null,
    );
  }
  
  double? get priceChangePercent {
    if (previousClose != null && previousClose! > 0 && priceChange != null) {
      return (priceChange! / previousClose!) * 100;
    }
    return null;
  }
}
```

---

## State Management

The current repository uses a shared `InvestmentController` built on `ChangeNotifier`. The controller holds app state for authentication, market payloads, portfolio data, watchlist items, and user preferences, and it notifies UI listeners when data changes.

### Current implementation

- `lib/controllers/investment_controller.dart` is the central state hub.
- `main.dart` constructs `InvestmentApp` with a single `InvestmentController` instance.
- UI widgets update through controller state and `notifyListeners()` rather than Riverpod or Bloc.

### Example pattern

```dart
// lib/controllers/investment_controller.dart
class InvestmentController extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool loading = false;
  AuthSession? session;
  Map<String, dynamic>? overview;
  List<WatchlistItem> watchlist = [];
  bool halalOnly = false;
  bool darkMode = false;
  bool biometricEnabled = false;

  Future<void> initialize() async {
    await _loadPreferences();
    session = await _api.restoreSession();
    await refreshAll(showLoader: false);
    notifyListeners();
  }

  void setHalalOnly(bool value) {
    halalOnly = value;
    notifyListeners();
  }
}
```

This is the current live state model for the app.

---

## Offline Support

### Current implementation

The existing mobile app does not include a dedicated offline persistence layer for stock or portfolio data.

The app currently stores:

- user preferences in `SharedPreferences`
- secure API session tokens in `flutter_secure_storage`
- saved recommendation snapshots in `SharedPreferences`

### Pending work

- Add an offline cache for market data, stock history and assets
- Implement stale-data fallback when network connectivity is missing
- Persist watchlist and portfolio details to a local store such as SQLite, Hive, or local JSON

---

## Push Notifications

### Current implementation

The app currently uses `flutter_local_notifications` for local notifications. There is no Firebase Cloud Messaging integration in the current repo.

Notifications are initialized in `main.dart` and used for:

- onboarding / first-launch reminders
- market status updates
- portfolio summary updates

### Local Notification Service

```dart
// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'investment_updates',
    'تحديثات الاستثمار',
    description: 'تحديثات الحالة والتذكيرات لمستخدمي تطبيق الاستثمار.',
    importance: Importance.high,
  );

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(settings);

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(_channel);

    _ready = true;
  }

  Future<void> showStatusNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'investment_updates',
          'تحديثات الاستثمار',
          channelDescription: 'تحديثات الحالة والتذكيرات لمستخدمي تطبيق الاستثمار.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> maybeNotifyMarketStatus(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMessage = prefs.getString('last_market_message');
    if (lastMessage == message) return;

    await showStatusNotification(title: 'تحديث حالة السوق', body: message);
    await prefs.setString('last_market_message', message);
  }

  Future<void> maybeNotifyInvestmentSummary(Map<String, dynamic> summary) async {
    final totalValue = toDouble(summary['total_value']);
    final gainLoss = toDouble(summary['total_gain_loss']);
    final message = gainLoss >= 0
        ? 'قيمة المحفظة ${totalValue.toStringAsFixed(0)} جنيه مع ربح ${gainLoss.toStringAsFixed(0)} جنيه.'
        : 'قيمة المحفظة ${totalValue.toStringAsFixed(0)} جنيه مع خسارة ${gainLoss.abs().toStringAsFixed(0)} جنيه.';

    final prefs = await SharedPreferences.getInstance();
    final lastMessage = prefs.getString('last_investment_message');
    if (lastMessage == message) return;

    await showStatusNotification(
      title: 'تغيرت حالة الاستثمار',
      body: message,
    );
    await prefs.setString('last_investment_message', message);
  }
}
```

### Notification types (planned)

| Type | Description |
|------|-------------|
| `market_status` | Market open/close updates |
| `investment_summary` | Portfolio summary changes |
| `price_alert` | Price threshold alerts (local watchlist triggers) |

---

## Security Best Practices

### 1. Secure Storage

```dart
// Use flutter_secure_storage for sensitive data
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: 'api_key', value: apiKey);
  }
  
  static Future<String?> getApiKey() async {
    return await _storage.read(key: 'api_key');
  }
  
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: 'api_key');
  }
}
```

### 2. Certificate Pinning (Production)

```dart
// Add to Dio configuration for production
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

Dio createSecureDio() {
  final dio = Dio();
  
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) {
      // Implement certificate pinning
      return cert.sha256 == expectedSHA256;
    };
    return client;
  };
  
  return dio;
}
```

### 3. API Key Protection

```dart
// Never hardcode API keys in production
// Use environment variables or secure config

// .env file (add to .gitignore)
// API_KEY=your_production_api_key

// Use flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(MyApp());
}

String get apiKey {
  if (kDebugMode) {
    return 'dev_api_key';
  }
  return dotenv.env['API_KEY'] ?? '';
}
```

### 4. Request Signing (Optional)

```dart
// Add request signature for additional security
import 'package:crypto/crypto.dart';

String signRequest(String method, String path, String timestamp, String body) {
  final message = '$method:$path:$timestamp:$body';
  final key = utf8.encode(apiSecret);
  final bytes = utf8.encode(message);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(bytes);
  return digest.toString();
}
```

---

## Complete API Reference Table

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health` | GET | No | Health check |
| `/api` | GET | No | API info |
| **Authentication** | | | |
| `/api/auth/register` | POST | No | Register new user |
| `/api/auth/login` | POST | No | Login user and return `api_key` |
| `/api/auth/me` | GET | Key + User | Get current user |
| `/api/auth/logout` | POST | Key + User | Revoke current API key |
| `/api/auth/google/config` | GET | No | Google OAuth config |
| `/api/auth/google` | POST | No | Google OAuth login/register |
| **Stocks** | | | |
| `/api/stocks` | GET | Optional | List stocks with filters |
| `/api/stocks/{ticker}` | GET | Optional | Get stock by ticker |
| `/api/stocks/search/{query}` | GET | Optional | Search stocks |
| `/api/stocks/{ticker}/history` | GET | Optional | Get price history |
| `/api/stocks/{ticker}/recommendation` | GET | Optional | Get stock recommendation / analysis |
| **Market** | | | |
| `/api/market/overview` | GET | Optional | Market overview |
| `/api/market/indices` | GET | Optional | All market indices |
| `/api/market/indices/{symbol}` | GET | Optional | Specific index |
| `/api/market/status` | GET | Optional | Market status |
| `/api/market/update-status` | GET | Optional | Data update status |
| `/api/market/update-history` | GET | Optional | Update history |
| `/api/market/check-update-allowed` | POST | Optional | Check schedule gate |
| `/api/market/update-data` | POST | Key | Trigger stock data update |
| `/api/market/refresh-check` | GET | Optional | Check if refresh is needed |
| `/api/market/live-prices` | GET | Key | Fetch near-real-time prices |
| `/api/market/recommendations/trusted-sources` | GET | Key | Ranked recommendations |
| `/api/market/recommendations/ai-insights` | GET | Key | AI market insights |
| `/api/market/recommendations/gemini-assistant` | POST | Key + User | Personalized portfolio advice |
| **Portfolio** | | | |
| `/api/portfolio/recommend` | GET | Key | Portfolio recommendations |
| `/api/portfolio/recommend/advanced` | POST | Key | Advanced recommendations |
| **User Data** | | | |
| `/api/user/watchlist` | GET | Key + User | Get watchlist |
| `/api/user/watchlist` | POST | Key + User | Add to watchlist |
| `/api/user/watchlist/{id}` | PUT | Key + User | Update watchlist item |
| `/api/user/watchlist/{id}` | DELETE | Key + User | Remove from watchlist |
| `/api/user/assets` | GET | Key + User | Get user assets |
| `/api/user/assets` | POST | Key + User | Create asset |
| `/api/user/assets/{id}` | PUT | Key + User | Update asset |
| `/api/user/assets/{id}` | DELETE | Key + User | Delete asset |
| `/api/user/assets/sync-prices` | POST | Key + User | Sync asset prices |
| `/api/user/portfolio-impact` | GET | Key + User | Portfolio alerts / impact view |
| `/api/user/financial-summary` | GET | Key + User | Financial summary |
| `/api/user/income-expense` | GET | Key + User | Get transactions |
| `/api/user/income-expense` | POST | Key + User | Create transaction |
| `/api/user/income-expense/{id}` | PUT | Key + User | Update transaction |
| `/api/user/income-expense/{id}` | DELETE | Key + User | Delete transaction |
| `/api/user/share-portfolio` | POST | Key + User | Share portfolio |
| `/api/user/shared-portfolio/{code}` | GET | No | View shared portfolio |
| `/api/user/my-shares` | GET | Key + User | Get user's shares |
| `/api/user/share/{id}` | DELETE | Key + User | Revoke share |
| **Payment** | | | |
| `/api/payment/plans` | GET | No | Subscription plans |
| `/api/payment/subscription` | GET | Key + User | Current subscription |
| `/api/payment/initiate` | POST | Key + User | Start Paymob payment |
| `/api/payment/callback` | POST | No | Paymob webhook |
| `/api/payment/callback` | GET | No | Redirect callback |

---

## Error Handling

### Standard Error Response

```json
{
  "detail": "Error message here"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid/missing API key |
| 403 | Forbidden - Not allowed |
| 404 | Not Found |
| 410 | Gone - Expired resource |
| 500 | Internal Server Error |

### Flutter Error Handling

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    final message = data is Map ? (data['detail'] ?? 'Unknown error') : 'Unknown error';
    return ApiException(response.statusCode ?? 0, message);
  }
}

// Usage in API client
Future<T> _handleRequest<T>(Future<Response> Function() request, T Function(dynamic) parser) async {
  try {
    final response = await request();
    return parser(response.data);
  } on DioException catch (e) {
    if (e.response != null) {
      throw ApiException.fromResponse(e.response!);
    }
    throw ApiException(0, 'Network error: ${e.message}');
  }
}
```

---

## Testing

### Unit Tests

```dart
// test/services/stock_api_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([Dio])
void main() {
  late StockApi stockApi;
  late MockDio mockDio;
  
  setUp(() {
    mockDio = MockDio();
    stockApi = StockApi(ApiClient().._dio = mockDio);
  });
  
  test('getStock returns Stock for valid ticker', () async {
    when(mockDio.get('/stocks/ETEL')).thenAnswer(
      (_) async => Response(
        data: {'data': {'ticker': 'ETEL', 'name': 'Telecom Egypt'}},
        statusCode: 200,
      ),
    );
    
    final stock = await stockApi.getStock('ETEL');
    
    expect(stock.ticker, 'ETEL');
    expect(stock.name, 'Telecom Egypt');
  });
}
```

### Integration Tests

```dart
// integration_test/stock_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Stock search and detail flow', (tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to search
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    
    // Search for stock
    await tester.enterText(find.byType(TextField), 'ETEL');
    await tester.pumpAndSettle();
    
    // Verify results
    expect(find.text('Telecom Egypt'), findsOneWidget);
    
    // Tap on stock
    await tester.tap(find.text('Telecom Egypt'));
    await tester.pumpAndSettle();
    
    // Verify detail screen
    expect(find.text('ETEL'), findsOneWidget);
  });
}
```

---

## Deployment Checklist

### Pre-Production

- [x] Update API base URL to production for release builds (`https://invist.m2y.net/api`)
- [x] Remove debug API keys; the app now uses the runtime `api_key` returned by the backend
- [x] Verify localhost auth basics (`/health`, `/api/auth/register`, `/api/auth/me`, `/api/payment/subscription`)
- [ ] Set production Google auth env values: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI`, `GOOGLE_ANDROID_CLIENT_IDS`
- [ ] Confirm Android release `SHA-1` and `SHA-256` are registered for Google Sign-In
- [ ] Retest one real Google sign-in on a release/dev Android build
- [ ] Enable certificate pinning
- [ ] Configure ProGuard/R8 (Android release)
- [ ] Configure push notifications if required (**optional**; Firebase is not required for auth)
- [ ] Test on multiple physical devices
- [ ] Performance profiling
- [ ] Security audit

### App Store

- [ ] Prepare app icons
- [ ] Prepare screenshots
- [ ] Write app description (EN/AR)
- [ ] Set up app signing
- [ ] Configure in-app purchases (if any)
- [ ] Privacy policy URL
- [ ] Support URL

### Play Store

- [ ] Prepare app icons
- [ ] Prepare feature graphics
- [ ] Write app description (EN/AR)
- [ ] Content rating questionnaire
- [ ] Target audience settings
- [ ] Privacy policy URL

---

## Support & Resources

- **API Documentation**: `/docs/FLUTTER_API_DOCUMENTATION.md`
- **Backend Source**: `/backend`
- **Flutter Documentation**: https://docs.flutter.dev
- **Dio Package**: https://pub.dev/packages/dio
- **Riverpod**: https://riverpod.dev
- **Firebase Flutter**: https://firebase.flutter.dev

---

*Last Updated: April 15, 2026*
