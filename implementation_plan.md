# Phase 3: Bug Fixes & UX Improvements

## Summary

Six issues identified from screenshots and user feedback. All require targeted fixes.

---

## Issue Analysis

### 1. 🔒 Security Lock — Make Opt-in (Not Forced)
- **Problem**: App blocks immediately with biometric on launch even when not enrolled. If the device has no biometric/PIN, the dialog hangs with no response.
- **Fix**:
  - `SecurityWrapper`: Change `_isLocked = false` as **default**. Only lock if the controller's `biometricEnabled` flag is `true`.
  - `SecurityService.authenticate()`: If device has no biometric enrolled (`notEnrolled` / `passcodeNotSet`), **bypass** and return `true` gracefully.
  - Expose a **Settings toggle** that lets the user opt into the lock (already in settings — just fix default).

### 2. 📊 Gold/Metals Data Not Showing Everywhere
- **Problem**: Dashboard shows `-- ج.م` for gold because `marketMetals` map nesting differs.
- **Fix**: Normalize the metals extraction helper so `dashboard_tab.dart`, `portfolio_tab.dart` use the same safe path: `metals['metals']` → fallback → root-level keys.

### 3. 🚫 Remove Data Source Labels
- **Problem**: "مصدر السعر: gold-api+open-er-api" leaks internal API names to users.
- **Fix**: Remove `_MetricRow(label: 'مصدر السعر', ...)` from `metal_detail_page.dart`. Also remove the raw `source` trailing in the Market Tools live prices list.

### 4. 📈 Gold Chart — Cleaner & More Honest
- **Problem**: `history_preview` returns only 12 cached snapshots (not real OHLCV). The chart looks fake.
- **Fix**:
  - Add a clear label: "مؤشر سريع للاتجاه - تحديث عند كل جلسة" (Quick trend indicator).
  - Hide the chart if fewer than 3 valid points exist (to avoid misleading lines).
  - Remove the vague "آخر N نقطة بيانات للمتابعة السريعة" label.

### 5. 💱 Currency Page — Add Bank Rates & More Currencies
- **Problem**: Currency page just reuses the gold endpoint with `metalKey: 'gold'`. There is no real bank rate data shown.
- **Fix**:
  - Check `FLUTTER_MOBILE_APP_GUIDE.md` for a `/market/currency` or `/market/metals` bank rate field.
  - Restructure `CurrencyDetailPage` as a dedicated widget showing: USD/EGP, EUR/EGP, GBP/EGP with buy/sell bank rates if available from the API, or as calculated from the existing `usd_egp_rate`.

### 6. 📋 Recommendations — Show Action (Buy/Sell) & Details
- **Problem**: Recommendations section shows ticker + allocation % but no clear Buy/Sell action label, no chart, no explanation.
- **Fix**:
  - Parse `action`, `action_label_ar`, `reason_ar`, `score` from each recommendation item.
  - Show color-coded Buy/Sell chip (green = شراء, red = بيع).
  - Tapping a recommendation opens `StockDetailPage` for the full chart + premium data sheet.
  - Show `reason_ar` as a subtitle under each card.

---

## Proposed Changes

### Security
#### [MODIFY] [security_wrapper.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/widgets/common/security_wrapper.dart)
- Default `_isLocked = false`. Accept `controller` ref and only lock on app-resume if `controller.biometricEnabled == true`.

#### [MODIFY] [security_service.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/services/security_service.dart)
- Return `true` (bypass) when device has no passcode/biometric set, so blocked state never occurs.

---

### Data & Display
#### [MODIFY] [metal_detail_page.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/views/market/metal_detail_page.dart)
- Remove "مصدر السعر" row.
- Fix chart labeling.
- Restructure `CurrencyDetailPage` to show multi-currency rates with bank-era layout.

#### [MODIFY] [market_tools_page.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/views/market/market_tools_page.dart)
- Remove `source` trailing from live prices tile.
- Remove "حالة تحديث البيانات" / "فحص الحاجة للتحديث" sections (internal operational data not relevant to users).

#### [MODIFY] [dashboard_tab.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/views/dashboard/dashboard_tab.dart)
- Fix gold price extraction to handle nested `metals.metals` correctly.

---

### Recommendations
#### [MODIFY] [portfolio_tab.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/views/portfolio/portfolio_tab.dart)
- Redesign the recommendation list tile to show: action chip (Buy/Sell/Hold), reason, score, and tap-to-detail.

