SHELL := /bin/bash

TOP       := counter
RTL       := rtl/counter.sv
TB        := tb/tb_counter.sv
CONFIG    := config.yaml
PDK       ?= ihp-sg13g2
BUILD_DIR := build
WAVE_DIR  := waves

.PHONY: all help tools lint sim synth pnr openroad klayout reports clean clean-runs

all: lint sim synth

help:
	@echo "Lab 3 targets"
	@echo "  make tools      Check required executables"
	@echo "  make lint       Verilator lint"
	@echo "  make sim        Icarus Verilog self-checking simulation"
	@echo "  make synth      Generic Yosys synthesis"
	@echo "  make pnr        LibreLane Classic RTL-to-GDSII flow"
	@echo "  make openroad   Open latest LibreLane run in OpenROAD GUI"
	@echo "  make klayout    Open latest LibreLane run in KLayout"
	@echo "  make reports    Locate final views and print selected metrics"
	@echo "  make clean      Remove local simulation/synthesis outputs"
	@echo "  make clean-runs Remove LibreLane run directories"
	@echo ""
	@echo "Override the PDK with: make pnr PDK=<pdk-name>"

$(BUILD_DIR) $(WAVE_DIR):
	@mkdir -p $@

tools:
	@set -e; \
	for tool in verilator iverilog vvp yosys python3 librelane; do \
		if command -v $$tool >/dev/null 2>&1; then \
			printf "[OK]   %-12s %s\n" $$tool "$$(command -v $$tool)"; \
		else \
			printf "[MISS] %-12s\n" $$tool; \
		fi; \
	done

lint:
	verilator --lint-only --Wall --Wno-fatal --sv --top-module $(TOP) $(RTL)

sim: $(BUILD_DIR) $(WAVE_DIR)
	iverilog -g2012 -Wall -s tb_counter -o $(BUILD_DIR)/tb_counter.vvp $(RTL) $(TB)
	vvp $(BUILD_DIR)/tb_counter.vvp
	@echo "Waveform: $(WAVE_DIR)/counter.vcd"

synth: $(BUILD_DIR)
	yosys -s scripts/synth.ys | tee $(BUILD_DIR)/yosys.log
	@test -s $(BUILD_DIR)/counter_generic_netlist.v
	@echo "Netlist: $(BUILD_DIR)/counter_generic_netlist.v"

pnr:
	librelane --pdk $(PDK) $(CONFIG)

openroad:
	librelane --pdk $(PDK) $(CONFIG) --last-run --flow OpenInOpenROAD

klayout:
	librelane --pdk $(PDK) $(CONFIG) --last-run --flow OpenInKLayout

reports:
	python3 scripts/check_results.py

clean:
	rm -rf $(BUILD_DIR) $(WAVE_DIR)
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)

clean-runs:
	rm -rf runs run
