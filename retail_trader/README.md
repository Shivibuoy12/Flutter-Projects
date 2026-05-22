# Retail Trader (Flutter demo)

A **mock** retail trading workstation with a **dark, Webull‑inspired layout** (similar information density, greens/reds, ticker strip, rails, and tables).  
**Not affiliated with Webull or any brokerage** — styling is generic; **do not** reuse third‑party logos or trademarks.

## Features

| Area | What’s included |
|------|------------------|
| **Charts** | Watchlist sidebar, headline quote, candlestick-style chart (generated), chip tabs (Depth / Option / News…), bid/ask depth mock |
| **Markets** | Index ticker strip, gainers/losers cards, lightweight news & account widgets |
| **Orders** | **Order blotter** `DataTable` (IDs, chain, symbol, side, qty, avg/limit, TIF, status) + mock §3.1.8-style protocol log lines |
| **Portfolio** | Stat cards + **positions** table (P&amp;L colors) |

Responsive: wide layout uses **NavigationRail + extended labels**; narrow uses bottom **NavigationBar**.

## Run

```bash
cd retail_trader
flutter pub get
flutter run          # picks device / Chrome / Windows
flutter run -d windows
```

Use **desktop** (`-d windows` / macOS / Linux): the mock TCP client uses **`dart:io`** (`Socket`), which does not run on **web**.

Executable (after release build): `build/windows/x64/runner/Release/retail_trader.exe`

### Testing against `Server_Side_Mock` / BOP

1. Put **`fmx_instruments.json`** in your **Downloads** folder — on Windows `%USERPROFILE%\Downloads\fmx_instruments.json`. The desktop build loads that copy first and uses **`assets/data/fmx_instruments.json`** only if Downloads is missing.
2. Point **Host / Port** at the listener; **Save** credentials that the mock accepts (wrong password ⇒ login **`J`** / `LOGIN REJECT`; good ⇒ **`A`** and `LOGIN OK` in Orders **gateway message log**).
3. Order ticket (**Charts** workspace): select a symbol from the JSON-backed watchlist rows (they carry **instrument ids**), submit **Buy/Sell** (**`O`** Enter via envelope `u`).
4. **Cancel** sends Futures extended **`X`** (Tables 36–37: id `@1–30`, sender + client trader trailing); server **`C`** ack drives blot removal (`parseCancelled`). **Modify (replace)** sends **`U`** with Tables 38–39 layout (replacement id `@31–60`, qty/price `@61`/`@69`, extended slice from `@95`). **`parseReplaced`** accepts shorter Table‑46 echoes or echoed replace bodies (see `gateway_parse.dart`). Responses still depend on mock rules.
5. **Gear** dialog → **protocol probes**: replay **login `L`** (same or misaligned seq), raw **heartbeat `R`**, **`T`** account probe (same shape as post-login handshake).
6. If the mock expects a **different outer envelope** than **`u`** for cancel/replace, change `GatewayService.kGatewayFuturesOrderEnvelopeAscii` next to Enter.

## Next steps (real product)

Wire **Bloc / Riverpod / Provider** state, REST/WebSocket to your gateway (e.g. FMX mock), authenticated sessions, pagination on tables, TradingView/widget chart, and localization.
