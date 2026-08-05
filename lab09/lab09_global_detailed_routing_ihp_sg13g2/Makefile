SHELL := /usr/bin/env bash

CONFIG  ?= config.yaml
PDK     ?= ihp-sg13g2
TAG     ?= lab09-ihp-routing
JOBS    ?= 4

.PHONY: help check lint sim validate grt drt run gui metrics reports archive experiments clean distclean

help:
	@echo "Lab 9 — Global and Detailed Routing (IHP SG13G2)"
	@echo "  make check        Check files, tools and PDK visibility"
	@echo "  make lint         Run Verilator lint"
	@echo "  make sim          Run self-checking RTL simulation"
	@echo "  make validate     Ask LibreLane to load/validate config"
	@echo "  make grt          Run through OpenROAD.GlobalRouting"
	@echo "  make drt          Run through OpenROAD.DetailedRouting"
	@echo "  make run          Run complete Classic RTL-to-GDSII flow"
	@echo "  make gui          Open latest run in OpenROAD GUI"
	@echo "  make metrics      Print routing metrics from latest run"
	@echo "  make reports      Locate routing logs/reports/databases"
	@echo "  make archive      Archive reports from latest run"
	@echo "  make experiments  Sweep GRT_ADJUSTMENT values"
	@echo "  make clean        Remove simulation and experiment output"
	@echo "  make distclean    Also remove LibreLane runs"

check:
	@PDK=$(PDK) ./scripts/check_environment.sh

lint:
	@command -v verilator >/dev/null || { echo "ERROR: verilator not found"; exit 1; }
	verilator --lint-only --timing -Wall -Wno-fatal \
		--top-module routing_demo src/routing_demo.sv

sim:
	@command -v verilator >/dev/null || { echo "ERROR: verilator not found"; exit 1; }
	rm -rf build/sim
	mkdir -p build/sim
	verilator --binary --timing -Wall -Wno-fatal \
		--Mdir build/sim --top-module tb_routing_demo \
		src/routing_demo.sv tb/tb_routing_demo.sv
	./build/sim/Vtb_routing_demo

# This starts only the initial flow step and therefore catches most YAML/PDK
# loading errors without running place-and-route.
validate:
	librelane -j $(JOBS) --pdk $(PDK) --run-tag $(TAG)-validate \
		--to Verilator.Lint $(CONFIG)

grt:
	librelane -j $(JOBS) --pdk $(PDK) --run-tag $(TAG)-grt \
		--to OpenROAD.GlobalRouting $(CONFIG)

drt:
	librelane -j $(JOBS) --pdk $(PDK) --run-tag $(TAG)-drt \
		--to OpenROAD.DetailedRouting $(CONFIG)

run:
	librelane -j $(JOBS) --pdk $(PDK) --run-tag $(TAG)-full $(CONFIG)

gui:
	librelane --pdk $(PDK) --last-run --flow OpenInOpenROAD $(CONFIG)

metrics:
	python3 scripts/report_routing_metrics.py runs

reports:
	@./scripts/find_routing_reports.sh runs

archive:
	@./scripts/archive_latest_reports.sh runs

experiments:
	@PDK=$(PDK) JOBS=$(JOBS) ./scripts/run_experiments.sh

clean:
	rm -rf build/sim build/experiments reports_archive

# Deliberately separate because runs may take a long time to reproduce.
distclean: clean
	rm -rf runs
	mkdir -p runs
