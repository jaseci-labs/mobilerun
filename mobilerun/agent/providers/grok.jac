import from __future__ { annotations }

import from collections.abc { Mapping, MutableMapping }

import from typing { Any }

glob GROK_API_DEFAULT_MODEL: any = "grok-4.6";

glob GROK_OAUTH_DEFAULT_MODEL: any = "grok-4.7";

glob GROK_API_MODELS: any = (GROK_API_DEFAULT_MODEL,);

glob GROK_OAUTH_MODELS: any = (GROK_OAUTH_DEFAULT_MODEL, "grok-4.6");

glob GROK_OAUTH_LEGACY_MODELS: any = ("grok-4.5",);

glob GROK_MODEL_ALIASES: any = {"grok-4.5-latest": "grok-4.5"};

glob XAI_API_BASE: any = "https://api.x.ai/v1";

glob GROK_CONTEXT_WINDOW: any = 500000;

glob GROK_UNSUPPORTED_SAMPLING_PARAMS: any = frozenset({
    "presence_penalty",
    "frequency_penalty",
    "stop",
});

def normalize_grok_model_id(model: object) -> str;

def sanitize_grok_responses_kwargs(
    payload: MutableMapping[str, Any],
    *,
    omit_sampler_fields: bool = False,
    omit_tool_choice: bool = False,
) -> MutableMapping[str, Any];
