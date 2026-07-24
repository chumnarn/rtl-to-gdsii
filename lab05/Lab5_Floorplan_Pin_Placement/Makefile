SHELL := /bin/bash

TOP        ?= floorplan_demo
PDK        ?= ihp-sg13g2
CONFIG     ?= config.yaml
TAG        ?= lab5_ihp
LIBRELANE  ?= librelane
VERILATOR  ?= verilator
IVERILOG   ?= iverilog
VVP        ?= vvp
PYTHON     ?= python3

RTL := src/floorplan_demo.sv
TB  := tb/tb_floorplan_demo.sv

.PHONY: help check-tools check config-check lint sim sim-verilator pins \
        synthesis floorplan gui run results clean

help:
	@echo "Lab 5 - Floorplan and Pin Placement / IHP SG13G2"
	@echo
	@echo "make check-tools    Check commands and PDK environment"
	@echo "make check          Run config, pin, lint and RTL simulation checks"
	@echo "make lint           Run Verilator lint"
	@echo "make sim            Run self-checking simulation with Icarus Verilog"
	@echo "make sim-verilator  Run self-checking simulation with Verilator"
	@echo "make synthesis      Run LibreLane through Yosys synthesis"
	@echo "make floorplan      Run through Odb.CustomIOPlacement"
	@echo "make gui            Open the floorplan run in OpenROAD GUI"
	@echo "make run            Run complete Classic RTL-to-GDSII flow"
	@echo "make results        List artifacts from newest run"
	@echo "make clean          Delete generated build and run directories"
	@echo
	@echo "Defaults: PDK=$(PDK) CONFIG=$(CONFIG) TAG=$(TAG)"
	@echo "For Docker installations append LL_FLAGS=--dockerized"

check-tools:
	@command -v $(PYTHON) >/dev/null || { echo "ERROR: python3 not found"; exit 1; }
	@command -v $(LIBRELANE) >/dev/null || { echo "ERROR: librelane not found"; exit 1; }
	@command -v $(VERILATOR) >/dev/null || echo "WARNING: verilator not found"
	@command -v $(IVERILOG) >/dev/null || echo "WARNING: iverilog not found"
	@echo "PDK_ROOT=$${PDK_ROOT:-<not exported>}"
	@echo "PASS: basic environment check completed."

config-check:
	$(PYTHON) scripts/check_config.py

pins:
	$(PYTHON) scripts/check_pin_order.py

lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal \
		--top-module $(TOP) $(RTL)

sim:
	@mkdir -p build
	$(IVERILOG) -g2012 -Wall \
		-s tb_floorplan_demo \
		-o build/tb_floorplan_demo.vvp \
		$(RTL) $(TB)
	$(VVP) build/tb_floorplan_demo.vvp

sim-verilator:
	@mkdir -p build
	$(VERILATOR) --binary --timing --trace \
		-Wall -Wno-fatal \
		--top-module tb_floorplan_demo \
		-Mdir build/obj_dir \
		-o sim_lab5 \
		$(RTL) $(TB)
	./build/obj_dir/sim_lab5

check: config-check pins lint sim

synthesis: config-check pins
	$(LIBRELANE) $(LL_FLAGS) \
		--pdk $(PDK) \
		--run-tag $(TAG)_synthesis \
		--to Yosys.Synthesis \
		$(CONFIG)

floorplan: config-check pins lint
	$(LIBRELANE) $(LL_FLAGS) \
		--pdk $(PDK) \
		--run-tag $(TAG)_floorplan \
		--to Odb.CustomIOPlacement \
		$(CONFIG)

gui:
	$(LIBRELANE) $(LL_FLAGS) \
		--pdk $(PDK) \
		--run-tag $(TAG)_floorplan \
		--last-run \
		--flow OpenInOpenROAD \
		$(CONFIG)

run: config-check pins lint
	$(LIBRELANE) $(LL_FLAGS) \
		--pdk $(PDK) \
		--run-tag $(TAG)_full \
		$(CONFIG)

results:
	$(PYTHON) scripts/list_results.py

clean:
	rm -rf build runs
