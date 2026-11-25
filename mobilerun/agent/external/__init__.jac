import from __future__ { annotations }

import asyncio;

import importlib;

import logging;

import from pathlib { Path }

import from typing { Any, Callable, Dict, List, Optional, TypedDict }

glob logger: any;

glob _EXTERNAL_DIR: any;

with entry {
    logger = logging.getLogger("mobilerun");

    _EXTERNAL_DIR = Path(__file__).parent;
}

"""Type for a loaded external agent module."""
class ExternalAgentModule(TypedDict) {
    has run: Callable;

    has config: Dict[str, Any];
}

def list_agents -> List[str];

def load_agent(name: str) -> Optional[ExternalAgentModule];
