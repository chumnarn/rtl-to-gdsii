#!/usr/bin/env bash

export LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PDK_ROOT="${PDK_ROOT:-${HOME}/.ciel}"
export PDK="${PDK:-gf180mcuD}"
export SCL="${SCL:-gf180mcu_fd_sc_mcu7t5v0}"
export PDK_REVISION="${PDK_REVISION:-}"

echo "LAB_ROOT=${LAB_ROOT}"
echo "PDK_ROOT=${PDK_ROOT}"
echo "PDK=${PDK}"
echo "SCL=${SCL}"
echo "PDK_REVISION=${PDK_REVISION:-<default>}"
