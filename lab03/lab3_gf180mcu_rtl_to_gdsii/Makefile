SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

TOP      ?= counter
PDK      ?= gf180mcuD
FLOW     ?= Classic
JOBS     ?= 1
RUN_TAG  ?=

RTL      := rtl/counter.sv
TB       := tb/tb_counter.sv
SIM_EXE  := build/tb_counter.vvp

.PHONY: help tools preflight check-config lint sim synth all pnr reports openroad klayout clean clean-runs

help:
	@printf '%s\n' \
	  'Lab 3 - GF180MCU RTL-to-GDSII' \
	  '' \
	  'make tools       Show tool versions' \
	  'make preflight   Check configuration and LibreLane' \
	  'make lint        Run Verilator lint' \
	  'make sim         Run self-checking simulation' \
	  'make synth       Run generic Yosys synthesis' \
	  'make all         Run lint, simulation, and synthesis' \
	  'make pnr         Run LibreLane Classic flow' \
	  'make reports     Locate final files and metrics' \
	  'make openroad    Open the latest run in OpenROAD' \
	  'make klayout     Open the latest run in KLayout' \
	  '' \
	  'Default PDK: gf180mcuD. Override with PDK=<installed-name>.'

tools:
	@for tool in librelane verilator iverilog vvp yosys openroad klayout; do \
	  if command -v $$tool >/dev/null 2>&1; then \
	    printf '%-12s ' $$tool; $$tool --version 2>/dev/null | head -1 || true; \
	  else printf '%-12s %s\n' $$tool 'NOT FOUND'; fi; \
	done

preflight check-config:
	@PDK=$(PDK) scripts/preflight.sh

lint:
	@mkdir -p build
	verilator --lint-only --Wall --Wno-fatal --sv --top-module $(TOP) $(RTL)

$(SIM_EXE): $(RTL) $(TB)
	@mkdir -p build waves
	iverilog -g2012 -Wall -s tb_counter -o $@ $(RTL) $(TB)

sim: $(SIM_EXE)
	vvp $(SIM_EXE)

synth:
	@mkdir -p build
	yosys -s scripts/synth.ys | tee build/yosys.log

all: lint sim synth

pnr: preflight
	librelane -j $(JOBS) --pdk $(PDK) --flow $(FLOW) $(if $(RUN_TAG),--run-tag $(RUN_TAG),) config.yaml

reports:
	python3 scripts/check_results.py

openroad:
	librelane --pdk $(PDK) --last-run --flow OpenInOpenROAD config.yaml

klayout:
	librelane --pdk $(PDK) --last-run --flow OpenInKLayout config.yaml

clean:
	rm -rf build/* waves/*

clean-runs:
	rm -rf runs
