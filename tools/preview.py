"""Run the compiled Flutter preview with a read-only catalog route."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
import urllib.error
import urllib.parse
import urllib.request


PROVIDER = "https://icinema.live"
ALLOWED_API = re.compile(r"/api/(?:home|catalog|search|items/(?:show|movie)/[1-9]\d*)\Z")
MAX_JSON_BYTES = 8_000_000


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, url):
        return None


CLIENT = urllib.request.build_opener(NoRedirect)


class Preview(SimpleHTTPRequestHandler):
    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path.startswith("/api/"):
            self.catalog(url)
        else:
            super().do_GET()

    def catalog(self, url):
        if not ALLOWED_API.fullmatch(url.path) or len(url.query) > 1_200:
            self.send_error(404)
            return

        request_url = PROVIDER + url.path
        if url.query:
            request_url += "?" + url.query
        request = urllib.request.Request(request_url, headers={"Accept": "application/json"})
        try:
            with CLIENT.open(request, timeout=15) as response:
                if response.headers.get_content_type() != "application/json":
                    self.send_error(502, "The provider did not return catalog data")
                    return
                body = response.read(MAX_JSON_BYTES + 1)
        except urllib.error.HTTPError as error:
            self.send_error(error.code if 400 <= error.code < 600 else 502)
            return
        except (OSError, ValueError):
            self.send_error(502, "Unable to reach the catalog provider")
            return

        if len(body) > MAX_JSON_BYTES:
            self.send_error(502, "Catalog response too large")
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--directory", type=Path, default=Path("build/web"))
    options = parser.parse_args()
    if not (options.directory / "index.html").is_file():
        parser.error("Build the Flutter web release or specify its directory with --directory.")
    handler = partial(Preview, directory=options.directory)
    with ThreadingHTTPServer(("127.0.0.1", options.port), handler) as server:
        print(f"Mashhad: http://127.0.0.1:{server.server_port}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
