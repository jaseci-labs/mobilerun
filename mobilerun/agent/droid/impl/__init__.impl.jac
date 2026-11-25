impl __getattr__(name) -> any {
    if name in _LEGACY_ALIASES {
        import warnings;

        warnings.warn(
            f"{name} has been renamed. Update your imports.", DeprecationWarning, stacklevel=2
        );
        return _LEGACY_ALIASES[name];
    }
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}");
}
