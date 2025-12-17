# HTTP Proxy Setup (Workaround for lua-https Bug)

## Overview
Since `lua-https` has a bug on Windows where POST request bodies aren't sent, we can use a local HTTP proxy to work around this issue.

## How It Works
1. **Python Proxy Script** (`http_proxy.py`): Runs on localhost:8080, handles HTTPS requests
2. **Love2D Client** (`lib/http_proxy_client.lua`): Makes HTTP requests to localhost proxy
3. **Proxy forwards** requests to the actual HTTPS API and returns results

## Setup Instructions

### 1. Install Python (if not already installed)
- Download from: https://www.python.org/downloads/
- Make sure Python 3.6+ is installed
- Verify: `python --version` or `python3 --version`

### 2. Start the Proxy Server
```bash
python http_proxy.py
```

Or on Windows:
```powershell
python http_proxy.py
```

You should see:
```
HTTP Proxy server running on http://localhost:8080
Endpoints:
  POST /proxy - Proxy HTTPS requests
  GET /health - Health check

Press Ctrl+C to stop
```

### 3. Update HTTP Client to Use Proxy
Modify `lib/http_client.lua` to use the proxy client when available.

### 4. Test
The proxy will handle all HTTPS POST requests, and Love2D will communicate with it via HTTP (which works fine).

## Advantages
- ✅ Works immediately (no waiting for bug fixes)
- ✅ Uses Python's native HTTPS (very reliable)
- ✅ Simple to set up
- ✅ Can be disabled when bug is fixed

## Disadvantages
- ⚠️ Requires external Python process
- ⚠️ Adds a dependency (Python must be installed)
- ⚠️ Slight performance overhead (extra hop)

## Alternative: Node.js Version
If you prefer Node.js, we can create a similar proxy in Node.js instead.

