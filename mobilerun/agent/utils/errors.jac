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

def http_status_code(error: BaseException) -> int | None;

def _request_url(error: BaseException) -> str | None;

def _clean_prefix(prefix: str) -> str;

def _summarize_html_page(
    text: str,
    *,
    max_prefix: int,
    allow_prefix: bool = True,
    status: int | None = None,
    url: str | None = None,
) -> str | None;

glob max_chars_default_: any;

with entry {
    max_chars_default_ = _MAX_ERROR_CHARS;
}

def describe_error(error: BaseException, max_chars: int = max_chars_default_) -> str;

"""Shorten HTML error pages that third-party retry logs include verbatim."""
class HtmlErrorPageFilter(logging.Filter) {
    def filter(record: logging.LogRecord) -> bool;
}
