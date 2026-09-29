from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import json

HOST="127.0.0.1"
PORT=5173
BASE_DIR=Path(__file__).resolve().parent
latest_payload=None

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin","*")
        self.send_header("Access-Control-Allow-Methods","GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers","Content-Type")
        self.send_header("Cache-Control","no-store")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        global latest_payload
        if self.path.split("?",1)[0]=="/hp":
            body=json.dumps(latest_payload or {}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type","application/json; charset=utf-8")
            self.send_header("Content-Length",str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path.split("?",1)[0]=="/":
            self.path="/manifest.json"
        super().do_GET()

    def do_POST(self):
        global latest_payload
        if self.path!="/hp":
            self.send_error(404)
            return
        try:
            length=int(self.headers.get("Content-Length","0"))
            payload=json.loads(self.rfile.read(length).decode("utf-8"))
            if not isinstance(payload,dict) or not isinstance(payload.get("players"),list):
                raise ValueError("payload invalide")
            latest_payload=payload
            body=b'{"ok":true}'
            self.send_response(200)
            self.send_header("Content-Type","application/json")
            self.send_header("Content-Length",str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception:
            self.send_error(400)

if __name__=="__main__":
    print("The Last Heart - passerelle Owlbear locale")
    print("Adresse : http://127.0.0.1:5173")
    print("Laisse cette fenêtre ouverte pendant la partie.")
    ThreadingHTTPServer((HOST,PORT),Handler).serve_forever()
