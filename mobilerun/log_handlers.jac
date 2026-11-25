import builtins;

import logging;

import from rich.console { Console }

glob COLORS: any = frozenset({"blue", "cyan", "green", "red", "yellow", "magenta", "white", "dim"});

def configure_logging(debug: builtins.bool, handler: logging.Handler) -> None {
    logger: any = logging.getLogger("mobilerun");
    logger.handlers = [];
    logger.addHandler(handler);
    logger.setLevel(logging.DEBUG if debug else logging.INFO);
    logger.propagate = False;
}

glob level_default_: any;

with entry {
    level_default_ = logging.NOTSET;
}

"""Rich-colored line output for CLI and SDK use."""
class CLILogHandler(logging.Handler) {
    def init(level: builtins.int = level_default_) {
        super.__init__(level);
        self.console = Console();
    }

    def emit(record: logging.LogRecord) -> None {
        try {
            msg: any = self.format(record);
            color: any = getattr(record, "color", None);
            stream: any = getattr(record, "stream", False);
            stream_end: any = getattr(record, "stream_end", False);

            if stream {
                self.console.print(msg, end="", highlight=False, markup=False);
            } elif stream_end {
                self.console.print("", highlight=False);
            } elif color and color in COLORS {
                self.console.print(msg, style=color, highlight=False, markup=False);
            } else {
                self.console.print(msg, highlight=False, markup=False);
            }
        } except Exception {
            self.handleError(record);
        }
    }
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
    def init(on_record=None, level: builtins.int = level_default__) {
        super.__init__(level);
        self.on_record = on_record;
        self.records = [];
    }

    def emit(record: logging.LogRecord) -> None {
        try {
            msg: any = self.format(record);
            color: any = getattr(record, "color", None);
            stream: any = getattr(record, "stream", False);
            stream_end: any = getattr(record, "stream_end", False);

            rec: any = {
                "msg": msg,
                "color": color,
                "stream": stream,
                "stream_end": stream_end,
                "level": record.levelno,
            };
            self.records.append(rec);

            if self.on_record {
                self.on_record(rec);
            }
        } except Exception {
            self.handleError(record);
        }
    }
}
