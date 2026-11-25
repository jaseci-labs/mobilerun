"""Safe shared storage for Mobilerun authentication profiles.

All OAuth providers and saved API keys share one JSON object.  Writes therefore
need to be serialized across processes and must preserve slots owned by other
providers.
"""

import builtins;

import from __future__ { annotations }

import json;

import os;

import tempfile;

import from contextlib { AbstractContextManager }

import from pathlib { Path }

import from typing { Any, Callable, TypeVar }

import from filelock { FileLock }

"""Raised when an existing auth-profiles file is not a JSON object."""
class AuthProfileFormatError(ValueError) {}

glob _T: any;

glob _FCHMOD: Callable[[int, int], None] | None;

with entry {
    _T = TypeVar("_T");
    _FCHMOD = getattr(os, "fchmod", None);
}

"""A locked read/modify/write transaction over an auth profile file."""
class AuthProfileTransaction(AbstractContextManager) {
    def init(
        store: "AuthProfileStore",
        *,
        lock_timeout: float | None = None,
        before_commit: Callable[[], None] | None = None,
    );

    def __enter__ -> "AuthProfileTransaction";

    """The locked profile object. Mutate it only via :meth:`update`."""
    has profile: dict[str, Any] {
        getter {
            return self._profile;
        }
    }

    def get_slot(slot: str) -> dict[str, Any] | None;

    def set_slot(slot: str, payload: dict[str, Any]) -> None;

    def update(updater: Callable[[dict[str, Any]], _T]) -> _T;

    def __exit__(exc_type: object, exc: object, traceback: object) -> None;
}

"""Cross-process-safe JSON object store used by all auth providers."""
class AuthProfileStore {
    has path: any,
        lock_path: any;

    def init(path: str | Path);

    def transaction(
        *, lock_timeout: float | None = None, before_commit: Callable[[], None] | None = None
    ) -> AuthProfileTransaction;

    def read_profile -> dict[str, Any];

    def read_slot(slot: str) -> dict[str, Any] | None;

    def update_slot(
        slot: str,
        payload: dict[str, Any],
        *,
        lock_timeout: float | None = None,
        before_commit: Callable[[], None] | None = None,
    ) -> None;

    def update_profile(updater: Callable[[dict[str, Any]], _T]) -> _T;

    def _read_unlocked -> dict[str, Any];

    def _write_unlocked(
        profile: dict[str, Any], *, before_commit: Callable[[], None] | None = None
    ) -> None;
}
