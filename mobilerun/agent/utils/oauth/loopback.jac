import builtins;

import threading;

import from http.server { BaseHTTPRequestHandler }

import from typing { Any }

import from urllib.parse { parse_qs, urlparse }

"""One OAuth redirect, received by a loopback HTTP server on its own thread."""
class LoopbackCallback {
    has path: str,
        result: dict[str, Any],
        done: Any,
        lock: Any,
        httpd: Any;

    def init(host: str, port: int, path: str, server_cls: Any);

    def port -> int;

    def serve -> None;

    def receive(request: Any) -> None;

    def code(deadline: Any, state: str, timeout_message: str) -> str;

    def close -> None;
}

"""Hands each request to the LoopbackCallback its server belongs to."""
class _CallbackHandler(BaseHTTPRequestHandler) {
    def do_GET -> None;

    def log_message(format: builtins.str, *args: Any) -> None;
}
