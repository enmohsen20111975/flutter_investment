| Feature | API Endpoint | Method |
|---------|-------------|--------|
| Login | `/api/auth/login` | POST |
| Register | `/api/auth/register` | POST |
| User Profile | `/api/user/profile` | GET |
| Market Overview | `/api/market/overview` | GET |
| Live Stock Data | `/api/market/live-data` | GET |
| Gold/Silver Prices | `/api/market/gold` | GET |
| Gold History (Chart) | `/api/market/gold/history?karat=24&days=90` | GET |
| Currency Rates | `/api/market/currency` | GET |
| Currency History (Chart) | `/api/market/currency/history?code=USD&days=90` | GET |
| Stock List | `/api/stocks` | GET |
| Stock Search | `/api/stocks/search?q=xxx` | GET |
| Stock Detail | `/api/stocks/[ticker]` | GET |
| Stock Chart Data (OHLCV) | `/api/stocks/[ticker]/history?days=180` | GET |
| Stock News | `/api/stocks/[ticker]/news` | GET |
| Stock Analysis | `/api/stocks/[ticker]/professional-analysis` | GET |
| Sectors | `/api/sectors` | GET |
| Portfolio Holdings | `/api/portfolio` | GET/POST/PUT/DELETE |
| Finance Assets | `/api/finance/assets` | GET/POST/PUT/DELETE |
| Finance Reports | `/api/finance/reports` | GET |
| Transactions | `/api/finance/transactions` | GET/POST/PUT/DELETE |
| Obligations | `/api/finance/obligations` | GET/POST/PUT/DELETE |
| Watchlist | `/api/watchlist` | GET/POST/DELETE |
| Recommendations | `/api/v2/recommend` | GET/POST |
| Subscription Plans | `/api/subscription/plans` | GET |
| Current Subscription | `/api/subscription/current` | GET |