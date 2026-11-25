"""Migration v6: Treat default-shaped ``tools.disabled_tools`` as the sentinel.

Older generated configs (v5) shipped the literal default list
``[click_at, click_area, long_press_at]``. The schema now uses ``None`` as the
"use framework default" sentinel — an explicit list is honored verbatim and
disables the vision auto-unmask for ``click_at`` (and raises in
screenshot-only modes when coordinate tools are listed).

This migration only converts the **exact** default list to ``None``. Supersets
like ``[click_at, click_area, long_press_at, wait]`` are intentionally left
untouched so non-vision runs continue disabling the coordinate tools the user
expected. ``_effective_disabled_tools`` gives those legacy supersets a
graceful path through screenshot-only modes (coord tools are stripped with a
warning instead of raising ValueError).
"""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 6;

glob _OLD_DEFAULT: any = {"click_at", "click_area", "long_press_at"};

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
