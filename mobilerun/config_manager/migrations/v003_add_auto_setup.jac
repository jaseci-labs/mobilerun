"""Migration v3: Add device.auto_setup field."""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 3;

"""Add auto_setup to device config (defaults to True)."""
def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
