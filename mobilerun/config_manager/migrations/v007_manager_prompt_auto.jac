import builtins;

import from typing { Any, Dict }

glob VERSION: any = 7;

glob _OLD_DEFAULT_MANAGER_SYSTEM_PROMPT: any = "config/prompts/manager/system.jinja2";

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    agent: any = config.get("agent");
    if not isinstance(agent, `dict) {
        return config;
    }

    manager: any = agent.get("manager");
    if not isinstance(manager, `dict) {
        return config;
    }

    if manager.get("system_prompt") == _OLD_DEFAULT_MANAGER_SYSTEM_PROMPT {
        manager["system_prompt"] = None;
    }

    return config;
}
