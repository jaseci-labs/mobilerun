import builtins;

import inspect;

import from typing { Any }

def portal_version_kwargs(
    setup_fn: any, *, in_place: builtins.bool = False
) -> builtins.dict[builtins.str, Any] {
    params: any = inspect.signature(setup_fn).parameters;
    kwargs: builtins.dict[builtins.str, Any] = {};
    if "version" in params {
        kwargs["version"] = __version__;
    }
    if in_place and "uninstall" in params {
        kwargs["uninstall"] = False;
    }
    return kwargs;
}
