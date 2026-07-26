#!/usr/bin/env python3
"""Generate YAML experiment files from config.yaml without changing the baseline."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit("PyYAML is required: python3 -m pip install pyyaml") from exc

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "experiments"


def write(name: str, cfg: dict) -> None:
    path = OUT / name
    with path.open("w", encoding="utf-8") as stream:
        yaml.safe_dump(cfg, stream, sort_keys=False)
    print(path.relative_to(ROOT))


def main() -> None:
    OUT.mkdir(exist_ok=True)
    with (ROOT / "config.yaml").open("r", encoding="utf-8") as stream:
        base = yaml.safe_load(stream)

    for density in (40, 50, 60, 70):
        cfg = deepcopy(base)
        cfg["PL_TARGET_DENSITY_PCT"] = density
        write(f"config_density_{density}.yaml", cfg)

    for side in (100, 110, 120, 130):
        cfg = deepcopy(base)
        cfg["FP_SIZING"] = "absolute"
        cfg.pop("FP_CORE_UTIL", None)
        cfg["DIE_AREA"] = [0, 0, side, side]
        cfg["PL_TARGET_DENSITY_PCT"] = 50
        write(f"config_die_{side}.yaml", cfg)

    cfg = deepcopy(base)
    cfg["FP_SIZING"] = "absolute"
    cfg.pop("FP_CORE_UTIL", None)
    cfg["DIE_AREA"] = [0, 0, 120, 120]
    cfg["FP_OBSTRUCTIONS"] = [[25, 25, 35, 35], [75, 75, 90, 90]]
    cfg["PL_SOFT_OBSTRUCTIONS"] = [[45, 45, 60, 60]]
    write("config_obstructions.yaml", cfg)


if __name__ == "__main__":
    main()
