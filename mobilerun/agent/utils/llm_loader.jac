"""
LLM Loader - Centralized logic for loading agent-specific LLMs based on configuration.

This module determines which LLMs are needed based on the agent mode (reasoning vs direct execution)
and loads them from config profiles.
"""

import builtins;

import logging;

import from typing { Any, List, Type }

import from llama_index.core.llms.llm { LLM }

import from pydantic { BaseModel }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""
    Determine which LLM profiles are required based on agent configuration.

    Args:
        config: Mobilerun configuration containing agent settings
        output_model: Optional Pydantic model for structured output extraction

    Returns:
        List of required profile names
    """
def _get_required_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str];

"""
    Validate that required LLM profiles exist in the provided LLM dictionary.

    Args:
        config: Mobilerun configuration containing LLM profiles
        llms: Dictionary containing LLM profiles
        output_model: Optional Pydantic model for structured output extraction

    Returns:
        List of required profile names

    Raises:
        ValueError: If any required profiles are missing from llms
    """
def validate_llm_dict(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
) -> List[builtins.str];

"""
    Validate that required LLM profiles exist in the configuration.

    Args:
        config: Mobilerun configuration containing LLM profiles
        output_model: Optional Pydantic model for structured output extraction

    Returns:
        List of required profile names

    Raises:
        ValueError: If any required profiles are missing from config
    """
def validate_llm_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str];

"""
    Load LLMs required for MobileAgent based on reasoning mode and configuration.

    Args:
        config: Mobilerun configuration containing LLM profiles
        custom_provider: Optional custom provider to use for all agents
        custom_model: Optional custom model to use for all agents
        temperature: Optional temperature override for all agents
        output_model: Optional Pydantic model for structured output extraction
        **kwargs: Additional kwargs to pass to LLM constructor (base_url, api_base, etc.)

    Returns:
        Dictionary mapping agent type to LLM instance:
        - If reasoning=True: {manager, executor, app_opener, structured_output?}
        - If reasoning=False: {fast_agent, app_opener, structured_output?}
        - structured_output is only included if output_model is provided

    Raises:
        ValueError: If required LLM profiles are missing from config
    """
def load_agent_llms(
    config: MobileConfig,
    custom_provider: builtins.str | None = None,
    custom_model: builtins.str | None = None,
    temperature: builtins.float | None = None,
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM];

"""
    Merge a user-provided partial llms dict with LLMs loaded from the
    configuration for any missing required profiles.
    Args:
        config: Mobilerun configuration containing LLM profiles
        llms: Partial dictionary of LLM instances provided by user. Keys may be
            a subset of required agent names.
        output_model: Optional Pydantic model for structured output extraction
        **kwargs: Additional kwargs forwarded when loading missing profiles
    Returns:
        A dictionary containing the union of provided LLMs and any LLMs loaded
        from config for missing required profiles.
    Raises:
        ValueError: If required profiles are missing from both the provided
            llms dict and the config profiles.
    """
def merge_llms_with_config(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM];
