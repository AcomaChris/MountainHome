# Known Issues

## lua-https POST Body Not Sent on Windows (Love2D 12.0+)

**Status**: Confirmed Bug  
**Platform**: Windows  
**Love2D Version**: 12.0.0  
**Module**: `lua-https` (built-in HTTPS client)

### Description
When using `lua-https` for POST requests on Windows, the request body is not sent to the server, even though:
- The body is correctly formatted as a string
- The format matches the official documentation
- The same request works perfectly with `curl`
- GET requests work fine with `lua-https`

### Symptoms
- POST requests complete (no hang)
- Server returns HTTP 400 with "body: Field required" error
- GET requests work correctly
- Same request works with `curl`

### Workaround
Currently, there is no working workaround. Options attempted:
- ✅ Removing `Content-Length` header (fixes hang, but body still not sent)
- ❌ Using `socket.http` (requires `ssl.https` which isn't available)
- ❌ Using `socket.https` (requires `ssl.https` which isn't available)

### Test Case
```lua
local https = require("https")
local json = require("lunajson")

local body = json.encode({
    project_id = "proj_test",
    metadata = { test = "value" }
})

local result, code, headers, status = https.request("https://api.artificial.agency/v1/sessions", {
    method = "POST",
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer token",
        ["AA-API-Version"] = "2025-05-15"
    },
    body = body
})
-- Result: HTTP 400 "body: Field required" (body not sent)
```

### Verification
The same request works with `curl`:
```bash
curl -X POST https://api.artificial.agency/v1/sessions \
  -H "Authorization: Bearer token" \
  -H "AA-API-Version: 2025-05-15" \
  -H "Content-Type: application/json" \
  -d '{"project_id":"proj_test","metadata":{"test":"value"}}'
# Result: HTTP 200 with valid session response
```

### Next Steps
1. Report bug to Love2D team: https://github.com/love2d/lua-https/issues
2. Monitor for fix in future Love2D releases
3. Consider alternative HTTP library if available

### Related Files
- `lib/http_client.lua` - HTTP client implementation
- `lib/api_client.lua` - API client using HTTP client
- `test_api_curl.bat` - Working curl test case

