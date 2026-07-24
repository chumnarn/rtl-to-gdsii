#!/usr/bin/env python3
from librelane.steps import Step

from common import classic_step_ids


def main() -> None:
    print("Classic Flow sequence")
    print("=" * 96)
    for index, identifier in enumerate(classic_step_ids(), start=1):
        print(f"{index:3d}. {identifier}")

    print()
    print("All registered LibreLane steps")
    print("=" * 96)
    for index, name in enumerate(sorted(Step.factory.list()), start=1):
        step_class = Step.factory.get(name)
        qualified = (
            f"{step_class.__module__}.{step_class.__name__}"
            if step_class is not None
            else "<unresolved>"
        )
        print(f"{index:3d}. {name:<48} {qualified}")


if __name__ == "__main__":
    main()
