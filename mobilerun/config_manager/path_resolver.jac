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
    static def get_project_root -> Path {
        return Path(__file__).resolve().parents[1];
    }

    static def resolve(
        path: Union[builtins.str, Path],
        create_if_missing: builtins.bool = False,
        must_exist: builtins.bool = False,
    ) -> Path {
        path = Path(path).expanduser();
        if path.is_absolute() {
            if must_exist and not path.exists() {
                raise FileNotFoundError(f"Path not found: {path}");
            }
            return path;
        }
        cwd_path: any = Path.cwd() / path;
        package_path: any = PathResolver.get_project_root() / path;
        if create_if_missing {
            return cwd_path;
        }
        if cwd_path.exists() {
            return cwd_path;
        }
        if package_path.exists() {
            return package_path;
        }
        if must_exist {
            raise FileNotFoundError(
                f"Path not found in:\n  - Working dir: {cwd_path}\n  - Package dir: {package_path}"
            );
        }
        return cwd_path;
    }
}
