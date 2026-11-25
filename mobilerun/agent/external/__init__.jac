import from __future__ { annotations }

import asyncio;

import importlib;

import logging;

import from pathlib { Path }

import from typing { Any, Callable, Dict, List, Optional, TypedDict }

glob logger: any = logging.getLogger("mobilerun");

glob _EXTERNAL_DIR: any;

with entry {
    _EXTERNAL_DIR = Path(__file__).parent;
}

"""Type for a loaded external agent module."""
class ExternalAgentModule(TypedDict) {
    has run: Callable;

    has config: Dict[str, Any];
}

def list_agents -> List[str] {
    agents: list[str] = [];
    for item in _EXTERNAL_DIR.iterdir() {
        if item.name.startswith(("_", ".")) {
            continue;
        }
        if item.is_file() and item.suffix == ".py" {
            agents.append(item.stem);
        } elif item.is_dir() and (item / "__init__.py").exists() {
            agents.append(item.name);
        }
    }
    return sorted(agents);
}

def load_agent(name: str) -> Optional[ExternalAgentModule] {
    try {
        module: any = importlib.import_module(f"mobilerun.agent.external.{name}");

        if not hasattr(module, "run") {
            logger.error(f"External agent '{name}' missing run() function");
            return None;
        }

        if not asyncio.iscoroutinefunction(module.run) {
            logger.error(
                f"External agent '{name}' has a sync run() — it must be async (async def run)"
            );
            return None;
        }

        return {"run": module.run, "config": getattr(module, "DEFAULT_CONFIG", {})};
    } except ImportError as e {
        logger.error(f"Failed to load external agent '{name}': {e}");
        return None;
    }
}
