"""
Unified path resolution for Mobilerun.

This module provides a single path resolver that handles all file path resolution
with consistent priority: working directory first, then package directory.
"""

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
obj PathResolver {
    """
        Get the package root directory (where config/ bundled resources live).

        This is 1 parent up from this file's location:
        mobilerun/config_manager/path_resolver.py -> mobilerun/ (package root)
        """
    static def get_project_root -> Path;

    """
        Universal path resolver for all file operations.

        Resolution order:
        1. Absolute path → use as-is
        2. Relative path:
           - If creating: prefer working directory (for user outputs)
           - If reading: check working dir first, then package dir (for bundled resources)
        3. If must_exist and not found → raise FileNotFoundError

        Args:
            path: Path to resolve (str or Path object). Use absolute paths to avoid
                 ambiguity, or relative paths for portable configs.
            create_if_missing: If True, prefer working dir for relative paths (output mode).
                              Does not create the file/directory, just determines the location.
            must_exist: If True, raise FileNotFoundError if path doesn't exist after resolution.
                       Use for required config files and prompts.

        Returns:
            Resolved absolute Path object

        Raises:
            FileNotFoundError: If must_exist=True and path not found in any location.
                              Error message includes both checked locations.

        Security Note:
            Expands tilde (~) to user home directory. Does not follow symlinks during
            resolution, but the returned path may point to a symlink target.

        Examples:
            # Reading config (checks CWD first, then package dir)
            config_path = PathResolver.resolve("config.yaml")

            # Creating output (creates in CWD)
            output_dir = PathResolver.resolve("trajectories", create_if_missing=True)

            # Loading prompts (must exist, checks both locations)
            prompt = PathResolver.resolve("config/prompts/system.jinja2", must_exist=True)

            # Absolute path (used as-is)
            abs_path = PathResolver.resolve("/tmp/output")
        """
    static def resolve(
        path: Union[builtins.str, Path],
        create_if_missing: builtins.bool = False,
        must_exist: builtins.bool = False,
    ) -> Path;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