## Verification Plan

### Manual
- Gold price visible on Dashboard.
- App opens **without lock** on fresh install.
- No "gold-api" text visible anywhere.
- Recommendations show a clear Buy/Sell action chip in Arabic.
--------------------------------------------------------------------------------
# Phase 1 Implementation Walkthrough

We successfully implemented Phase 1 to close key gaps identified against the `FLUTTER_MOBILE_APP_GUIDE.md` checklist.

## Changes Made
### 1. API Enhancements
- Expanded `getStockHistory` to support a string `interval` (e.g., `'1M'`, `'1Y'`), dynamically mapping it to the correct number of backend days.
- Exposed the `compliance_status` field inside `searchStocks` and `getStocks` so the Flutter app can actively filter for Halal-only options during search queries.

### 2. Interactive Charts
- Added a `SegmentedButton` to `StockDetailPage` giving the user quick toggles for `1D`, `1W`, `1M`, `6M`, and `1Y` historical views.

### 3. Dashboard Top Movers Carousel
- Removed the plain list representation of Top Gainers/Losers from the Home Dashboard.
- Replaced it with a new horizontal card carousel (`TopMoversWidget`) derived dynamically from the locally sorted stock array.

---

# Phase 2 Implementation Walkthrough

We successfully executed Phase 2, strictly enforcing the difference between Free, Pro, and Premium tiers exactly as defined by your live Node.js web application.

## Changes Made

### 1. Subscription Logic Restructure
- Modified `InvestmentController` to parse exactly which active plan (`free`, `pro`, `premium`) the current user holds instead of a vague boolean check.
- Defined `isPro` for mid-tier unlocked functionalities (like ad-blocking and unlimited watchlist limits).
- Defined `isPremium` exclusively to protect the highest-tier administrative and analytical capabilities.

### 2. Authentication: Password Reset
- Added `forgotPassword` wiring to `api_service.dart`.
- Developed the `forgot_password_sheet.dart` UI complete with validation and visual success states.
- Bound a "Forgot Password?" entry point securely below the Web shortcut button in the native `LoginCard`.

### 3. Financial Tracking Export
- Updated `pubspec.yaml` with the native `csv` and `path_provider` engines.
- Wrote an export generator in `InvestmentController.exportIncomeExpenses` that dynamically turns the JSON transactions into a valid device `.csv` file.
- Prevented UI execution for non-Premium members (unless they are administrators) by triggering the Premium Upsell if clicked.

### 4. Push Alerts Entitlement
- Restructured `WatchlistTab` to lock the "Alert Threshold" input fields entirely.
- Appended a soft warning block inside the Watchlist Editor explicitly highlighting that precise stock threshold Push Alerts are a strictly **Premium-only** feature, guiding users to upgrade.

## Verification

- **Code Compliance**: All files pass the `dart analyzer`. Native dependencies resolved successfully with `flutter pub get`.
- **Security Check**: The exact tier distinctions from the Web platform are now perfectly identically paired to Flutter's API request interceptions.

## Next Phase Options

What section of the remaining app requirements would you like to build out next? Let me know your priorities!
-------------------------------------------------------------------------------------
# Phase 3 Execution Checklist

- `[/]` **1. Security Lock — Make Opt-in**
  - `[ ]` Fix `SecurityWrapper` to start unlocked, only lock if `biometricEnabled == true`
  - `[ ]` Fix `SecurityService` to bypass gracefully when no biometric/PIN enrolled
- `[ ]` **2. Fix Gold Price Display on Dashboard**
  - `[ ]` Normalize metals map extraction in `dashboard_tab.dart`
- `[ ]` **3. Remove Data Source Labels**
  - `[ ]` Remove "مصدر السعر" row from `metal_detail_page.dart`
  - `[ ]` Remove raw `source` from market tools live prices
  - `[ ]` Remove internal operational sections from `market_tools_page.dart`
- `[ ]` **4. Fix Gold Chart Labeling**
  - `[ ]` Hide chart if < 3 points, improve label
- `[ ]` **5. Currency Page — Multi-Bank Rates**
  - `[ ]` Restructure `CurrencyDetailPage` to show USD/EUR/GBP rates
- `[ ]` **6. Recommendations — Buy/Sell Action + Details**
  - `[ ]` Parse `action_label_ar`, `reason_ar`, `score` fields
  - `[ ]` Show color-coded chip + reason under each recommendation
