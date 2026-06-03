// ─────────────────────────────────────────────
// Commute Buddy — configuration
// Edit this file to match your commute.
// ─────────────────────────────────────────────

const CONFIG = {
  // Station codes (from PANYNJ ridepath.json)
  homeStation:    'HOB',   // Hoboken
  workStation:    '23S',   // 23rd Street

  // Minutes to walk from home/work to the station entrance
  walkFromHome:   8,
  walkFromWork:   5,

  // Time windows where the app activates (24h "HH:MM")
  morningWindow:  { start: '07:30', end: '09:30' },
  eveningWindow:  { start: '17:00', end: '20:00' },

  // How many upcoming trains to show
  trainCount:     3,

  // Auto-refresh interval (ms)
  refreshMs:      30_000,
};

// TODO: deploy worker.js to Cloudflare Workers and replace this URL
//       with your *.workers.dev endpoint so the app works without
//       the local proxy.py running.
//       Commands:  wrangler login
//                  wrangler deploy worker.js --name path-commute-proxy --compatibility-date 2025-01-01
//const API_URL = 'http://localhost:8787';
const API_URL = 'https://path-commute-proxy.commutebuddy.workers.dev';