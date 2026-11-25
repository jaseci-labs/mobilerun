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

def _normalize_base_url(base_url: str | None) -> str {
    return `str(base_url or "").strip().rstrip("/").lower();
}

def minimax_model_context_window(model: object) -> int | None {
    return MINIMAX_MODEL_CONTEXT_WINDOWS.get(`str(model or "").strip());
}

def is_minimax_base_url(base_url: str | None) -> bool {
    return _normalize_base_url(base_url) in {
        _normalize_base_url(url)
        for url in (MINIMAX_GLOBAL_BASE_URL, MINIMAX_CHINA_BASE_URL, MINIMAX_LEGACY_BASE_URL)
    };
}

def apply_minimax_defaults(kwargs: dict[str, Any]) -> dict[str, Any] {
    kwargs = `dict(kwargs);
    kwargs.setdefault("is_function_calling_model", True);
    kwargs.setdefault("pydantic_program_mode", PydanticProgramMode.LLM);
    context_window: any = minimax_model_context_window(kwargs.get("model"));
    if context_window is not None {
        kwargs.setdefault("context_window", context_window);
    }
    additional_kwargs: any = `dict(kwargs.get("additional_kwargs") or {});
    extra_body: any = `dict(additional_kwargs.get("extra_body") or {});
    extra_body.setdefault("reasoning_split", True);
    additional_kwargs["extra_body"] = extra_body;
    additional_kwargs.setdefault("stream_options", {"include_usage": True});
    kwargs["additional_kwargs"] = additional_kwargs;
    return kwargs;
}

@lru_cache(maxsize=1)
def _warn_about_legacy_endpoint_once -> None {
    logger.warning(
        f"This MiniMax profile uses the legacy endpoint {MINIMAX_LEGACY_BASE_URL}. The profile was not changed. Re-run `mobilerun configure` and choose either Global ({MINIMAX_GLOBAL_BASE_URL}) or Mainland China ({MINIMAX_CHINA_BASE_URL}).",
    );
}

def warn_if_legacy_minimax_endpoint(base_url: str | None) -> None {
    if _normalize_base_url(base_url) == _normalize_base_url(MINIMAX_LEGACY_BASE_URL) {
        _warn_about_legacy_endpoint_once();
    }
}
