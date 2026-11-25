import builtins;

import from typing { Any, Dict }

glob VERSION: any = 7;

glob _OLD_DEFAULT_MANAGER_SYSTEM_PROMPT: any = "config/prompts/manager/system.jinja2";

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
