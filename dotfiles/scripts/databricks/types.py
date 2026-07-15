"""Shared types for PR nit checkers."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any


@dataclass(frozen=True)
class Finding:
    rule: str
    file: str
    line: int | None
    severity: str
    message: str
    module: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
