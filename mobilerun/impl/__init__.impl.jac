impl __getattr__(name) -> any {
    if name in _LEGACY_ALIASES {
        import warnings;

        new_name: any = _LEGACY_ALIASES[name];
        warnings.warn(
            f"{name} has been renamed to {new_name}. Update your code to use {new_name}.",
            DeprecationWarning,
            stacklevel=2,
        );
        return getattr(sys.modules[__name__], new_name);
    }
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}");
}
