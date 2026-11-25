"""Migration v4: Remove deprecated agent configs and rename prompt paths."""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 4;

glob _OLD_SYSTEM_PROMPT: any = "config/prompts/codeact/tools_system.jinja2";

glob _OLD_USER_PROMPT: any = "config/prompts/codeact/tools_user.jinja2";

glob _NEW_SYSTEM_PROMPT: any = "config/prompts/fast_agent/system.jinja2";

glob _NEW_USER_PROMPT: any = "config/prompts/fast_agent/user.jinja2";

"""Strip removed agent configs and update prompt paths."""
def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
