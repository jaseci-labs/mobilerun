"""
Prompts for the ExecutorAgent.
"""

import builtins;

"""
    Parse the Executor LLM response.

    Extracts:
    - thought: Content between "### Thought" and "### Action"
    - action: Content between "### Action" and "### Description"
    - description: Content after "### Description"

    Args:
        response: Raw LLM response string

    Returns:
        Dictionary with 'thought', 'action', 'description' keys
    """
def parse_executor_response(response: builtins.str) -> builtins.dict;
