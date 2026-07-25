SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PYTHON      ?= python3
IVERILOG    ?= iverilog
VVP         ?= vvp
VERILATOR   ?= verilator
YOSYS       ?= yosys
PDK         ?= ihp-sg13g2
PDK_ROOT    ?= $(MAKEFILE_DIR)/IHP-Open-PDK
PDK_COMMIT  ?= 3b5a704ba6738aa686b08706187830e6284d2a10
RUN_TAG     ?= baseline
CONFIG      ?= config.yaml
RUN_DIR     ?= runs/$(RUN_TAG)

export PDK PDK_ROOT

.PHONY: help env clone-pdk validate lint sim synth flow synthesis-only floorplan placement cts routing density25 small-core clk25 bad-clock nodrc magic-drc klayout-drc inspect errors metrics compare reproduce open-klayout open-openroad clean distclean

help:
	@printf '%s\n' \
	  'Lab 11 - Controlling and Debugging LibreLane (IHP SG13G2)' \
	  '' \
	  'Setup and RTL:' \
	  '  make env                    Check tools and paths' \
	  '  make clone-pdk              Install pinned ihp-sg13g2 PDK with ciel' \
	  '  make validate               Validate all YAML files and RTL paths' \
	  '  make lint                   Verilator lint' \
	  '  make sim                    Self-checking RTL simulation' \
	  '  make synth                  Standalone generic Yosys synthesis' \
	  '' \
	  'LibreLane control:' \
	  '  make flow RUN_TAG=baseline Complete Classic flow' \
	  '  make synthesis-only        Stop after Yosys.Synthesis' \
	  '  make floorplan             Stop after OpenROAD.Floorplan' \
	  '  make placement             Stop after detailed placement' \
	  '  make cts                   Stop after OpenROAD.CTS' \
	  '  make routing               Stop after detailed routing' \
	  '' \
	  'Experiments and checks:' \
	  '  make density25             Placement-density experiment' \
	  '  make small-core            Smaller floorplan experiment' \
	  '  make clk25                 25 ns timing experiment' \
	  '  make bad-clock             Intentional failure exercise' \
	  '  make nodrc                 Skip DRC/density/antenna checks' \
	  '  make magic-drc             Keep Magic DRC; skip KLayout DRC' \
	  '  make klayout-drc           Keep KLayout DRC; skip Magic DRC' \
	  '' \
	  'Debug:' \
	  '  make inspect RUN_TAG=name' \
	  '  make errors RUN_TAG=name' \
	  '  make metrics RUN_TAG=name' \
	  '  make compare A=baseline B=density25' \
	  '  make reproduce RUN_TAG=name' \
	  '  make open-klayout RUN_TAG=name' \
	  '  make open-openroad RUN_TAG=name'

env:
	@./scripts/check_env.sh

$(PDK_ROOT)/$(PDK):
	@command -v ciel >/dev/null || { echo 'ERROR: ciel not found. Enter LibreLane Nix shell.'; exit 127; }
	ciel enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK)

clone-pdk: $(PDK_ROOT)/$(PDK)

validate:
	@$(PYTHON) scripts/validate_project.py config.yaml configs/*.yaml
	@grep -RInP '\t' --include='*.yaml' . && { echo 'ERROR: tab found in YAML'; exit 1; } || true

lint:
	@command -v $(VERILATOR) >/dev/null || { echo 'ERROR: verilator not found'; exit 127; }
	$(VERILATOR) --lint-only --Wall -Wno-fatal --top-module counter src/counter.sv

sim:
	@command -v $(IVERILOG) >/dev/null || { echo 'ERROR: iverilog not found'; exit 127; }
	@mkdir -p build
	$(IVERILOG) -g2012 -Wall -s tb_counter -o build/tb_counter.vvp src/counter.sv tb/tb_counter.sv
	$(VVP) build/tb_counter.vvp

synth:
	@command -v $(YOSYS) >/dev/null || { echo 'ERROR: yosys not found'; exit 127; }
	@mkdir -p build
	$(YOSYS) -ql build/yosys.log -p 'read_verilog -sv src/counter.sv; hierarchy -check -top counter; proc; opt; check; synth -top counter; stat; write_verilog -noattr build/counter_synth.v'
	@tail -n 35 build/yosys.log

flow: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh $(CONFIG) $(RUN_TAG)

synthesis-only: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml synthesis_only --to Yosys.Synthesis

floorplan: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh configs/config_floorplan.yaml floorplan --to OpenROAD.Floorplan

placement: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml placement --to OpenROAD.DetailedPlacement

cts: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml cts --to OpenROAD.CTS

routing: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml routing --to OpenROAD.DetailedRouting

density25: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh configs/config_density25.yaml density25

small-core: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh configs/config_small_core.yaml small_core

clk25: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh configs/config_clk25.yaml clk25

bad-clock: validate $(PDK_ROOT)/$(PDK)
	@echo 'Expected failure: CLOCK_PORT does not exist in RTL.'
	@./scripts/run_flow.sh configs/config_bad_clock.yaml bad_clock

nodrc: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml nodrc --skip KLayout.DRC --skip Magic.DRC --skip KLayout.Antenna --skip KLayout.Density

magic-drc: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml magic_drc --skip KLayout.DRC

klayout-drc: validate $(PDK_ROOT)/$(PDK)
	@./scripts/run_flow.sh config.yaml klayout_drc --skip Magic.DRC

inspect:
	@./scripts/inspect_run.sh $(RUN_DIR)

errors:
	@./scripts/find_errors.sh $(RUN_DIR)

metrics:
	@test -f $(RUN_DIR)/resolved.json || { echo 'ERROR: resolved.json not found'; exit 2; }
	@$(PYTHON) scripts/summarize_resolved.py $(RUN_DIR)/resolved.json
	@if [[ -f $(RUN_DIR)/final/metrics.csv ]]; then grep -iE 'area|utilization|density|wns|tns|drc|lvs|antenna|wire|via|power|clock|skew' $(RUN_DIR)/final/metrics.csv || true; fi

compare:
	@test -n "$(A)" -a -n "$(B)" || { echo 'Usage: make compare A=baseline B=density25'; exit 2; }
	@$(PYTHON) scripts/compare_metrics.py runs/$(A)/final/metrics.json runs/$(B)/final/metrics.json

reproduce: $(PDK_ROOT)/$(PDK)
	@test -f $(RUN_DIR)/resolved.json || { echo 'ERROR: resolved.json not found'; exit 2; }
	@./scripts/run_flow.sh $(RUN_DIR)/resolved.json reproduce_$(RUN_TAG)

open-klayout: $(PDK_ROOT)/$(PDK)
	librelane config.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --last-run --flow OpenInKLayout

open-openroad: $(PDK_ROOT)/$(PDK)
	librelane config.yaml --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --last-run --flow OpenInOpenROAD

clean:
	rm -rf build/* logs/*.log

distclean: clean
	find runs -mindepth 1 ! -name .gitkeep -exec rm -rf {} +
