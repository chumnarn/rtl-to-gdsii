SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PYTHON      ?= python3
IVERILOG    ?= iverilog
VVP         ?= vvp
VERILATOR   ?= verilator
YOSYS       ?= yosys
PDK         ?= sky130A
SCL         ?= sky130_fd_sc_hd
RUN_TAG     ?= baseline
CONFIG      ?= config.yaml
RUN_DIR     ?= runs/$(RUN_TAG)

.PHONY: help env validate lint sim synth flow floorplan density40 util30 clk25 bad-clock inspect errors metrics reproduce open-klayout open-openroad clean distclean

help:
	@printf '%s\n' \
	  'Lab 11 - Controlling and Debugging the LibreLane Flow' \
	  '' \
	  'Local RTL targets:' \
	  '  make env                     Check installed tools' \
	  '  make validate                Validate YAML and RTL paths' \
	  '  make lint                    Verilator lint' \
	  '  make sim                     Self-checking Icarus simulation' \
	  '  make synth                   Standalone Yosys synthesis/check' \
	  '' \
	  'LibreLane targets:' \
	  '  make flow RUN_TAG=baseline  Run complete Classic flow' \
	  '  make floorplan              Stop after OpenROAD.Floorplan' \
	  '  make density40              Experiment: placement density 40%' \
	  '  make util30                 Experiment: floorplan utilization 30%' \
	  '  make clk25                  Experiment: 25 ns clock' \
	  '  make bad-clock              Intentional clock-port failure' \
	  '' \
	  'Debug/report targets:' \
	  '  make inspect RUN_TAG=name   Inspect a run directory' \
	  '  make errors RUN_TAG=name    Search logs and reports' \
	  '  make metrics RUN_TAG=name   Summarize resolved config and metrics' \
	  '  make reproduce RUN_TAG=name Re-run from resolved.json' \
	  '  make open-klayout RUN_TAG=name' \
	  '  make open-openroad RUN_TAG=name' \
	  '' \
	  'Overrides: PDK=sky130A SCL=sky130_fd_sc_hd CONFIG=config.yaml'

env:
	@./scripts/check_env.sh

validate:
	@$(PYTHON) scripts/validate_project.py \
	  config.yaml \
	  configs/config_floorplan.yaml \
	  configs/config_density40.yaml \
	  configs/config_util30.yaml \
	  configs/config_clk25.yaml \
	  configs/config_bad_clock.yaml

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
	@tail -n 30 build/yosys.log

flow: validate
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh $(CONFIG) $(RUN_TAG)

floorplan: validate
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh configs/config_floorplan.yaml floorplan --to OpenROAD.Floorplan

density40: validate
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh configs/config_density40.yaml density40

util30: validate
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh configs/config_util30.yaml util30

clk25: validate
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh configs/config_clk25.yaml clk25

bad-clock: validate
	@echo 'This target is expected to fail for debugging practice.'
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh configs/config_bad_clock.yaml bad_clock

inspect:
	@./scripts/inspect_run.sh $(RUN_DIR)

errors:
	@./scripts/find_errors.sh $(RUN_DIR)

metrics:
	@test -f $(RUN_DIR)/resolved.json || { echo 'resolved.json not found'; exit 2; }
	@$(PYTHON) scripts/summarize_resolved.py $(RUN_DIR)/resolved.json
	@echo
	@if [[ -f $(RUN_DIR)/final/metrics.csv ]]; then \
	  grep -iE 'area|utilization|density|wns|tns|drc|lvs|antenna|wire|via|power|clock|skew' $(RUN_DIR)/final/metrics.csv || true; \
	else echo 'final/metrics.csv not found'; fi

reproduce:
	@test -f $(RUN_DIR)/resolved.json || { echo 'resolved.json not found'; exit 2; }
	@PDK=$(PDK) SCL=$(SCL) ./scripts/run_flow.sh $(RUN_DIR)/resolved.json reproduce_$(RUN_TAG)

open-klayout:
	@test -f $(RUN_DIR)/resolved.json || { echo 'resolved.json not found'; exit 2; }
	librelane --run-tag view_klayout_$(RUN_TAG) --flow OpenInKLayout $(RUN_DIR)/resolved.json

open-openroad:
	@test -f $(RUN_DIR)/resolved.json || { echo 'resolved.json not found'; exit 2; }
	librelane --run-tag view_openroad_$(RUN_TAG) --flow OpenInOpenROAD $(RUN_DIR)/resolved.json

clean:
	rm -rf build logs/*.log

distclean: clean
	rm -rf runs/*
