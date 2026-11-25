"""The text of a project module's source, whether it is Python or Jac."""

from pathlib import Path

ROOT = next(d for d in Path(__file__).resolve().parents if (d / "jac.toml").exists())


def module_source(module_name: str) -> str:
    path = ROOT / module_name.replace(".", "/")
    for candidate in (path.with_suffix(".py"), path / "__init__.py"):
        if candidate.exists():
            return candidate.read_text(encoding="utf-8")
    for stem, folder in ((path.name, path.parent), ("__init__", path)):
        jac = folder / f"{stem}.jac"
        if jac.exists():
            annex = folder / "impl" / f"{stem}.impl.jac"
            extra = annex.read_text(encoding="utf-8") if annex.exists() else ""
            return jac.read_text(encoding="utf-8") + extra
    raise FileNotFoundError(module_name)
