import builtins;

import from pathlib { Path }

import from typing { Union }

"""
    Unified path resolver for all Mobilerun file operations.

    Resolution order:
    1. Absolute paths → use as-is
    2. Relative paths → check working dir first, then package dir (bundled resources)
    3. For creation → prefer working dir
    """
class PathResolver {
    static def get_project_root -> Path;

    static def resolve(
        path: Union[builtins.str, Path],
        create_if_missing: builtins.bool = False,
        must_exist: builtins.bool = False,
    ) -> Path;
}
