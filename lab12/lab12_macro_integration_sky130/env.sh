#!/usr/bin/env bash

export LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PDK_ROOT="${PDK_ROOT:-${HOME}/.ciel}"
export PDK="${PDK:-sky130A}"
export SCL="${SCL:-sky130_fd_sc_hd}"

echo "LAB_ROOT=${LAB_ROOT}"
echo "PDK_ROOT=${PDK_ROOT}"
echo "PDK=${PDK}"
echo "SCL=${SCL}"
