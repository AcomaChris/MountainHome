# Upgrading to Love2D 12.0+ for HTTPS Support

## Current Situation
- **Current Version**: Love2D 11.5.0
- **Problem**: `socket.http` has issues with HTTPS redirects and explicit ports (`:443`)
- **Solution**: Upgrade to Love2D 12.0+ to use `lua-https` (native HTTPS support)

## Why Upgrade?
Love2D 12.0+ includes `lua-https`, which:
- Uses native platform HTTP libraries (handles redirects/ports correctly)
- Designed specifically for HTTPS requests
- No external dependencies
- Better performance and reliability

## How to Upgrade

### Windows
1. Download Love2D 12.0+ from: https://love2d.org/
2. Install or extract to a new directory
3. Update your PATH if needed, or use the new executable directly
4. Test: `love --version` should show 12.0 or higher

### Verify Installation
Run this in your game to confirm:
```lua
local major, minor = love.getVersion()
print(string.format("Love2D %d.%d", major, minor))
```

## After Upgrading
Once on 12.0+, we can:
1. Update `http_client.lua` to use `lua-https` instead of `socket.http`
2. Remove all the redirect/port workarounds
3. Get clean, reliable HTTPS requests

## Alternative: Custom HTTPS Client
If upgrading isn't possible, we can implement a custom HTTPS client using `socket.tcp` with TLS, but this is more complex and requires more code to maintain.


