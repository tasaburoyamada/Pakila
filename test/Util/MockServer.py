import http.server
import json
import sys

class MockHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.log_request_details()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"models": [{"name": "models/mock-v1"}]}).encode())

    def do_POST(self):
        self.log_request_details()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        # Return a dummy Gemini response
        response = {
            "candidates": [{
                "content": {"parts": [{"text": "Mock success"}]},
                "role": "model"
            }]
        }
        self.wfile.write(json.dumps(response).encode())

    def log_request_details(self):
        data = {
            "path": self.path,
            "headers": dict(self.headers),
            "method": self.command
        }
        with open("mock_request.json", "w") as f:
            json.dump(data, f)

def run(port=8080):
    server_address = ('', port)
    httpd = http.server.HTTPServer(server_address, MockHandler)
    print(f"Starting mock server on port {port}...")
    httpd.handle_request() # Run once

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run(port)
