SHELL := /usr/bin/env bash

PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp
PDK ?= ihp-sg13g2
TAG ?= lab14_ihp_full

export PDK

.PHONY: help
help:
	@echo "Lab 14 - LibreLane Python API / IHP SG13G2"
	@echo
	@echo "make check       Check LibreLane/Python environment"
	@echo "make sim         Run RTL self-checking simulation"
	@echo "make flows       List registered flows"
	@echo "make steps       List Classic and registered steps"
	@echo "make validate    Resolve and validate config.yaml"
	@echo "make synth       Run from start through synthesis"
	@echo "make run         Run the complete Classic Flow"
	@echo "make state       Run and export final State/metrics"
	@echo "make sweep       Run 3 placement-density experiments"
	@echo "make custom      Run a custom synthesis-only flow"
	@echo "make compare     Inspect exported State JSON files"
	@echo "make gui         Open the last run with OpenROAD GUI"
	@echo "make klayout     Open final GDS using KLayout"
	@echo "make tree        Show generated run files"
	@echo "make clean       Remove generated results"

.PHONY: check
check:
	$(PYTHON) scripts/01_check_environment.py

.PHONY: sim
sim:
	mkdir -p reports
	$(IVERILOG) -g2012 -Wall \
		-s tb_counter \
		-o reports/tb_counter.vvp \
		rtl/counter.sv tb/tb_counter.sv
	$(VVP) reports/tb_counter.vvp

.PHONY: flows
flows:
	$(PYTHON) scripts/02_show_flows.py

.PHONY: steps
steps:
	$(PYTHON) scripts/03_show_steps.py | tee reports/steps.txt

.PHONY: validate
validate:
	$(PYTHON) scripts/04_validate_config.py

.PHONY: synth
synth:
	$(PYTHON) scripts/06_run_to_synthesis.py

.PHONY: run
run:
	$(PYTHON) scripts/05_run_classic.py --tag "$(TAG)"

.PHONY: state
state:
	$(PYTHON) scripts/07_export_state.py

.PHONY: sweep
sweep:
	$(PYTHON) scripts/08_parameter_sweep.py

.PHONY: custom
custom:
	$(PYTHON) scripts/09_custom_synthesis_flow.py

.PHONY: compare
compare:
	$(PYTHON) scripts/10_compare_exported_states.py | tee reports/state_comparison.txt

.PHONY: gui
gui:
	librelane --pdk "$(PDK)" --last-run --flow OpenInOpenROAD config.yaml

.PHONY: klayout
klayout:
	@GDS="$$(find runs -type f -path '*/final/*' -name '*.gds' | sort | tail -1)"; \
	if [[ -z "$$GDS" ]]; then \
		echo "No final GDS found. Run 'make run' first."; exit 1; \
	fi; \
	echo "Opening $$GDS"; \
	klayout "$$GDS"

.PHONY: tree
tree:
	find runs -maxdepth 3 -type f 2>/dev/null | sort | head -200

.PHONY: clean
clean:
	rm -rf runs
	rm -f reports/*.vvp reports/*.vcd reports/*.txt reports/*.json reports/*.csv
