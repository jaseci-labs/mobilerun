impl __getattr__(name) -> any {
    if name in __all__ {
        return getattr(importlib.import_module("mobilerun.macro.replay"), name);
    }
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}");
}
