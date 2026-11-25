"""
Prompt loading utility using Jinja2 templates.

Templates are rendered in an immutable sandboxed environment, so template code
cannot reach Python internals or mutate the objects passed into it.

Features:
- Loads from absolute file paths (resolved by AgentConfig + PathResolver)
- Conditional rendering: {% if variable %}...{% endif %}
- Loops with slicing: {% for item in items[-5:] %}...{% endfor %}
- Filters: {{ variable|default("fallback") }}
- Missing variables: silently ignored (renders as empty string)
- Extra variables: silently ignored
"""

import builtins;

import from pathlib { Path }

import from typing { Any, Dict }

import aiofiles;

import from jinja2.sandbox { ImmutableSandboxedEnvironment }

"""Jinja2 template renderer - loads from absolute file paths using aiofiles."""
obj PromptLoader {
    static has _env: any = None;

    """Get or create cached sandboxed Jinja2 environment."""
    class def _get_environment -> ImmutableSandboxedEnvironment;

    """
        Load and render Jinja2 template from absolute file path.

        Path resolution is handled by AgentConfig + PathResolver.
        This method just loads and renders.

        Args:
            file_path: ABSOLUTE path to template file (from AgentConfig methods)
            variables: Dict of variables to pass to template
                      - Missing variables: silently ignored (render as empty string)
                      - Extra variables: silently ignored

        Returns:
            Rendered prompt string

        Raises:
            FileNotFoundError: If template file doesn't exist

        """
    static async def load_prompt(
        file_path: builtins.str, variables: Dict[builtins.str, Any] = None
    ) -> builtins.str;

    """
        Render Jinja2 template from string (NOT file path).

        This is used for custom prompts passed at runtime. Rendering happens in
        a sandbox: unsafe attribute access raises jinja2.exceptions.SecurityError.

        Args:
            template_string: Jinja2 template as string
            variables: Dict of variables to pass to template
                      - Missing variables: silently ignored (render as empty string)
                      - Extra variables: silently ignored

        Returns:
            Rendered prompt string

        """
    static def render_template(
        template_string: builtins.str, variables: Dict[builtins.str, Any] = None
    ) -> builtins.str;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
