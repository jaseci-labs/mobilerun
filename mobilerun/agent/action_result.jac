import from __future__ { annotations }

import from dataclasses { dataclass }

"""What the agent sees after an action runs."""
@dataclass
class ActionResult {
    has success: bool;

    has summary: str;

    def __str__ -> str;
}
