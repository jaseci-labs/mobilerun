"""
Logging handlers for Mobilerun.

Provides CLILogHandler (Rich colored terminal output) and TUILogHandler
(record buffer for deferred Textual rendering). Both support extra params:

    color:      logger.info("msg", extra={"color": "blue"})
    stream:     logger.info(token, extra={"stream": True})
    stream_end: logger.info("", extra={"stream_end": True})
"""

import builtins;

import logging;

import from rich.console { Console }

glob COLORS: any;

with entry {
    COLORS = frozenset({"blue", "cyan", "green", "red", "yellow", "magenta", "white", "dim"});
}

"""Replace all handlers on the ``mobilerun`` logger."""
def configure_logging(debug: builtins.bool, handler: logging.Handler) -> None;

glob level_default_: any;

with entry {
    level_default_ = logging.NOTSET;
}

"""Rich-colored line output for CLI and SDK use."""
class CLILogHandler(logging.Handler) {
    def init(level: builtins.int = level_default_);

    def emit(record: logging.LogRecord) -> None;
}

glob level_default__: any;

with entry {
    level_default__ = logging.NOTSET;
}

"""Captures log records for TUI rendering.

    Args:
        on_record: Optional callback invoked for every record with the record dict.
    """
class TUILogHandler(logging.Handler) {
    def init(on_record=None, level: builtins.int = level_default__);

    def emit(record: logging.LogRecord) -> None;
}
