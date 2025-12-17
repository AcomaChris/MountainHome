# External Libraries Setup

This directory should contain external Lua libraries for HTTP and JSON support.

## Required Libraries

### 1. lunajson
- **Source**: https://github.com/grafi-tt/lunajson
- **Installation**: 
  - Clone or download the repository
  - **Option A (Recommended):** Copy `src/lunajson.lua` to `lib/lunajson.lua` and copy `src/lunajson/` folder to `lib/lunajson/`
  - **Option B:** Copy entire `src/` folder contents to `lib/lunajson/`, then require as `require('lunajson.lunajson')`
  - **Required structure (Option A):**
    - `lib/lunajson.lua` (main entry point)
    - `lib/lunajson/decoder.lua`
    - `lib/lunajson/encoder.lua`
    - `lib/lunajson/parser.lua`
    - Other files from `src/lunajson/` subdirectory
  - Usage: `local lunajson = require('lunajson')`

### 2. lua-http (⚠️ Has Dependency Issue)
- **Source**: https://github.com/daurnimator/lua-http
- **Problem**: Requires `lpeg` (C extension) which doesn't work in Love2D
- **Current Status**: Library will load but HTTP requests will fail due to missing `lpeg`
- **Installation** (for reference, but won't work fully):
  - Clone or download the repository
  - Copy the `http/` folder from the repository root into `lib/lua-http/` directory
  - **Required structure:**
    - `lib/lua-http/http/request.lua`
    - Other HTTP modules as needed
  - Usage: `local http = require('http.request')`

**Solution for Love2D:**
- We'll implement a custom HTTP client in `lib/http_client.lua` using Love2D's socket library
- This avoids the lpeg dependency issue
- For Phase 1, JSON (lunajson) is the priority; HTTP will be implemented as a custom wrapper

## Package Path

The main.lua file already sets up package.path to include:
- `lib/?.lua`
- `lib/?/init.lua`
- `lib/?/?.lua`

This allows requiring libraries like:
- `local json = require('lunajson')`
- `local http = require('http.request')`

