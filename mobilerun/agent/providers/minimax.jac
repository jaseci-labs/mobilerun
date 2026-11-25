import from __future__ { annotations }

import logging;

import from functools { lru_cache }

import from typing { Any }

import from llama_index.core.types { PydanticProgramMode }

glob MINIMAX_GLOBAL_BASE_URL: any = "https://api.minimax.io/v1";

glob MINIMAX_CHINA_BASE_URL: any = "https://api.minimaxi.com/v1";

glob MINIMAX_LEGACY_BASE_URL: any = "https://api.minimaxi.chat/v1";

glob MINIMAX_DEFAULT_MODEL: any = "MiniMax-M3";

glob MINIMAX_MODEL_CONTEXT_WINDOWS: any = {
    "MiniMax-M3": 1000000,
    "MiniMax-M2.7": 204800,
    "MiniMax-M2.7-highspeed": 204800,
    "MiniMax-M2.5": 204800,
    "MiniMax-M2.5-highspeed": 204800,
    "MiniMax-M2.1": 204800,
    "MiniMax-M2.1-highspeed": 204800,
    "MiniMax-M2": 204800,
};

glob logger: any = logging.getLogger("mobilerun");

def _normalize_base_url(base_url: str | None) -> str;

def minimax_model_context_window(model: object) -> int | None;

def is_minimax_base_url(base_url: str | None) -> bool;

def apply_minimax_defaults(kwargs: dict[str, Any]) -> dict[str, Any];

@lru_cache(maxsize=1)
def _warn_about_legacy_endpoint_once -> None;

def warn_if_legacy_minimax_endpoint(base_url: str | None) -> None;
