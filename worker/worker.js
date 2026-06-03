/**
 * Cloudflare Worker — PATH ridepath.json proxy
 *
 * Deploy via Cloudflare dashboard:
 *   1. Go to workers.cloudflare.com → Create Worker
 *   2. Paste this file, save & deploy
 *   3. Copy the *.workers.dev URL into index.html → CONFIG.proxyUrl
 *
 * Or with wrangler CLI:
 *   npm i -g wrangler && wrangler deploy
 */

const API_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json";

const CORS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }

    const upstream = await fetch(API_URL, {
      headers: {
        "Referer":    "https://www.panynj.gov/path/en/index.html",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Accept":     "application/json",
      },
    });

    const body = await upstream.text();

    return new Response(body, {
      status: upstream.status,
      headers: {
        "Content-Type":  "application/json",
        "Cache-Control": "public, max-age=15",
        ...CORS,
      },
    });
  },
};
