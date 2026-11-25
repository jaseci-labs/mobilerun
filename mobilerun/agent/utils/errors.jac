import from __future__ { annotations }

import logging;

import re;

import from urllib.parse { urlsplit }

glob _MAX_ERROR_CHARS: any = 2000;

glob _MAX_TITLE_CHARS: any = 100;

glob _TITLE_SCAN_CHARS: any = 20000;

glob _HTML_TAG: any = re.compile("<!doctype\\s+html|<html[\\s>]", re.IGNORECASE);

glob _PAGE_TAG: any = re.compile("<(?:head|body|title|script|/html)[\\s>]", re.IGNORECASE);

glob _HTML_TITLE: any = re.compile("<title[^>]{0,200}>([^<]{0,500})</title>", re.IGNORECASE);

glob _PAGE_PREAMBLE: any = re.compile(
    "(?:\\s|\\ufeff|\\\\[nrt]|<\\?xml[^>]{0,200}\\?>|<!--.{0,500}?-->)*$", re.DOTALL
);

glob _ESCAPES: any = re.compile("\\\\[nrt]|\\ufeff");

glob _TRUNCATION_MARKER: any = re.compile("\\.\\.\\. \\[\\d+ more characters\\]$");

def http_status_code(error: BaseException) -> int | None {
    def read_attribute(value: object, name: str) -> object | None {
        try {
            return getattr(value, name, None);
        } except Exception {
            return None;
        }
    }

    def parse_status(value: object) -> int | None {
        if isinstance(value, `bool) {
            return None;
        }
        if isinstance(value, `int) {
            parsed: any = value;
        } elif isinstance(value, `str) {
            stripped: any = value.strip();
            if not stripped.isascii() or not stripped.isdecimal() {
                return None;
            }
            parsed = `int(stripped);
        } else {
            return None;
        }
        return parsed if 100 <= parsed <= 599 else None;
    }

    response: any = read_attribute(error, "response");
    candidates: any = (
        read_attribute(error, "status_code"),
        read_attribute(response, "status_code"),
        read_attribute(error, "code"),
        read_attribute(error, "status"),
        read_attribute(response, "status"),
    );
    for status_code in candidates {
        parsed: any = parse_status(status_code);
        if parsed is not None {
            return parsed;
        }
    }
    return None;
}

def _request_url(error: BaseException) -> str | None {
    try {
        response: any = getattr(error, "response", None);
        request: any = getattr(error, "request", None) or getattr(response, "request", None);
        url: any = getattr(request, "url", None) or getattr(response, "url", None);
        if not url {
            return None;
        }
        parts: any = urlsplit(`str(url));
        host: any = parts.hostname;
        if not parts.scheme or not host {
            return None;
        }
        if ":" in host {
            host = f"[{host}]";
        }
        if parts.port {
            host = f"{host}:{parts.port}";
        }
        return f"{parts.scheme}://{host}{parts.path}";
    } except Exception {
        return None;
    }
}

def _clean_prefix(prefix: str) -> str {
    prefix = _ESCAPES.sub(" ", prefix).split("{", 1)[0];
    return prefix.strip().rstrip(" -:.,'\"[").strip();
}

def _summarize_html_page(
    text: str,
    *,
    max_prefix: int,
    allow_prefix: bool = True,
    status: int | None = None,
    url: str | None = None,
) -> str | None {
    `match: any = _HTML_TAG.search(text, 0, max_prefix + 1000);
    if `match is None {
        return None;
    }
    raw_prefix: any = text[:`match.start()];
    preamble: any = _PAGE_PREAMBLE.search(raw_prefix);
    head: any = raw_prefix[:preamble.start()] if preamble else raw_prefix;
    if head.strip() and (not allow_prefix or len(head) > max_prefix) {
        return None;
    }
    if "<" in head or "`" in head {
        return None;
    }
    if not _PAGE_TAG.search(text, `match.end(), `match.end() + _TITLE_SCAN_CHARS) {
        return None;
    }
    prefix: any = _clean_prefix(head);
    parts: any = [prefix] if prefix else [];
    page: any = "HTML error page";
    if status and `str(status) not in prefix {
        page = f"HTTP {status} {page}";
    }
    if prefix and "{" not in head and head.rstrip(" '\"").endswith(":") {
        parts[-1] = f"{prefix}:";
    }
    parts.append(page);
    title: any = _HTML_TITLE.search(text, 0, _TITLE_SCAN_CHARS);
    if title {
        title_text: any = " ".join(title.group(1).split())[:_MAX_TITLE_CHARS];
        if title_text {
            parts.append(f"'{title_text}'");
        }
    }
    if url {
        parts.append(f"from {url}");
    }
    return " ".join(parts);
}

glob max_chars_default_: any;

with entry {
    max_chars_default_ = _MAX_ERROR_CHARS;
}

def describe_error(error: BaseException, max_chars: int = max_chars_default_) -> str {
    text: any = `str(error) or `type(error).__name__;
    status: any = http_status_code(error);
    summary: any = _summarize_html_page(
        text, max_prefix=80, allow_prefix=status is not None, status=status, url=_request_url(error)
    );
    if summary is not None {
        text = summary;
    }
    if len(text) > max_chars and not _TRUNCATION_MARKER.search(text) {
        omitted: any = len(text) - max_chars;
        text = f"{text[:max_chars]}... [{omitted} more characters]";
    }
    return text;
}

"""Shorten HTML error pages that third-party retry logs include verbatim."""
class HtmlErrorPageFilter(logging.Filter) {
    def filter(record: logging.LogRecord) -> bool {
        try {
            message: any = record.getMessage();
        } except Exception {
            return True;
        }
        summary: any = _summarize_html_page(message, max_prefix=300);
        if summary is not None {
            record.msg = summary;
            record.args = None;
        }
        return True;
    }
}
