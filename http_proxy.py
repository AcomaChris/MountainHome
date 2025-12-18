#!/usr/bin/env python3
"""
HTTP Proxy for Love2D
Workaround for lua-https POST body bug on Windows

This script acts as a local HTTP proxy that:
1. Receives HTTP requests from Love2D (localhost)
2. Makes HTTPS requests to external APIs
3. Returns results to Love2D

Usage:
    python http_proxy.py

Then in Love2D, make requests to: http://localhost:8080/proxy
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import urllib.parse
import json
import sys

class ProxyHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests from Love2D"""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        # Parse the proxy request
        try:
            proxy_data = json.loads(body.decode('utf-8'))
            target_url = proxy_data.get('url')
            target_method = proxy_data.get('method', 'POST')
            target_headers = proxy_data.get('headers', {})
            target_body = proxy_data.get('body', '')
            
            if not target_url:
                self.send_error(400, "Missing 'url' in proxy request")
                return
            
            # Make the actual HTTPS request
            req = urllib.request.Request(
                target_url,
                data=target_body.encode('utf-8') if target_body else None,
                headers=target_headers,
                method=target_method
            )
            
            try:
                with urllib.request.urlopen(req, timeout=30) as response:
                    response_body = response.read()
                    response_headers = dict(response.headers)
                    
                    # Send response back to Love2D
                    self.send_response(response.getcode())
                    for header, value in response_headers.items():
                        if header.lower() not in ['connection', 'transfer-encoding']:
                            self.send_header(header, value)
                    self.send_header('Content-Length', str(len(response_body)))
                    self.end_headers()
                    self.wfile.write(response_body)
                    
            except urllib.error.HTTPError as e:
                # Handle HTTP errors (4xx, 5xx)
                error_body = e.read()
                self.send_response(e.code)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(error_body)))
                self.end_headers()
                self.wfile.write(error_body)
                
            except Exception as e:
                self.send_error(500, f"Proxy error: {str(e)}")
                
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON in proxy request")
        except Exception as e:
            self.send_error(500, f"Error: {str(e)}")
    
    def do_GET(self):
        """Handle GET requests (health check)"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_error(404, "Only POST /proxy and GET /health are supported")
    
    def log_message(self, format, *args):
        """Override to use Python logging instead of stderr"""
        print(f"[HTTP Proxy] {format % args}")

def run(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, ProxyHandler)
    print(f"HTTP Proxy server running on http://localhost:{port}")
    print("Endpoints:")
    print("  POST /proxy - Proxy HTTPS requests")
    print("  GET /health - Health check")
    print("\nPress Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down proxy server...")
        httpd.shutdown()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run(port)

