"""Servidor estático local con cabeceras de seguridad para DevPlay Web.

No es un WAF completo: para producción usa nginx, Cloudflare o el proxy del
hosting. Este script sirve el build de Flutter con protecciones básicas:
- solo GET y HEAD;
- bloquea archivos ocultos y rutas típicas de escaneo;
- evita listados de directorios;
- añade cabeceras de seguridad y caché.

Uso:
    python tool/serve_web.py --directory C:\\devplay_web --port 8080
"""

from __future__ import annotations

import argparse
import posixpath
import urllib.parse
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=()",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "same-site",
    "X-Permitted-Cross-Domain-Policies": "none",
    "X-Download-Options": "noopen",
}

BLOCKED_PREFIXES = (
    "wp-admin",
    "wp-login",
    "wp-content",
    "phpmyadmin",
    "server-status",
    "vendor",
)

BLOCKED_SUFFIXES = (
    ".env",
    ".git",
    ".sql",
    ".bak",
    ".old",
    ".ini",
    ".log",
    ".pem",
    ".key",
)


class DevPlayHandler(SimpleHTTPRequestHandler):
    server_version = "DevPlay"
    sys_version = ""

    def end_headers(self) -> None:
        for name, value in SECURITY_HEADERS.items():
            self.send_header(name, value)

        path = urllib.parse.urlparse(self.path).path.lower()
        if path.endswith(
            (
                "index.html",
                "flutter_bootstrap.js",
                "flutter_service_worker.js",
                "manifest.json",
            )
        ) or path in ("/", ""):
            self.send_header("Cache-Control", "no-cache")
        else:
            self.send_header("Cache-Control", "public, max-age=3600")

        super().end_headers()

    def do_GET(self) -> None:  # noqa: N802 (nombre exigido por http.server)
        if self._is_allowed():
            super().do_GET()

    def do_HEAD(self) -> None:  # noqa: N802
        if self._is_allowed():
            super().do_HEAD()

    def do_POST(self) -> None:  # noqa: N802
        self.send_error(HTTPStatus.METHOD_NOT_ALLOWED)

    def do_PUT(self) -> None:  # noqa: N802
        self.send_error(HTTPStatus.METHOD_NOT_ALLOWED)

    def do_PATCH(self) -> None:  # noqa: N802
        self.send_error(HTTPStatus.METHOD_NOT_ALLOWED)

    def do_DELETE(self) -> None:  # noqa: N802
        self.send_error(HTTPStatus.METHOD_NOT_ALLOWED)

    def list_directory(self, path):  # noqa: ANN001
        self.send_error(HTTPStatus.NOT_FOUND)
        return None

    def _is_allowed(self) -> bool:
        raw_path = urllib.parse.urlparse(self.path).path
        decoded = urllib.parse.unquote(raw_path).replace("\\", "/")
        normalized = posixpath.normpath(decoded)
        parts = [part for part in normalized.split("/") if part]

        if any(part.startswith(".") for part in parts):
            self.send_error(HTTPStatus.NOT_FOUND)
            return False

        lowered = [part.lower() for part in parts]
        if any(part.startswith(BLOCKED_PREFIXES) for part in lowered):
            self.send_error(HTTPStatus.NOT_FOUND)
            return False

        if normalized.lower().endswith(BLOCKED_SUFFIXES):
            self.send_error(HTTPStatus.NOT_FOUND)
            return False

        return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Servidor estático de DevPlay")
    parser.add_argument("--directory", default="build/web")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--bind", default="127.0.0.1")
    args = parser.parse_args()

    DevPlayHandler.extensions_map.update(
        {
            ".wasm": "application/wasm",
            ".js": "text/javascript",
            ".mjs": "text/javascript",
            ".json": "application/json",
        }
    )

    handler = partial(DevPlayHandler, directory=args.directory)
    server = ThreadingHTTPServer((args.bind, args.port), handler)
    print(f"DevPlay Web en http://{args.bind}:{args.port} ({args.directory})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
