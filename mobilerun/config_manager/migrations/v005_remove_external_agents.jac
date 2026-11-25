"""Migration v5: Remove legacy external agent example configs."""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 5;

"""Remove legacy mai_ui and autoglm example entries from external_agents."""
def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
