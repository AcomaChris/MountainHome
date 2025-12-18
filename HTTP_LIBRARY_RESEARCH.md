# HTTP Library Research for Love2D (Windows)

## Problem Statement
- `lua-https` (Love2D 12.0+ built-in) has a bug on Windows where POST request bodies are not sent
- `socket.http` cannot handle HTTPS without `ssl.https` (LuaSec), which isn't available in Love2D
- Need a working HTTP client that can make POST requests with JSON bodies on Windows

## Evaluated Options

### 1. **lua-https** (Current - Has Bug)
- **Status**: ❌ Bug on Windows - POST bodies not sent
- **Platform**: Windows, Linux, macOS, iOS, Android
- **Dependencies**: None (built into Love2D 12.0+)
- **Pros**:
  - Built-in, no installation needed
  - GET requests work perfectly
  - Handles redirects automatically
  - Simple API
- **Cons**:
  - **POST request bodies are not sent on Windows** (confirmed bug)
  - Cannot stream responses
  - Cannot access headers before downloading body
- **GitHub**: https://github.com/love2d/lua-https
- **Verdict**: ❌ Not usable for POST requests on Windows

### 2. **lua-http** (Already in codebase)
- **Status**: ❌ Requires C extensions
- **Platform**: Any (but requires compilation)
- **Dependencies**: 
  - `lpeg` (C extension - **NOT available in Love2D**)
  - `lpeg_patterns` (depends on lpeg)
  - `cqueues` (doesn't support Windows)
  - `luaossl` (C extension)
  - `basexx`, `binaryheap`, `fifo` (pure Lua - OK)
- **Pros**:
  - Comprehensive HTTP/1.0, 1.1, 2.0 support
  - Optional async operations
  - Good documentation
- **Cons**:
  - **Requires `lpeg` (C extension) - NOT available in Love2D**
  - `cqueues` doesn't support Windows
  - Too many dependencies
- **GitHub**: https://github.com/daurnimator/lua-http
- **Verdict**: ❌ Not usable - requires C extensions not available in Love2D

### 3. **socket.http + socket.https** (Love2D built-in)
- **Status**: ❌ Requires `ssl.https` (LuaSec)
- **Platform**: Any (but HTTPS requires LuaSec)
- **Dependencies**: 
  - `socket.http` - ✅ Available in Love2D
  - `socket.https` - ❌ Requires `ssl.https` (LuaSec) - NOT available
- **Pros**:
  - Built into Love2D
  - Works for HTTP requests
- **Cons**:
  - **Cannot do HTTPS without LuaSec (C extension)**
  - Has redirect/port issues (as we've seen)
- **Verdict**: ❌ Cannot do HTTPS in Love2D

### 4. **socket.tcp with manual TLS** (Custom Implementation)
- **Status**: ⚠️ Possible but complex
- **Platform**: Any
- **Dependencies**: `socket.tcp` (✅ Available in Love2D)
- **Pros**:
  - Full control over HTTP implementation
  - Can handle redirects and ports exactly as needed
  - No external dependencies
- **Cons**:
  - **Very complex to implement**
  - Need to implement HTTP protocol manually
  - Need to handle TLS/SSL manually (requires TLS library)
  - **TLS libraries typically require C extensions**
  - Significant development time
- **Verdict**: ⚠️ Theoretically possible but impractical

### 5. **haproxy-lua-http** (Pure Lua)
- **Status**: ⚠️ Unknown - needs testing
- **Platform**: Any (pure Lua)
- **Dependencies**: Pure Lua (no C extensions)
- **Pros**:
  - Pure Lua implementation
  - Modeled after Python's Requests library
  - HTTP 1.1 support
- **Cons**:
  - Designed for HAProxy (may have HAProxy-specific code)
  - Unknown if it works standalone
  - Need to verify HTTPS support
  - Less documented
- **GitHub**: https://github.com/haproxytech/haproxy-lua-http
- **Verdict**: ⚠️ Worth investigating - pure Lua, might work

### 6. **fetch-lua** (Mentioned in docs)
- **Status**: ❓ Unknown - needs research
- **Platform**: Any (pure LuaJIT)
- **Dependencies**: Pure Lua (no C extensions)
- **Pros**:
  - Pure Lua implementation
  - Event-driven API
  - Designed for Love2D games
- **Cons**:
  - Hard to find (not in awesome-love2d easily)
  - May not exist or be maintained
  - Unknown HTTPS support
- **GitHub**: Need to find actual repository
- **Verdict**: ❓ Need to locate and test

### 7. **lua-resty-http** (OpenResty)
- **Status**: ❌ Wrong environment
- **Platform**: OpenResty/ngx_lua only
- **Dependencies**: OpenResty framework
- **Pros**:
  - Good HTTP client
- **Cons**:
  - **Only works in OpenResty/Nginx environment**
  - Not compatible with Love2D
- **Verdict**: ❌ Not applicable

### 8. **httpclient** (Wrapper)
- **Status**: ❌ Depends on other libraries
- **Platform**: Any
- **Dependencies**: Wraps other HTTP libraries (socket.http, etc.)
- **Pros**:
  - Unified interface
- **Cons**:
  - **Still depends on underlying libraries (socket.http, etc.)**
  - Doesn't solve the HTTPS problem
- **Verdict**: ❌ Doesn't solve our problem

### 9. **Lua-cURL** (libcurl binding)
- **Status**: ❌ Requires C extension
- **Platform**: Any (but requires compilation)
- **Dependencies**: 
  - `libcurl` (C library)
  - C binding code
- **Pros**:
  - Full-featured (libcurl is very robust)
  - Supports HTTPS, HTTP/2, etc.
- **Cons**:
  - **Requires C extension compilation**
  - Not available as pre-built for Love2D
- **Verdict**: ❌ Requires compilation, not practical

## Recommended Next Steps

### Option A: Investigate haproxy-lua-http
1. Download and test `haproxy-lua-http`
2. Check if it can work standalone (not just in HAProxy)
3. Test HTTPS POST requests
4. If it works, integrate it

### Option B: Report Bug and Wait
1. Report `lua-https` POST body bug to Love2D team
2. Document workaround (use curl for testing)
3. Wait for fix in future Love2D release
4. Continue with other Phase 1 tasks that don't require POST

### Option C: Use External Process (Workaround)
1. Create a small HTTP proxy script (Python/Node.js) that:
   - Listens on localhost
   - Makes HTTPS requests using native libraries
   - Returns results to Love2D via HTTP
2. Love2D makes HTTP requests to localhost proxy
3. Proxy handles HTTPS to external API
4. **Pros**: Works immediately
5. **Cons**: Requires external process, adds complexity

### Option D: Custom socket.tcp Implementation
1. Implement basic HTTP/1.1 client using `socket.tcp`
2. For HTTPS, use Love2D's built-in TLS if available, or skip HTTPS validation
3. **Pros**: Full control
4. **Cons**: Very time-consuming, complex

## Current Recommendation

**Short-term**: Use **Option C (External Process)** as a workaround to unblock Phase 1 development.

**Long-term**: 
1. Report `lua-https` bug to Love2D team
2. Investigate `haproxy-lua-http` as potential pure Lua solution
3. Monitor for `lua-https` fix in future releases

## Testing Priority

1. **haproxy-lua-http** - Test if it works standalone for HTTPS POST
2. **External proxy script** - Quick workaround to unblock development
3. **Bug report** - Document issue for Love2D team

