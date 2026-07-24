#!/usr/bin/env python3
"""Shared helpers for Lab 14 LibreLane Python API."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Iterable

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_FILE = PROJECT_ROOT / "config.yaml"
REPORTS_DIR = PROJECT_ROOT / "reports"
DEFAULT_PDK = os.environ.get("PDK", "ihp-sg13g2")


def ensure_project_layout() -> None:
    if not CONFIG_FILE.is_file():
        raise FileNotFoundError(f"Configuration not found: {CONFIG_FILE}")
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def get_flow_class(name: str = "Classic"):
    from librelane.flows import Flow

    flow_class = Flow.factory.get(name)
    if flow_class is None:
        available = ", ".join(sorted(Flow.factory.list()))
        raise RuntimeError(
            f"LibreLane flow '{name}' is unavailable. Available flows: {available}"
        )
    return flow_class


def make_flow(
    config_sources: Any = None,
    *,
    pdk: str | None = None,
):
    ensure_project_layout()
    flow_class = get_flow_class("Classic")
    sources = CONFIG_FILE if config_sources is None else config_sources
    return flow_class(
        sources,
        pdk=pdk or DEFAULT_PDK,
        design_dir=str(PROJECT_ROOT),
    )


def step_id(step_or_class: Any) -> str:
    value = getattr(step_or_class, "id", None)
    if value:
        return str(value)
    return step_or_class.__class__.__name__


def classic_step_ids() -> list[str]:
    flow_class = get_flow_class("Classic")
    return [str(getattr(step, "id", step.__name__)) for step in flow_class.Steps]


def resolve_step_id(
    preferred: str,
    *,
    contains: Iterable[str] = (),
) -> str:
    ids = classic_step_ids()
    if preferred in ids:
        return preferred

    words = [word.lower() for word in contains]
    matches = [
        identifier
        for identifier in ids
        if all(word in identifier.lower() for word in words)
    ]

    if len(matches) == 1:
        return matches[0]

    raise RuntimeError(
        f"Cannot resolve target step '{preferred}'. "
        f"Candidate matches={matches}. Run scripts/03_show_steps.py."
    )


def find_metric(metrics: Any, *keywords: str) -> Any:
    required = [keyword.lower() for keyword in keywords]
    for name, value in metrics.items():
        lowered = str(name).lower()
        if all(keyword in lowered for keyword in required):
            return value
    return None
