# HTTP Library Options for Love2D

## Current Issue
We're experiencing problems with `socket.http` (Love2D's built-in HTTP client):
- Server redirects `https://api.artificial.agency/v1/sessions` → `https://api.artificial.agency:443/v1/sessions`
- `socket.http` hangs when using URLs with explicit `:443` port
- Even after normalization and retry logic, server consistently returns 301

## Alternative Options

### 1. **lua-https** (Recommended if Love2D 12.0+)
- **Status**: Built into Love2D 12.0 and later
- **Platforms**: Windows, Linux, macOS, iOS, Android
- **Pros**:
  - Native platform backends (uses system HTTP libraries)
  - Should handle redirects and ports correctly
  - No external dependencies
  - Simple API: `https.request(url, options)`
- **Cons**:
  - Cannot stream responses
  - Cannot access headers before downloading body
  - Only available in Love2D 12.0+
- **GitHub**: https://github.com/love2d/lua-https
- **Documentation**: https://love2d.org/wiki/lua-https

**Usage Example:**
```lua
local https = require("https")
local result, code, headers, status = https.request("https://api.example.com/endpoint", {
    method = "POST",
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer token"
    },
    body = json.encode(data)
})
```

### 2. **fetch-lua**
- **Status**: Pure LuaJIT HTTP/HTTPS library
- **Platforms**: Any platform running LuaJIT (Love2D uses LuaJIT)
- **Pros**:
  - Pure Lua implementation (no C dependencies)
  - Event-driven API
  - Designed for Love2D games
- **Cons**:
  - May have similar issues with redirects/ports
  - Less mature than lua-https
  - Need to verify it handles our use case
- **GitHub**: https://github.com/love2d-community/awesome-love2d (search for fetch-lua)

### 3. **Custom Implementation with socket.tcp**
- **Status**: Use Love2D's `socket.tcp` directly
- **Pros**:
  - Full control over HTTP implementation
  - Can handle redirects and ports exactly as needed
  - No external dependencies
- **Cons**:
  - More complex to implement
  - Need to handle TLS/SSL manually
  - More code to maintain

### 4. **Continue with socket.http + Workarounds**
- **Status**: Current approach
- **Pros**:
  - Already integrated
  - Works for most cases
- **Cons**:
  - Has issues with explicit ports (`:443`)
  - Redirect handling is problematic
  - May need server-side fix

## Recommendation

**Check Love2D Version First:**
```lua
print(love.getVersion())  -- Check if >= 12.0
```

**If Love2D 12.0+:**
- **Use `lua-https`** - It's built-in, uses native HTTP libraries, and should handle redirects/ports correctly.

**If Love2D < 12.0:**
- **Option A**: Upgrade to Love2D 12.0+ to use `lua-https`
- **Option B**: Try `fetch-lua` (need to test if it handles our redirect issue)
- **Option C**: Implement custom HTTP client using `socket.tcp` with full control

## Next Steps

1. Check Love2D version: `love.getVersion()`
2. If 12.0+, implement `lua-https` client
3. If < 12.0, evaluate upgrading or trying `fetch-lua`
4. Test with the Artificial Agency API to verify redirect handling works

