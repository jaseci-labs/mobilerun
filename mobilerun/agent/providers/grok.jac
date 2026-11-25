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

def normalize_grok_model_id(model: object) -> str {
    model_id: any = `str(model or "").strip();
    if model_id.startswith("xai/") {
        model_id = model_id.removeprefix("xai/");
    }
    return GROK_MODEL_ALIASES.get(model_id, model_id);
}

def sanitize_grok_responses_kwargs(
    payload: MutableMapping[str, Any],
    *,
    omit_sampler_fields: bool = False,
    omit_tool_choice: bool = False,
) -> MutableMapping[str, Any] {
    filtered_params: any = `set(GROK_UNSUPPORTED_SAMPLING_PARAMS);
    if omit_sampler_fields {
        filtered_params.update(("temperature", "top_p"));
    }
    if omit_tool_choice {
        filtered_params.add("tool_choice");
    }

    for param in filtered_params {
        payload.pop(param, None);
    }
    payload["store"] = False;
    payload.pop("reasoning", None);
    extra_body: any = payload.get("extra_body");
    if extra_body is not None {
        if not isinstance(extra_body, Mapping) {
            payload.pop("extra_body", None);
        } else {
            sanitized_extra_body: any = `dict(extra_body);
            for param in filtered_params {
                sanitized_extra_body.pop(param, None);
            }
            for param in ("model", "store", "reasoning") {
                sanitized_extra_body.pop(param, None);
            }
            payload["extra_body"] = sanitized_extra_body;
        }
    }
    return payload;
}
