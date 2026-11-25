import builtins;

import importlib;

import pkgutil;

import from pathlib { Path }

import from typing { Any, Dict, List }

glob CURRENT_VERSION: any = 7;

def get_migrations -> List;

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
