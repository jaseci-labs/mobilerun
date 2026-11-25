import builtins;

import from pathlib { Path }

import from typing { Any, Dict }

import aiofiles;

import from jinja2.sandbox { ImmutableSandboxedEnvironment }

"""Jinja2 template renderer - loads from absolute file paths using aiofiles."""
class PromptLoader {
    static has _env: any = None;

    class def _get_environment -> ImmutableSandboxedEnvironment;

    static async def load_prompt(
        file_path: builtins.str, variables: Dict[builtins.str, Any] = None
    ) -> builtins.str;

    static def render_template(
        template_string: builtins.str, variables: Dict[builtins.str, Any] = None
    ) -> builtins.str;
}
