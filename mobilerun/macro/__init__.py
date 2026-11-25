"""Mobilerun Macro Module - Record and replay UI automation sequences."""

import importlib

__all__ = ["MacroPlayer", "replay_macro_file", "replay_macro_folder"]


def __getattr__(name):
    if name in __all__:
        return getattr(importlib.import_module("mobilerun.macro.replay"), name)
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
