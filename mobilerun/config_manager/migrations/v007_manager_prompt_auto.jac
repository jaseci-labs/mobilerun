"""Migration v7: use automatic manager prompt selection by default.

Configs produced before v7 stored the bundled stateful manager prompt as an
explicit path. That pin prevents ``stateless: true`` from selecting the bundled
stateless prompt. Convert only that exact former default to ``None``. Any other
path remains an intentional override; an intentional pin to the former default
can be restored after migration.
"""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 7;

glob _OLD_DEFAULT_MANAGER_SYSTEM_PROMPT: any = "config/prompts/manager/system.jinja2";

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
