impl get_migrations -> List {
    migrations: any = [];
    migrations_dir: any = Path(__file__).parent;

    _: any;
    for (_, name, _) in pkgutil.iter_modules([`str(migrations_dir)]) {
        if name.startswith("v") and name[1:4].isdigit() {
            module: any = importlib.import_module(f".{name}", package=__name__);
            if hasattr(module, "VERSION") and hasattr(module, "migrate") {
                migrations.append(module);
            }
        }
    }

    return sorted(migrations, key=lambda (m) -> any { m.VERSION });
}

impl migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    version: any = config.get("_version", 0);

    if version >= CURRENT_VERSION {
        return config;
    }

    migrations: any = get_migrations();

    for migration in migrations {
        if migration.VERSION > version {
            config = migration.migrate(config);
            config["_version"] = migration.VERSION;
        }
    }

    return config;
}
