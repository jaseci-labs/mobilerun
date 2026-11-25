"""Config migration system."""

import builtins;

import importlib;

import pkgutil;

import from pathlib { Path }

import from typing { Any, Dict, List }

glob CURRENT_VERSION: any = 7;

"""Discover and load all migration modules."""
def get_migrations -> List;

"""Run all pending migrations on config."""
def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
