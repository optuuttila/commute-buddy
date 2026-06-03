# Commute Buddy — project memory for Claude

## What this is
A PATH train commute tracker. Web app POC is live; macOS and iOS native apps are next.

## Repo
- **Public repo**: github.com/optuuttila/commute-buddy
- **Live app**: https://optuuttila.github.io/commute-buddy
- **Cloudflare Worker**: https://path-commute-proxy.commutebuddy.workers.dev

## ⚠️ Public repo — sensitive data rules
This repo is public. Never commit:
- API keys or tokens
- `.env` files
- Personal addresses or precise location data
- Cloudflare / GitHub credentials
- Anything from `.wrangler/` (auth tokens live there)

`web/config.js` is public and contains the commute route and schedule — keep it to
station codes and timing only (no street addresses, no credentials).

## Route
- Home station: Hoboken (HOB) — walk time 8 min
- Work station: 23rd Street (23S) — walk time 5 min
- Morning window: 07:30–09:30
- Evening window: 17:00–20:00

## Architecture
```
web/      → static HTML/JS, GitHub Pages, calls Cloudflare Worker for PATH data
worker/   → Cloudflare Worker (free tier), proxies PANYNJ ridepath.json
mac/      → future SwiftUI menu bar app (can call PANYNJ API directly — no CORS)
ios/      → future SwiftUI app + WidgetKit (same, no CORS restriction)
```

## Data sources
- **Web**: `https://www.panynj.gov/bin/portauthority/ridepath.json` via Cloudflare Worker proxy
  (needs `Referer: https://www.panynj.gov/path/en/index.html` header)
- **Native (future)**: GTFS-RT at `https://path.transitdata.nyc/gtfsrt` — binary protobuf,
  15s refresh, no CORS issues in Swift

## Deploy
- **Web**: push to `main` → GitHub Actions deploys `web/` to Pages automatically
- **Worker**: `cd worker && wrangler deploy`
