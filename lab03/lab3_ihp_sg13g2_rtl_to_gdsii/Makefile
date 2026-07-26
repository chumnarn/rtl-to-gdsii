SHELL := /bin/bash
.DELETE_ON_ERROR:

TOP       := counter
RTL       := rtl/counter.sv
TB        := tb/tb_counter.sv
CONFIG    := config.yaml
PDK       ?= ihp-sg13g2
JOBS      ?= 1
BUILD_DIR := build
WAVE_DIR  := waves

.PHONY: help tools lint sim wave synth check-config pnr pnr-resume \
        reports openroad klayout clean clean-runs all

help:
	@echo "Lab 3 — IHP SG13G2 RTL-to-GDSII"
	@echo "  make tools        Check the environment"
	@echo "  make lint         Verilator lint"
	@echo "  make sim          Self-checking RTL simulation"
	@echo "  make wave         Open VCD in GTKWave"
	@echo "  make synth        Generic Yosys synthesis"
	@echo "  make check-config Validate LibreLane config without PnR"
	@echo "  make pnr          Run LibreLane Classic flow"
	@echo "  make pnr-resume   Resume the latest run"
	@echo "  make reports      Summarize final views and metrics"
	@echo "  make openroad     Open latest design in OpenROAD GUI"
	@echo "  make klayout      Open latest GDSII in KLayout"
	@echo "  make all          Run lint, simulation, synthesis"
	@echo "  make clean        Remove local RTL outputs"
	@echo "  make clean-runs   Delete all LibreLane runs"

$(BUILD_DIR) $(WAVE_DIR):
	@mkdir -p $@

tools:
	@./scripts/preflight.sh

lint:
	verilator --lint-only --Wall --Wno-fatal --sv \
		--top-module $(TOP) $(RTL)

sim: $(BUILD_DIR) $(WAVE_DIR)
	iverilog -g2012 -Wall -s tb_counter \
		-o $(BUILD_DIR)/tb_counter.vvp $(RTL) $(TB)
	vvp $(BUILD_DIR)/tb_counter.vvp
	@test -s $(WAVE_DIR)/counter.vcd
	@echo "Waveform: $(WAVE_DIR)/counter.vcd"

wave: sim
	@command -v gtkwave >/dev/null || { echo "GTKWave is not installed"; exit 1; }
	gtkwave $(WAVE_DIR)/counter.vcd

synth: $(BUILD_DIR)
	yosys -s scripts/synth.ys | tee $(BUILD_DIR)/yosys.log
	@test -s $(BUILD_DIR)/counter_generic_netlist.v
	@test -s $(BUILD_DIR)/counter_generic.json

check-config:
	librelane --pdk $(PDK) --flow Classic --only Verilator.Lint $(CONFIG)

pnr:
	librelane -j $(JOBS) --pdk $(PDK) --flow Classic $(CONFIG)

pnr-resume:
	librelane -j $(JOBS) --pdk $(PDK) --flow Classic --last-run $(CONFIG)

reports:
	python3 scripts/check_results.py

openroad:
	librelane --pdk $(PDK) --last-run --flow OpenInOpenROAD $(CONFIG)

klayout:
	librelane --pdk $(PDK) --last-run --flow OpenInKLayout $(CONFIG)

all: lint sim synth

clean:
	rm -rf $(BUILD_DIR) $(WAVE_DIR)
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)


clean-runs:
	rm -rf runs
