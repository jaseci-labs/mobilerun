"""
Shared event handler for CLI and SDK.

Translates workflow events into ``logging`` calls with ``extra`` params
(color, step_increment, etc.).  The actual rendering is handled by
whichever ``logging.Handler`` is attached (CLILogHandler, TUILogHandler, …).
"""

import builtins;

import logging;

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""Translates workflow events into logger calls.

    No UI state tracking — purely converts events into log records with
    ``extra`` params so that any attached handler can render them.
    """
obj EventHandler {
    def handle(event) -> None;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
