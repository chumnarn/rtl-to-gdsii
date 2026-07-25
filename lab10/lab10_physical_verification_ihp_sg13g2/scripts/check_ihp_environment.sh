#!/usr/bin/env bash
set -euo pipefail

PDK="${PDK:-ihp-sg13g2}"

echo "Checking Lab 10 IHP SG13G2 environment..."
echo

for tool in librelane python3; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "ERROR: ${tool} was not found in PATH." >&2
        exit 127
    fi
    printf "%-18s %s\n" "${tool}" "$(command -v "${tool}")"
done

echo
echo "LibreLane version:"
librelane --version || true

echo
echo "Checking whether the requested PDK can be resolved:"
# --help/config validation behavior differs among LibreLane releases.
# A dry configuration load is attempted when supported; otherwise the
# normal run command remains the authoritative check.
if librelane --pdk "${PDK}" --help >/dev/null 2>&1; then
    echo "PASS: LibreLane accepted the PDK option '${PDK}'."
else
    echo "WARNING: Could not validate '${PDK}' through --help."
    echo "Run 'make run' inside the LibreLane environment to confirm installation."
fi

if [[ -n "${PDK_ROOT:-}" ]]; then
    echo
    echo "PDK_ROOT=${PDK_ROOT}"
    if [[ -d "${PDK_ROOT}/${PDK}" ]]; then
        echo "PASS: ${PDK_ROOT}/${PDK} exists."
    else
        echo "NOTE: ${PDK_ROOT}/${PDK} was not found."
        echo "LibreLane may be using its Nix-managed PDK instead."
    fi
fi
