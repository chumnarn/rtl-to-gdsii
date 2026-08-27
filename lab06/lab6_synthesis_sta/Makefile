SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

CONFIG  ?= config.yaml
PDK     ?= sky130A
FLOW    ?= Classic
RUN_TAG ?= lab6
JOBS    ?= 1
BUILD   := build
RTL     := src/synth_sta_top.sv
TB      := tb/tb_synth_sta_top.sv
TOP     := tb_synth_sta_top

.PHONY: help check lint sim sta synth-explore run reports clean distclean

help:
	@echo "Lab 6 — Synthesis and Static Timing Analysis"
	@echo ""
	@echo "make check          Validate files and config.yaml"
	@echo "make lint           Run Verilator RTL lint"
	@echo "make sim            Run self-checking RTL simulation"
	@echo "make sta            Run LibreLane through OpenROAD.STAPrePNR"
	@echo "make synth-explore  Compare all synthesis strategies"
	@echo "make run            Run the complete LibreLane Classic flow"
	@echo "make reports        Summarize latest run outputs"
	@echo "make clean          Remove local simulator build files"
	@echo "make distclean      Also remove LibreLane runs"
	@echo ""
	@echo "Overrides: PDK=sky130A RUN_TAG=lab6 JOBS=1 CONFIG=config.yaml"

check:
	@python3 scripts/check_project.py
	@command -v librelane >/dev/null 2>&1 || echo "NOTE: librelane is not currently in PATH"
	@command -v verilator >/dev/null 2>&1 || echo "NOTE: verilator is not currently in PATH"

lint:
	@command -v verilator >/dev/null 2>&1 || { echo "ERROR: verilator not found"; exit 1; }
	verilator --lint-only --Wall --Wno-fatal --top-module synth_sta_top $(RTL)

sim:
	@command -v verilator >/dev/null 2>&1 || { echo "ERROR: verilator not found"; exit 1; }
	mkdir -p $(BUILD)
	verilator --binary --timing --trace --Wall --Wno-fatal \
		--Mdir $(BUILD)/obj_dir --top-module $(TOP) $(RTL) $(TB)
	./$(BUILD)/obj_dir/V$(TOP)

sta:
	@command -v librelane >/dev/null 2>&1 || { echo "ERROR: librelane not found"; exit 1; }
	librelane -j $(JOBS) --flow Classic --pdk $(PDK) --run-tag $(RUN_TAG) \
		--to OpenROAD.STAPrePNR $(CONFIG)

synth-explore:
	@command -v librelane >/dev/null 2>&1 || { echo "ERROR: librelane not found"; exit 1; }
	librelane -j $(JOBS) --flow SynthesisExploration --pdk $(PDK) \
		--run-tag $(RUN_TAG)_explore $(CONFIG)

synthesis:
	librelane \
		--flow $(FLOW) \
		--pdk $(PDK) \
		--run-tag $(RUN_TAG) \
		--to OpenROAD.STAPrePNR \
		$(CONFIG)

run:
	@command -v librelane >/dev/null 2>&1 || { echo "ERROR: librelane not found"; exit 1; }
	librelane -j $(JOBS) --flow Classic --pdk $(PDK) --run-tag $(RUN_TAG) $(CONFIG)

reports:
	python3 scripts/collect_results.py --runs runs

clean:
	rm -rf $(BUILD)

# Deliberately separate from clean to avoid accidentally deleting expensive runs.
distclean: clean
	rm -rf runs
	mkdir -p runs
