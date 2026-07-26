SHELL := /usr/bin/env bash

TOP       := lab4_counter
CONFIG    ?= config.yaml
PDK       ?= sky130A
BUILD_DIR := build
REPORT_DIR := reports
RTL       := rtl/lab4_counter.sv
TB        := tb/tb_lab4_counter.sv

.PHONY: help check lint sim synth run experiments summary clean

help:
	@echo "Lab 4 targets:"
	@echo "  make check                 Validate config.yaml and paths"
	@echo "  make lint                  Run Verilator lint"
	@echo "  make sim                   Run self-checking RTL simulation"
	@echo "  make synth                 Run generic Yosys synthesis"
	@echo "  make run PDK=sky130A       Run LibreLane using config.yaml"
	@echo "  make experiments           Generate and run experiment YAML files"
	@echo "  make summary               Create reports/run_summary.csv"
	@echo "  make clean                 Remove local build products"

check:
	python3 scripts/check_config.py

lint:
	@command -v verilator >/dev/null || { echo "ERROR: verilator not found"; exit 1; }
	verilator --lint-only --Wall -Wno-fatal --top-module $(TOP) $(RTL)

sim:
	@mkdir -p $(BUILD_DIR) $(REPORT_DIR)
	@if command -v verilator >/dev/null; then \
		verilator --binary --timing --trace --Wall -Wno-fatal \
			--Mdir $(BUILD_DIR)/obj_dir --top-module tb_lab4_counter \
			$(RTL) $(TB); \
		./$(BUILD_DIR)/obj_dir/Vtb_lab4_counter; \
	elif command -v iverilog >/dev/null; then \
		iverilog -g2012 -s tb_lab4_counter -o $(BUILD_DIR)/tb_lab4_counter.vvp $(RTL) $(TB); \
		vvp $(BUILD_DIR)/tb_lab4_counter.vvp; \
	else \
		echo "ERROR: install Verilator or Icarus Verilog"; exit 1; \
	fi

synth:
	@command -v yosys >/dev/null || { echo "ERROR: yosys not found"; exit 1; }
	@mkdir -p $(BUILD_DIR) $(REPORT_DIR)
	yosys -p 'read_verilog -sv $(RTL); hierarchy -check -top $(TOP); proc; opt; check; stat; write_json $(BUILD_DIR)/$(TOP).json' \
		2>&1 | tee $(REPORT_DIR)/yosys_synthesis.log

run: check
	@command -v librelane >/dev/null || { echo "ERROR: librelane not found"; exit 1; }
	librelane --pdk $(PDK) $(CONFIG)

experiments:
	PDK=$(PDK) scripts/run_experiments.sh

summary:
	python3 scripts/summarize_runs.py

clean:
	rm -rf $(BUILD_DIR) $(REPORT_DIR)/*.vcd $(REPORT_DIR)/*.log $(REPORT_DIR)/run_summary.csv
