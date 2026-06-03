# Commute Buddy

A minimal commute tracker focused on one question: **should I leave yet?**

Knows your PATH train route, your walk time to the station, and your commute windows. Slightly ahead of your usual departure time it surfaces the next few trains and tells you exactly when to leave.

![Web app screenshot showing "10:58 AM" with a "GO" signal and upcoming trains](https://placeholder)

---

## Features

- **Auto mode** — activates only during your configured morning/evening windows; shows idle clock otherwise
- **On mode** — always active; shows a live clock with a **Go / Wait** signal based on walk time vs. next train
- Live PATH departures via the PANYNJ real-time feed, refreshed every 30 seconds
- Direction-aware: morning = Hoboken → 23 St, evening = 23 St → Hoboken
- Filters out WTC-bound trains that skip 23rd St
- Mobile-friendly dark UI

---

## Project structure

```
commute-buddy/
├── web/                        # Web app (GitHub Pages)
│   ├── index.html              # App UI and logic — no build step
│   ├── config.js               # Your commute settings — edit this
│   ├── manifest.json           # PWA manifest (home screen install)
│   ├── icon.png                # Home screen icon
│   └── proxy.py               # Local dev proxy (not deployed)
├── worker/                     # Cloudflare Worker
│   ├── worker.js               # Proxy that adds required PANYNJ headers
│   └── wrangler.toml           # Wrangler config — deploy with `wrangler deploy`
├── mac/                        # macOS menu bar app — SwiftUI (future)
├── ios/                        # iOS app + widget — SwiftUI (future)
├── .github/workflows/
│   └── deploy.yml              # Deploys web/ to GitHub Pages on push
├── .gitignore
├── LICENSE
└── README.md
```

---

## Running locally

The PANYNJ API requires a `Referer` header that a browser can't forge directly, so a local proxy is needed for development.

**Terminal 1 — start the data proxy:**

```bash
cd web
python3 proxy.py
# PATH proxy → http://localhost:8787
```

**Terminal 2 — serve the app:**

```bash
cd web
python3 -m http.server 3000
```

Then open **http://localhost:3000** in your browser.

> Opening `index.html` directly as a `file://` URL can cause browsers to block the fetch — serving over HTTP avoids that.

---

## Configuration

All settings live in `web/config.js`:

```js
const CONFIG = {
  homeStation:   'HOB',  // Hoboken
  workStation:   '23S',  // 23rd Street

  walkFromHome:  8,      // minutes to walk to Hoboken PATH
  walkFromWork:  5,      // minutes to walk to 23rd St PATH

  morningWindow: { start: '07:30', end: '09:30' },
  eveningWindow: { start: '17:00', end: '20:00' },

  trainCount:    3,      // upcoming trains to display
  refreshMs:     30_000, // refresh interval
};

const API_URL = 'http://localhost:8787'; // swap for Cloudflare Worker URL in production
```

**Station codes** (from the PANYNJ ridepath feed):

| Station | Code |
|---|---|
| Newark | NWK |
| Harrison | HAR |
| Journal Square | JSQ |
| Grove Street | GRV |
| Exchange Place | EXP |
| World Trade Center | WTC |
| Newport | NEW |
| Hoboken | HOB |
| Christopher Street | CHR |
| 9th Street | 09S |
| 14th Street | 14S |
| 23rd Street | 23S |
| 33rd Street | 33S |

---

## Deploying to production (Cloudflare Workers)

The free Cloudflare Workers tier (100k requests/day) is more than enough for personal use.

**One-time setup:**

```bash
brew install node
npm install -g wrangler
wrangler login
```

**Deploy:**

```bash
cd worker
wrangler deploy
```

Wrangler prints a `*.workers.dev` URL. Paste it into `web/config.js`:

```js
const API_URL = 'https://path-commute-proxy.commutebuddy.workers.dev';
```

Now the app works from any browser without running `proxy.py`.

---

## Data source

Real-time departure data from the Port Authority of New York and New Jersey:

```
https://www.panynj.gov/bin/portauthority/ridepath.json
```

Returns all PATH stations in a single JSON payload, updated every ~30 seconds. The proxy adds the `Referer` header the endpoint requires and returns `Access-Control-Allow-Origin: *` so the browser app can consume it.

---

## Roadmap

- [x] Web app POC
- [x] Deploy Cloudflare Worker — retire local proxy
- [x] Host on GitHub Pages — accessible from any browser
- [x] PWA support — installable on iPhone home screen
- [ ] Settings UI (no more editing `config.js` by hand)
- [ ] macOS menu bar app (SwiftUI + `MenuBarExtra`)
- [ ] iOS app with Lock Screen / Home Screen widget (WidgetKit)
- [ ] Switch native apps to GTFS-RT feed (`path.transitdata.nyc/gtfsrt`) for standard format and 15s refresh
