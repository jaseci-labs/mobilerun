"""Portal auto-setup helpers."""

import builtins;

import inspect;

import from typing { Any, Callable }

"""Key the Portal version map by mobilerun's version when core-local allows it.

    With in_place, also ask for an update that keeps Portal's data.
    """
def portal_version_kwargs(
    setup_fn: any, *, in_place: builtins.bool = False
) -> builtins.dict[builtins.str, Any];
