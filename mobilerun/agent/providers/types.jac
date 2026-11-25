import builtins;

import from __future__ { annotations }

import from dataclasses { dataclass, field }

"""Internal provider runtime variant for a user-facing provider family."""
@dataclass(frozen=True)
class ProviderVariantSpec {
    has id: str;

    has runtime_provider_name: str;

    has auth_mode: str;

    has default_model: str | None;

    has models: tuple[str, ...];

    has requires_api_key: bool = False;

    has requires_base_url: bool = False;

    has credential_path: str | None = None;

    has runtime_transport_provider_name: str | None = None;

    has base_url: str | None = None;
}

"""User-facing provider family shown during setup."""
@dataclass(frozen=True)
class ProviderFamilySpec {
    has id: str;

    has display_name: str;

    has variants: tuple[ProviderVariantSpec, ...];

    has notes: tuple[str, ...] = field(default_factory=builtins.tuple);
}
