import from __future__ { annotations }

import from dataclasses { dataclass }

import from typing { Sequence }

import click;

@dataclass(frozen=True)
class SelectChoice {
    has value: str;

    has label: str;

    has hint: str | None = None;
}

def _import_inquirer_select -> any;

def select_prompt(
    message: str, choices: Sequence[SelectChoice], *, `default: str | None = None
) -> str;

def text_prompt(message: str, *, `default: str | None = None, secret: bool = False) -> str;
