#!/usr/bin/env python3
"""
Local proxy for PATH ridepath.json.
Adds the Referer header PANYNJ requires, returns CORS headers so the
browser app can fetch the data from localhost.

Usage:
    python3 proxy.py

Then open index.html — the app will call http://localhost:8787
"""
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT    = 8787
API_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json"
HEADERS = {
    "Referer":    "https://www.panynj.gov/path/en/index.html",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Accept":     "application/json",
}

class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self._cors(204, b"")

    def do_GET(self):
        req = urllib.request.Request(API_URL, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = resp.read()
            self._cors(200, data)
        except urllib.error.HTTPError as e:
            self._cors(e.code, f"Upstream error: {e.reason}".encode())
        except Exception as e:
            self._cors(502, f"Proxy error: {e}".encode())

    def _cors(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin",  "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(f"  {args[0]}  {args[1]}")

if __name__ == "__main__":
    server = HTTPServer(("localhost", PORT), Handler)
    print(f"PATH proxy → http://localhost:{PORT}")
    print("Press Ctrl-C to stop.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
