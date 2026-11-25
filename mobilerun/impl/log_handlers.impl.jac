impl configure_logging(debug: builtins.bool, handler: logging.Handler) -> None {
    logger: any = logging.getLogger("mobilerun");
    logger.handlers = [];
    logger.addHandler(handler);
    logger.setLevel(logging.DEBUG if debug else logging.INFO);
    logger.propagate = False;
}

impl CLILogHandler.init(level: builtins.int = level_default_) {
    super.__init__(level);
    self.console = Console();
}

impl CLILogHandler.emit(record: logging.LogRecord) -> None {
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

impl TUILogHandler.init(on_record=None, level: builtins.int = level_default__) {
    super.__init__(level);
    self.on_record = on_record;
    self.records = [];
}

impl TUILogHandler.emit(record: logging.LogRecord) -> None {
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
