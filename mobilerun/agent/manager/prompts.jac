"""
Prompts for the ManagerAgent.
"""

import builtins;

import operator;

import re;

import from dataclasses { dataclass }

glob FINAL_RESPONSE_TAGS: any = ("request_accomplished", "answer");

glob _MANAGER_RESULT_TAGS: any;

glob _MANAGER_METADATA_TAGS: any;

glob _MANAGER_RESPONSE_ENVELOPE_TAGS: any;

glob _TAG_TOKEN_RE: any;

glob _SPACED_MANAGER_RESULT_TAG_RE: any;

glob _TRAILING_UNTERMINATED_MANAGER_RESULT_TAG_RE: any;

glob _ATTRIBUTE_RE: any;

with entry {
    _MANAGER_RESULT_TAGS = ("plan", *FINAL_RESPONSE_TAGS);
    _MANAGER_METADATA_TAGS = ("thought", "add_memory", "progress_summary");
    _MANAGER_RESPONSE_ENVELOPE_TAGS = (*_MANAGER_RESULT_TAGS, *_MANAGER_METADATA_TAGS);
    _TAG_TOKEN_RE = re.compile(
        "<(?P<closing>/)?(?P<tag>[A-Za-z][\\w:.-]*)\n    (?P<attrs>(?:[^<>\"']++|\"[^\"]*\"|'[^']*')*+)>",
        re.DOTALL | re.VERBOSE,
    );
    _SPACED_MANAGER_RESULT_TAG_RE = re.compile(
        "<(?:\\s+/?\\s*|/\\s+)(?P<tag>plan|request_accomplished|answer)\\b", re.IGNORECASE
    );
    _TRAILING_UNTERMINATED_MANAGER_RESULT_TAG_RE = re.compile(
        "<(?P<closing>/)?(?P<tag>plan|request_accomplished|answer)\\b[^<>]*\\Z", re.IGNORECASE
    );
    _ATTRIBUTE_RE = re.compile(
        "\\s+(?P<name>[^\\s=/>]+)\n    (?:\\s*=\\s*(?:(?P<quote>[\"'])(?P<quoted_value>.*?)(?P=quote)\n    |(?P<bare_value>[^\\s>]+)))?",
        re.DOTALL | re.VERBOSE,
    );
}

@dataclass(frozen=True)
class ManagerResponseValidation {
    has is_valid: builtins.bool;

    has error_message: builtins.str | None = None;
}

"""Raised when the manager cannot produce a valid response after retries."""
class ManagerResponseValidationError(RuntimeError) {}

def _find_tag_matches(
    response: builtins.str, tag: builtins.str
) -> builtins.list[re.Match[builtins.str]];

def _tag_content(`match: re.Match[builtins.str]) -> builtins.str;

"""Return a final tag's one valid, explicit success attribute.

    Only an attribute whose *name* is exactly ``success`` is accepted.  This
    deliberately rejects look-alikes such as ``data-success`` and strings in
    another attribute's value, as well as duplicate or unquoted attributes.
    """
def _success_from_attrs(attrs: builtins.str) -> builtins.bool | None;

"""Find well-formed top-level result tags and report unsafe control tags.

    Manager output is XML-like rather than a complete XML document, so a small
    stack parser is more robust than globally matching ``<plan>`` and terminal
    tags.  In particular, manager response tags inside metadata or a result
    must not turn into a top-level plan or final result.  Ordinary markup in
    a top-level result remains body text.
    """
def _find_top_level_manager_result_tags(
    response: builtins.str
) -> builtins.tuple[builtins.list[builtins.dict[builtins.str, builtins.str]], builtins.list[builtins.str]];

"""
    Parse manager LLM response into structured dict.

    Extracts XML-style tags from the response:
    - <thought>...</thought>
    - <add_memory>...</add_memory>
    - <plan>...</plan>
    - <request_accomplished success="true|false">...</request_accomplished> (answer)

    Also derives:
    - current_subgoal: first line of plan (with list markers removed)
    - If first item is <script> tag, extract script content as current_subgoal
    - success: bool | None parsed from request_accomplished success attribute

    Args:
        response: Raw LLM response text

    Returns:
        Dict with keys:
            - thought: str
            - memory: str
            - plan: str
            - current_subgoal: str (first line of plan, cleaned, or script content)
            - answer: str (from request_accomplished tag)
            - success: bool | None (True/False if task complete, None if still in progress)
    """
def parse_manager_response(response: builtins.str) -> builtins.dict;

"""Validate the manager output contract parsed by parse_manager_response."""
def validate_manager_response(parsed: builtins.dict) -> ManagerResponseValidation;
