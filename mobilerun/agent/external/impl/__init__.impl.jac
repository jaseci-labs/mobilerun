impl list_agents -> List[str] {
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

impl load_agent(name: str) -> Optional[ExternalAgentModule] {
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
