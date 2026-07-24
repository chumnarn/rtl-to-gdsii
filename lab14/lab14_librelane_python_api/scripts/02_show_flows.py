#!/usr/bin/env python3
from librelane.flows import Flow


def main() -> None:
    print("Registered LibreLane flows")
    print("=" * 80)
    for index, name in enumerate(sorted(Flow.factory.list()), start=1):
        flow_class = Flow.factory.get(name)
        qualified = (
            f"{flow_class.__module__}.{flow_class.__name__}"
            if flow_class is not None
            else "<unresolved>"
        )
        print(f"{index:3d}. {name:<32} {qualified}")


if __name__ == "__main__":
    main()
