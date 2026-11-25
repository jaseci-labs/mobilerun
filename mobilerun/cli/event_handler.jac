import builtins;

import logging;

glob logger: any = logging.getLogger("mobilerun");

"""Translates workflow events into logger calls.

    No UI state tracking — purely converts events into log records with
    ``extra`` params so that any attached handler can render them.
    """
class EventHandler {
    def handle(event) -> None;
}
