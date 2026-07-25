SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PDK ?= ihp-sg13g2
LIBRELANE ?= librelane
VERILATOR ?= verilator

RTL := rtl/counter_macro.sv rtl/accumulator_macro.sv rtl/hier_system.sv
TB  := tb/tb_hier_system.sv

.PHONY: help check tools lint sim counter accumulator macros collect check-macros top top-sta all clean

help:
	@echo "Lab 13 Hierarchical Physical Design — IHP SG13G2"
	@echo "  make check       Validate project files and YAML"
	@echo "  make tools       Print tool versions"
	@echo "  make lint        Verilator RTL lint"
	@echo "  make sim         Build and run self-checking RTL simulation"
	@echo "  make counter     Harden counter_macro with LibreLane"
	@echo "  make accumulator Harden accumulator_macro with LibreLane"
	@echo "  make macros      Harden both macros"
	@echo "  make collect     Copy latest macro views to macros/"
	@echo "  make top         Run robust top integration (LEF/GDS/VH)"
	@echo "  make top-sta     Run NL+SPEF hierarchical STA integration"
	@echo "  make all         sim -> macros -> collect -> top"

check:
	./scripts/check_project.sh

tools:
	@$(VERILATOR) --version
	@$(LIBRELANE) --version
	@openroad -version || true
	@klayout -v || true

lint:
	$(VERILATOR) --lint-only --timing -Wall -Wno-fatal --top-module hier_system $(RTL)

sim:
	$(VERILATOR) --binary --timing --trace -Wall -Wno-fatal \
		--top-module tb_hier_system $(RTL) $(TB)
	./obj_dir/Vtb_hier_system

counter:
	$(LIBRELANE) --pdk $(PDK) blocks/counter_macro/config.yaml

accumulator:
	$(LIBRELANE) --pdk $(PDK) blocks/accumulator_macro/config.yaml

macros: counter accumulator

collect:
	./scripts/collect_macro_views.sh counter_macro
	./scripts/collect_macro_views.sh accumulator_macro
	./scripts/check_macro_views.sh

check-macros:
	./scripts/check_macro_views.sh

top: check-macros
	$(LIBRELANE) --pdk $(PDK) top/config.yaml

top-sta: check-macros
	@test -s macros/counter_macro/nl/counter_macro.nl.v
	@test -s macros/counter_macro/spef/counter_macro.spef
	@test -s macros/accumulator_macro/nl/accumulator_macro.nl.v
	@test -s macros/accumulator_macro/spef/accumulator_macro.spef
	$(LIBRELANE) --pdk $(PDK) top/config_hier_sta.yaml

all: sim macros collect top

clean:
	rm -rf obj_dir hier_system.vcd
