"""Mobilerun Macro Module - Record and replay UI automation sequences."""

import importlib;

glob __all__: any = ["MacroPlayer", "replay_macro_file", "replay_macro_folder"];

def __getattr__(name) -> any;
