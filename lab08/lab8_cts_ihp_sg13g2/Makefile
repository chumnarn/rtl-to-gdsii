SHELL := /usr/bin/env bash

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

TOP        := cts_demo
RTL        := src/cts_demo.sv
TB         := tb/tb_cts_demo.sv
BUILD      := build

PDK        ?= ihp-sg13g2
PDK_ROOT   ?= $(MAKEFILE_DIR)/IHP-Open-PDK
# Commit pinned by the official IHP LibreLane template.
PDK_COMMIT ?= 3b5a704ba6738aa686b08706187830e6284d2a10

CONFIG     ?= config.yaml

.PHONY: help check pdk pdk-info lint sim synth config-check \
        run run-baseline openroad klayout summary artifacts \
        clock-cells clean clean-runs

help:
	@echo "Lab 8 Clock Tree Synthesis — IHP SG13G2"
	@echo
	@echo "make check          Check tools"
	@echo "make pdk            Install pinned ihp-sg13g2 PDK with ciel"
	@echo "make pdk-info       Show PDK installation information"
	@echo "make lint           Run Verilator lint"
	@echo "make sim            Run self-checking RTL simulation"
	@echo "make synth          Run generic Yosys synthesis/check"
	@echo "make config-check   Validate config.yaml"
	@echo "make run            Run LibreLane Classic flow"
	@echo "make run-baseline   Run conservative baseline config"
	@echo "make summary        Summarize latest run"
	@echo "make artifacts      List CTS artifacts"
	@echo "make clock-cells    List installed SG13G2 clock buffers"
	@echo "make openroad       Open latest run in OpenROAD GUI"
	@echo "make klayout        Open latest run in KLayout"
	@echo "make clean          Remove local RTL build products"
	@echo "make clean-runs     Remove runs/ and final/"

check:
	@scripts/check_tools.sh

$(PDK_ROOT)/$(PDK):
	@command -v ciel >/dev/null 2>&1 || { \
	  echo "ERROR: ciel not found. Enter the LibreLane Nix environment first."; \
	  exit 1; \
	}
	ciel enable $(PDK_COMMIT) \
	  --pdk-root $(PDK_ROOT) \
	  --pdk-family $(PDK)

pdk: $(PDK_ROOT)/$(PDK)

pdk-info: pdk
	@echo "PDK       : $(PDK)"
	@echo "PDK_ROOT  : $(PDK_ROOT)"
	@echo "PDK_COMMIT: $(PDK_COMMIT)"
	@find "$(PDK_ROOT)/$(PDK)" -maxdepth 2 -type d | head -30

lint:
	@command -v verilator >/dev/null 2>&1 || { echo "ERROR: verilator not found"; exit 1; }
	@mkdir -p $(BUILD)
	verilator --lint-only --Wall -Wno-fatal --top-module $(TOP) $(RTL)

sim:
	@command -v iverilog >/dev/null 2>&1 || { echo "ERROR: iverilog not found"; exit 1; }
	@command -v vvp >/dev/null 2>&1 || { echo "ERROR: vvp not found"; exit 1; }
	@mkdir -p $(BUILD)
	iverilog -g2012 -Wall -s tb_cts_demo \
	  -o $(BUILD)/tb_cts_demo.vvp $(RTL) $(TB)
	vvp $(BUILD)/tb_cts_demo.vvp

synth:
	@command -v yosys >/dev/null 2>&1 || { echo "ERROR: yosys not found"; exit 1; }
	@mkdir -p $(BUILD)
	yosys -ql $(BUILD)/yosys.log -p \
	  'read_verilog -sv $(RTL); hierarchy -check -top $(TOP); proc; opt; check; stat'

config-check:
	@python3 -c 'import yaml, pathlib; p=pathlib.Path("$(CONFIG)"); d=yaml.safe_load(p.read_text()); assert d["DESIGN_NAME"]=="$(TOP)"; assert d["CLOCK_PORT"]=="clk_i"; print("PASS:", p, "flow =", d["meta"]["flow"], "design =", d["DESIGN_NAME"])'

run: pdk config-check
	@command -v librelane >/dev/null 2>&1 || { \
	  echo "ERROR: librelane not found. Enter the LibreLane environment first."; \
	  exit 1; \
	}
	librelane $(CONFIG) \
	  --pdk $(PDK) \
	  --pdk-root $(PDK_ROOT) \
	  --manual-pdk \
	  --save-views-to final/

run-baseline:
	@$(MAKE) run CONFIG=config_baseline.yaml

openroad: pdk
	librelane $(CONFIG) \
	  --pdk $(PDK) \
	  --pdk-root $(PDK_ROOT) \
	  --manual-pdk \
	  --last-run \
	  --flow OpenInOpenROAD

klayout: pdk
	librelane $(CONFIG) \
	  --pdk $(PDK) \
	  --pdk-root $(PDK_ROOT) \
	  --manual-pdk \
	  --last-run \
	  --flow OpenInKLayout

summary:
	@scripts/cts_summary.sh

artifacts:
	@scripts/list_cts_artifacts.sh

clock-cells: pdk
	@PDK_ROOT="$(PDK_ROOT)" PDK="$(PDK)" scripts/list_clock_cells.sh

clean:
	rm -rf $(BUILD)

clean-runs:
	rm -rf runs final
