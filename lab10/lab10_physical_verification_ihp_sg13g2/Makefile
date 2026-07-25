SHELL := /usr/bin/env bash

PDK := ihp-sg13g2
CONFIG ?= config.yaml
RUNS_DIR ?= runs
BUILD_DIR ?= build
PYTHON ?= python3
VERILATOR ?= verilator

RTL := src/counter.sv
TB  := tb/tb_counter.sv

.PHONY: all help check env lint sim run reports pv-summary pv-check \
        open-gds final clean distclean

all: check lint sim

help:
	@echo "Lab 10 — Physical Verification: DRC and LVS"
	@echo "Target PDK: $(PDK)"
	@echo
	@echo "make check       Validate project files"
	@echo "make env         Check LibreLane/IHP environment"
	@echo "make lint        Run Verilator lint"
	@echo "make sim         Run self-checking simulation"
	@echo "make run         Run LibreLane using ihp-sg13g2"
	@echo "make reports     Locate PV reports and final views"
	@echo "make pv-summary  Summarize DRC, XOR and LVS"
	@echo "make pv-check    Return failure unless DRC=0 and LVS passes"
	@echo "make open-gds    Open latest final GDS in KLayout"
	@echo "make final       List final artifacts"
	@echo "make clean       Remove simulation output"
	@echo "make distclean   Remove simulation output and LibreLane runs"

check:
	$(PYTHON) scripts/check_project.py

env:
	PDK=$(PDK) bash scripts/check_ihp_environment.sh

lint:
	@command -v $(VERILATOR) >/dev/null || { \
		echo "ERROR: Verilator not found."; exit 127; }
	$(VERILATOR) --lint-only --Wall --Wno-fatal \
		--top-module counter $(RTL)

sim:
	@command -v $(VERILATOR) >/dev/null || { \
		echo "ERROR: Verilator not found."; exit 127; }
	mkdir -p $(BUILD_DIR)
	$(VERILATOR) --binary --timing --assert --trace \
		--Mdir $(BUILD_DIR)/obj_dir \
		-o sim_counter \
		--top-module tb_counter \
		$(RTL) $(TB)
	./$(BUILD_DIR)/obj_dir/sim_counter

run:
	@command -v librelane >/dev/null || { \
		echo "ERROR: LibreLane not found."; \
		echo "Enter the LibreLane Nix or supported container environment first."; \
		exit 127; }
	librelane --pdk $(PDK) $(CONFIG)

reports:
	bash scripts/find_reports.sh $(RUNS_DIR)

pv-summary:
	$(PYTHON) scripts/pv_summary.py --runs $(RUNS_DIR)

pv-check:
	$(PYTHON) scripts/pv_summary.py --runs $(RUNS_DIR) --strict

open-gds:
	@command -v klayout >/dev/null || { \
		echo "ERROR: KLayout not found."; exit 127; }
	@GDS="$$(find $(RUNS_DIR) -path '*/final/gds/*.gds' -type f \
		-printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)"; \
	if [[ -z "$$GDS" ]]; then \
		echo "ERROR: no final GDS found."; exit 1; \
	fi; \
	echo "Opening $$GDS"; \
	klayout "$$GDS"

final:
	@find $(RUNS_DIR) -path '*/final/*' -type f -print 2>/dev/null | sort || true

clean:
	rm -rf $(BUILD_DIR)

distclean: clean
	rm -rf $(RUNS_DIR)
