import builtins;

import logging;

import from rich.console { Console }

glob COLORS: any = frozenset({"blue", "cyan", "green", "red", "yellow", "magenta", "white", "dim"});

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
