SHELL := /bin/bash

PDK       ?= ihp-sg13g2
FLOW      ?= Classic
CONFIG    ?= config.yaml
RUN_TAG   ?= lab6_ihp
JOBS      ?= 1
BUILD_DIR ?= build

RTL       := src/synth_sta_top.sv
TB        := tb/tb_synth_sta_top.sv
SIM_BIN   := $(BUILD_DIR)/tb_synth_sta_top

.PHONY: help check tools lint sim wave sta sta-5ns run reports \
        list-steps openroad klayout clean distclean

help:
	@echo "Lab 6 - Synthesis and STA with IHP SG13G2"
	@echo
	@echo "make check       Validate project files and config.yaml"
	@echo "make tools       Display tool versions and PDK environment"
	@echo "make lint        Run Verilator lint"
	@echo "make sim         Run self-checking RTL simulation"
	@echo "make sta         Run LibreLane through OpenROAD.STAPrePNR"
	@echo "make sta-5ns     Run the 5 ns timing experiment"
	@echo "make run         Run the complete Classic flow"
	@echo "make reports     Generate reports/summary.md"
	@echo "make list-steps  Ask LibreLane to list Classic-flow steps"
	@echo "make clean       Remove local simulation output"
	@echo "make distclean   Remove simulation, reports, and LibreLane runs"
	@echo
	@echo "Override examples:"
	@echo "  make sta JOBS=4 RUN_TAG=lab6_try1"
	@echo "  make sta CONFIG=config_5ns.yaml RUN_TAG=lab6_5ns"
	@echo "  make run PDK=ihp-sg13g2"

check:
	python3 scripts/check_project.py

tools:
	@echo "PDK_ROOT=$${PDK_ROOT:-<not set>}"
	@echo "PDK=$(PDK)"
	@command -v librelane >/dev/null && librelane --version || \
		echo "ERROR: librelane is not available in PATH"
	@command -v verilator >/dev/null && verilator --version || \
		echo "WARNING: verilator is not available in PATH"
	@command -v iverilog >/dev/null && iverilog -V | head -1 || \
		echo "WARNING: iverilog is not available in PATH"
	@test -z "$${PDK_ROOT}" || \
		(test -d "$${PDK_ROOT}/$(PDK)" && \
		 echo "PASS: $${PDK_ROOT}/$(PDK) exists" || \
		 echo "WARNING: $${PDK_ROOT}/$(PDK) was not found")

lint:
	verilator --lint-only --Wall --Wno-fatal \
		--top-module synth_sta_top $(RTL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim: $(BUILD_DIR)
	iverilog -g2012 -Wall \
		-s tb_synth_sta_top \
		-o $(SIM_BIN) \
		$(RTL) $(TB)
	vvp $(SIM_BIN)

wave:
	gtkwave $(BUILD_DIR)/tb_synth_sta_top.vcd

sta:
	librelane -j $(JOBS) \
		--flow $(FLOW) \
		--pdk $(PDK) \
		--run-tag $(RUN_TAG) \
		--to OpenROAD.STAPrePNR \
		$(CONFIG)

sta-5ns:
	$(MAKE) sta CONFIG=config_5ns.yaml RUN_TAG=lab6_ihp_5ns

run:
	librelane -j $(JOBS) \
		--flow $(FLOW) \
		--pdk $(PDK) \
		--run-tag $(RUN_TAG) \
		$(CONFIG)

reports:
	python3 scripts/collect_results.py \
		--run-dir runs/$(RUN_TAG) \
		--output reports/$(RUN_TAG)_summary.md

list-steps:
	librelane --flow $(FLOW) --pdk $(PDK) --list-steps $(CONFIG)

openroad:
	@echo "Open the latest ODB using the OpenROAD GUI from the LibreLane environment."
	@find runs/$(RUN_TAG) -type f -name "*.odb" -print | tail -1

klayout:
	@echo "Open the final GDS using KLayout."
	@find runs/$(RUN_TAG) -type f -name "*.gds" -print | tail -1

clean:
	rm -rf $(BUILD_DIR)

distclean:
	rm -rf $(BUILD_DIR) reports/* runs/*
	mkdir -p reports runs
