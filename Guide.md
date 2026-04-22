# EGX Investment Platform - Flutter Mobile Application Guide

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
10. [Web-Mobile Connection](#web-mobile-connection)
11. [Flutter Implementation](#flutter-implementation)
12. [State Management](#state-management)
13. [Offline Support](#offline-support)
14. [Push Notifications](#push-notifications)
15. [Security Best Practices](#security-best-practices)
16. [Current Flutter Status](#current-flutter-status)

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
| State Management | Riverpod / BLoC |
| HTTP Client | Dio / http package |
| Local Storage | SharedPreferences / Hive / SQLite |
| Push Notifications | Firebase Cloud Messaging |
| Charts | fl_chart / syncfusion_flutter_charts |

---

## Current Flutter Status

> Updated on April 6, 2026 for the current Flutter workspace in `d:\My WebStie Applications\Flutter\investment`.
> This section reflects the implemented mobile app, not just the theoretical backend capability.

### Implemented in the current Flutter app

- Arabic UI with RTL layout across the app.
- Automatic ads behavior:
  - Banner ad appears across all screens.
  - Extra inline banners now appear inside key tabs instead of relying on a single bottom banner only.
  - Interstitial ad appears automatically on some tab switches.
  - Manual ad button was removed.
- Authentication with API key persistence and session restore.
- Website-connected authentication:
  - Login using `/api/auth/login`
  - Create a new website account using `/api/auth/register`
  - Keep the session saved on the mobile app
  - Optional biometric login using fingerprint / Face ID after enabling it on-device
- Dashboard market overview:
  - Market status
  - EGX30 summary
  - Gainers and losers
  - Most active stocks
  - AI market insights
  - Trusted-source recommendations
  - Portfolio impact summary
  - Open stock detail directly from movers, active stocks, and recommendation lists
- Stocks screen:
  - Search with proper empty-result handling instead of falling back to all stocks
  - Local fallback filtering if remote search returns nothing for already-loaded stocks
  - Recent searches
  - Halal-only client-side filter
  - Full stock list from `/api/stocks`
  - Full stock detail page
  - Candlestick and line price charts
  - Stock analysis page using:
    - `/api/stocks/{ticker}`
    - `/api/stocks/{ticker}/recommendation`
    - `/api/stocks/{ticker}/history`
- Watchlist:
  - Load watchlist
  - Add stock
  - Remove stock
  - Edit watchlist alerts and notes from mobile
  - Open stock detail directly from watchlist items
- Portfolio:
  - Financial summary
  - Portfolio impact
  - Gemini assistant / personalized actionable portfolio advice
  - Recommendations
  - Assets list
  - Open stock detail from stock assets and recommendation rows
  - Add asset
  - Sync asset prices manually from mobile
  - Delete asset
  - Income/expense list
  - Add transaction
  - Delete transaction
  - Budget control summary derived from transactions
- Settings / More:
  - Subscription plans
  - Current subscription
  - Start payment flow through Paymob iframe URL
  - Create portfolio share
  - View created shares
  - Revoke share
  - Open a mobile learning center with courses, simulation, candlestick patterns, quiz, and achievements
  - Open market tools page with market status, indices, update status, refresh check, and live prices

### Confirmed in backend and connected from Flutter

- `/api/auth/login`
- `/api/auth/me`
- `/api/auth/logout`
- `/api/market/overview`
- `/api/market/recommendations/trusted-sources`
- `/api/market/recommendations/ai-insights`
- `/api/stocks`
- `/api/stocks/search/{query}`
- `/api/stocks/{ticker}/history`
- `/api/stocks/{ticker}/recommendation`
- `/api/user/watchlist`
- `/api/user/assets`
- `/api/user/financial-summary`
- `/api/user/portfolio-impact`
- `/api/user/income-expense`
- `/api/user/share-portfolio`
- `/api/user/my-shares`
- `/api/user/share/{id}`
- `/api/payment/plans`
- `/api/payment/subscription`
- `/api/payment/initiate`

### Present in guide or frontend examples but not confirmed in the current backend scan

- News endpoints
- Scheduled advice endpoints
- Learning progress endpoints
- User settings endpoints beyond local mobile preferences

These should not be treated as available for the current mobile app until the backend routes are verified in the deployed server code.

### Notes for future work

- If a newer backend version is provided with news, alerts, learning progress, or richer user settings routes, the Flutter app can be extended further without changing the current architecture.
- The current app uses a controller-based structure, not Riverpod/BLoC, even though this guide includes reference examples for those patterns.

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
    "is_open": true,
    "current_time_cairo": "2026-03-06 13:00:00 EET",
    "trading_hours": "10:00 AM - 2:30 PM Cairo time",
    "message": "Market is open"
  },
  "summary": {
    "total_stocks": 100,
    "gainers": 45,
    "losers": 35,
    "unchanged": 20,
    "egx30_stocks": 30,
    "egx70_stocks": 70,
    "egx100_stocks": 100,
    "egx30_value": 18500.50
  },
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
  "top_gainers": [...],
  "top_losers": [...],
  "most_active": [...],
  "last_updated": "2026-03-06T13:00:00"
}
```

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
  "is_open": true,
  "current_time_cairo": "2026-03-06 13:00:00 EET",
  "trading_hours": "10:00 AM - 2:30 PM Cairo time",
  "trading_days": "Sunday - Thursday",
  "message": "Market is open. Closes at 14:30 Cairo time."
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
  "generated_at": "2026-03-06T13:00:00"
}
```

---

### 13. Gemini Portfolio Assistant

```http
POST /api/market/recommendations/gemini-assistant
```

**Headers:** user `X-API-Key` required

**Response:** includes `market_insights`, `portfolio_lots`, `deterministic_advice`, `gemini_response`, and `generated_at`.

---

## Portfolio APIs

### Base URL: `/api/portfolio`

> Portfolio recommendation routes require `X-API-Key`.

### 1. Get Portfolio Recommendations

```http
GET /api/portfolio/recommend?capital=100000&risk=medium&max_stocks=5&sectors=Telecommunications,Banking
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| capital | float | Yes | - | Investment capital (EGP) |
| risk | string | No | medium | Risk level: `low`, `medium`, `high` |
| max_stocks | integer | No | 10 | Maximum stocks to return |
| sectors | string | No | null | Comma-separated sectors |

**Response (200):**
```json
{
  "capital": 100000.0,
  "risk_level": "medium",
  "recommendations": [
    {
      "ticker": "ETEL",
      "name": "Telecom Egypt",
      "current_price": 25.50,
      "allocation_amount": 25000.0,
      "allocation_percent": 25.0,
      "recommended_shares": 980,
      "score": 85,
      "sector": "Telecommunications"
    }
  ],
  "total_stocks": 5,
  "generated_at": "2026-03-06T13:00:00"
}
```

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
  "max_stocks": 10,
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

## Mobile App Features

### Core Features

#### 1. Authentication & Onboarding
- [ ] User registration with email/username
- [ ] Login with credentials
- [ ] Google OAuth integration
- [ ] Biometric authentication (Face ID / Touch ID)
- [ ] PIN code for quick access
- [ ] Password reset functionality
- [ ] Session management

#### 2. Dashboard
- [ ] Market overview summary
- [ ] Portfolio value at a glance
- [ ] Today's gainers/losers
- [ ] Quick actions (search, add to watchlist)
- [ ] Market status indicator (open/closed)
- [ ] Last data update timestamp

#### 3. Stock Search & Discovery
- [ ] Search by ticker or company name
- [ ] Arabic name search support
- [ ] Filter by sector, halal status, price range
- [ ] Sort by various metrics
- [ ] Recent searches
- [ ] Trending stocks

#### 4. Stock Detail View
- [ ] Current price and change
- [ ] Price chart (1D, 1W, 1M, 3M, 1Y)
- [ ] Key statistics (P/E, ROE, dividend yield)
- [ ] Technical indicators (RSI, MA)
- [ ] Compliance status (Halal/Haram)
- [ ] AI recommendation
- [ ] Add to watchlist
- [ ] Add to portfolio

#### 5. Watchlist
- [ ] View all watched stocks
- [ ] Set price alerts (above/below)
- [ ] Set percentage change alerts
- [ ] Add notes to each stock
- [ ] Quick view of current prices
- [ ] Push notifications for alerts

#### 6. Portfolio Management
- [ ] Add/edit/delete assets
- [ ] Track stocks, gold, silver, cash
- [ ] View gain/loss per asset
- [ ] Portfolio diversification chart
- [ ] Asset allocation breakdown
- [ ] Halal portfolio percentage
- [ ] Sync prices with market data

#### 7. Portfolio Recommendations
- [ ] Input investment capital
- [ ] Select risk tolerance
- [ ] Halal-only filter
- [ ] View recommended allocations
- [ ] Save recommendations
- [ ] Compare with current portfolio

#### 8. Financial Tracking
- [ ] Record income (dividends, profits)
- [ ] Record expenses (fees, losses)
- [ ] Category breakdown
- [ ] Monthly/yearly summaries
- [ ] Export to CSV/PDF

#### 9. Alerts & Notifications
- [ ] Price alerts
- [ ] Percentage change alerts
- [ ] Market open/close notifications
- [ ] Portfolio milestone alerts
- [ ] Daily market summary
- [ ] News notifications

#### 10. Settings & Preferences
- [ ] Dark/Light theme
- [ ] Language (English/Arabic)
- [ ] Default risk tolerance
- [ ] Halal-only preference
- [ ] Notification preferences
- [ ] Currency display
- [ ] Data refresh interval

### Advanced Features

#### 11. Deep Analysis
- [ ] Multi-source data aggregation
- [ ] Technical analysis indicators
- [ ] Risk assessment metrics
- [ ] Trend signals
- [ ] Historical performance

#### 12. Portfolio Health
- [ ] Diversification score
- [ ] Risk score
- [ ] Halal compliance score
- [ ] Performance score
- [ ] Recommendations for improvement

#### 13. Social Features
- [ ] Share portfolio (with privacy controls)
- [ ] View shared portfolios
- [ ] Password-protected sharing
- [ ] Expiring share links

#### 14. Data Quality Indicators
- [ ] Data freshness indicator
- [ ] Source reliability
- [ ] Confidence scores
- [ ] Warning for stale data

---

## Web-Mobile Connection

### Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web App       │     │   REST API      │     │  Mobile App     │
│   (Frontend)    │────▶│   Server        │◀────│   (Flutter)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Shared Database (SQLite)                     │
│                  egx_investment.db                               │
└─────────────────────────────────────────────────────────────────┘
```

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

### Using Riverpod

```dart
// lib/providers/stock_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// API Provider
final stockApiProvider = Provider<StockApi>((ref) {
  return StockApi(ref.watch(apiClientProvider));
});

// Stocks List Provider
final stocksProvider = FutureProvider.family<List<Stock>, StocksFilter>((ref, filter) async {
  final api = ref.watch(stockApiProvider);
  return api.getStocks(
    halalOnly: filter.halalOnly,
    sector: filter.sector,
    page: filter.page,
    pageSize: filter.pageSize,
  );
});

// Single Stock Provider
final stockProvider = FutureProvider.family<Stock, String>((ref, ticker) async {
  final api = ref.watch(stockApiProvider);
  return api.getStock(ticker);
});

// Search Provider
final stockSearchProvider = FutureProvider.family<List<Stock>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final api = ref.watch(stockApiProvider);
  return api.searchStocks(query);
});

// Filter class
class StocksFilter {
  final bool halalOnly;
  final String? sector;
  final int page;
  final int pageSize;
  
  StocksFilter({
    this.halalOnly = false,
    this.sector,
    this.page = 1,
    this.pageSize = 50,
  });
}
```

### Using BLoC

```dart
// lib/blocs/stock/stock_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class StockEvent {}
class LoadStocks extends StockEvent {
  final bool halalOnly;
  final String? sector;
  LoadStocks({this.halalOnly = false, this.sector});
}
class SearchStocks extends StockEvent {
  final String query;
  SearchStocks(this.query);
}
class LoadStockDetail extends StockEvent {
  final String ticker;
  LoadStockDetail(this.ticker);
}

abstract class StockState {}
class StockInitial extends StockState {}
class StockLoading extends StockState {}
class StocksLoaded extends StockState {
  final List<Stock> stocks;
  StocksLoaded(this.stocks);
}
class StockDetailLoaded extends StockState {
  final Stock stock;
  StockDetailLoaded(this.stock);
}
class StockError extends StockState {
  final String message;
  StockError(this.message);
}

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockApi stockApi;
  
  StockBloc(this.stockApi) : super(StockInitial()) {
    on<LoadStocks>(_onLoadStocks);
    on<SearchStocks>(_onSearchStocks);
    on<LoadStockDetail>(_onLoadStockDetail);
  }
  
  Future<void> _onLoadStocks(LoadStocks event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final stocks = await stockApi.getStocks(
        halalOnly: event.halalOnly,
        sector: event.sector,
      );
      emit(StocksLoaded(stocks));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }
  
  Future<void> _onSearchStocks(SearchStocks event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final stocks = await stockApi.searchStocks(event.query);
      emit(StocksLoaded(stocks));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }
  
  Future<void> _onLoadStockDetail(LoadStockDetail event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final stock = await stockApi.getStock(event.ticker);
      emit(StockDetailLoaded(stock));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }
}
```

---

## Offline Support

### Caching Strategy

```dart
// lib/services/storage/cache_manager.dart
import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static const String stocksBox = 'stocks_cache';
  static const String marketBox = 'market_cache';
  static const Duration defaultCacheDuration = Duration(hours: 1);
  
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(stocksBox);
    await Hive.openBox(marketBox);
  }
  
  Future<void> cacheStocks(List<Stock> stocks) async {
    final box = Hive.box(stocksBox);
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'stocks': stocks.map((s) => s.toJson()).toList(),
    };
    await box.put('stocks_list', data);
  }
  
  Future<List<Stock>?> getCachedStocks() async {
    final box = Hive.box(stocksBox);
    final data = box.get('stocks_list');
    if (data == null) return null;
    
    final timestamp = DateTime.parse(data['timestamp']);
    if (DateTime.now().difference(timestamp) > defaultCacheDuration) {
      return null; // Cache expired
    }
    
    return (data['stocks'] as List)
        .map((json) => Stock.fromJson(json))
        .toList();
  }
  
  Future<void> cacheStockDetail(Stock stock) async {
    final box = Hive.box(stocksBox);
    await box.put('stock_${stock.ticker}', {
      'timestamp': DateTime.now().toIso8601String(),
      'data': stock.toJson(),
    });
  }
  
  Future<Stock?> getCachedStockDetail(String ticker) async {
    final box = Hive.box(stocksBox);
    final data = box.get('stock_$ticker');
    if (data == null) return null;
    
    final timestamp = DateTime.parse(data['timestamp']);
    if (DateTime.now().difference(timestamp) > defaultCacheDuration) {
      return null;
    }
    
    return Stock.fromJson(data['data']);
  }
}
```

### Offline-Aware Repository

```dart
// lib/repositories/stock_repository.dart
class StockRepository {
  final StockApi _api;
  final CacheManager _cache;
  
  StockRepository(this._api, this._cache);
  
  Future<List<Stock>> getStocks({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cached = await _cache.getCachedStocks();
      if (cached != null) return cached;
    }
    
    try {
      // Fetch from API
      final stocks = await _api.getStocks();
      // Cache the result
      await _cache.cacheStocks(stocks);
      return stocks;
    } catch (e) {
      // If API fails, try cache even if expired
      final cached = await _cache.getCachedStocks();
      if (cached != null) return cached;
      rethrow;
    }
  }
}
```

---

## Push Notifications

### Firebase Setup

```dart
// lib/services/notifications/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get token
    final token = await _fcm.getToken();
    print('FCM Token: $token');
    // Send token to server for user-specific notifications
    
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    await _localNotifications.initialize(settings);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }
  
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'egx_investment',
      'EGX Investment',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }
  
  Future<void> subscribeToStockAlerts(String ticker) async {
    await _fcm.subscribeToTopic('stock_$ticker');
  }
  
  Future<void> unsubscribeFromStockAlerts(String ticker) async {
    await _fcm.unsubscribeFromTopic('stock_$ticker');
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}
```

### Notification Types

| Type | Description | Data Payload |
|------|-------------|--------------|
| `price_alert` | Stock reached target price | `{ticker, price, target}` |
| `change_alert` | Significant price change | `{ticker, change_percent}` |
| `market_open` | Market opened | `{}` |
| `market_close` | Market closed | `{}` |
| `portfolio_update` | Portfolio milestone | `{type, value}` |
| `daily_summary` | Daily market summary | `{gainers, losers}` |

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

- [ ] Update API base URL to production
- [ ] Remove debug API keys
- [ ] Enable certificate pinning
- [ ] Configure ProGuard/R8 (Android)
- [ ] Set up Firebase project
- [ ] Configure push notifications
- [ ] Test on multiple devices
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

*Last Updated: April 6, 2026*
