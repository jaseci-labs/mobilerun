import builtins;

import logging;

import from typing { Any, List, Type }

import from llama_index.core.llms.llm { LLM }

import from pydantic { BaseModel }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

def _get_required_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str];

def validate_llm_dict(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
) -> List[builtins.str];

def validate_llm_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str];

def load_agent_llms(
    config: MobileConfig,
    custom_provider: builtins.str | None = None,
    custom_model: builtins.str | None = None,
    temperature: builtins.float | None = None,
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM];

def merge_llms_with_config(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM];
