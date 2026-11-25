"""Shared Grok/xAI model and transport metadata."""

import from __future__ { annotations }

import from collections.abc { Mapping, MutableMapping }

import from typing { Any }

glob GROK_API_DEFAULT_MODEL: any = "grok-4.6";

glob GROK_OAUTH_DEFAULT_MODEL: any = "grok-4.7";

glob GROK_API_MODELS: any;

glob GROK_OAUTH_MODELS: any;

glob GROK_OAUTH_LEGACY_MODELS: any;

glob GROK_MODEL_ALIASES: any;

glob XAI_API_BASE: any;

glob GROK_CONTEXT_WINDOW: any;

glob GROK_UNSUPPORTED_SAMPLING_PARAMS: any;

with entry {
    GROK_API_MODELS = (GROK_API_DEFAULT_MODEL,);
    GROK_OAUTH_MODELS = (GROK_OAUTH_DEFAULT_MODEL, "grok-4.6");
    GROK_OAUTH_LEGACY_MODELS = ("grok-4.5",);
    GROK_MODEL_ALIASES = {"grok-4.5-latest": "grok-4.5"};

    XAI_API_BASE = "https://api.x.ai/v1";
    GROK_CONTEXT_WINDOW = 500000;
    GROK_UNSUPPORTED_SAMPLING_PARAMS = frozenset({"presence_penalty", "frequency_penalty", "stop"});
}

"""Normalize public xAI/Grok aliases to Mobilerun's canonical model id."""
def normalize_grok_model_id(model: object) -> str;

"""Apply Grok's Responses API parameter contract to a final payload."""
def sanitize_grok_responses_kwargs(
    payload: MutableMapping[str, Any],
    *,
    omit_sampler_fields: bool = False,
    omit_tool_choice: bool = False,
) -> MutableMapping[str, Any];
