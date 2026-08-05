SHELL := /usr/bin/env bash

CONFIG  ?= config.yaml
PDK     ?= sky130A
TAG     ?= lab09-routing
JOBS    ?= 4

.PHONY: help check lint sim grt drt run gui metrics reports archive clean

help:
	@echo "Lab 9 targets"
	@echo "  make check    Validate project files and tool availability"
	@echo "  make lint     Run Verilator lint"
	@echo "  make sim      Run the self-checking RTL simulation"
	@echo "  make grt      Run LibreLane through Global Routing"
	@echo "  make drt      Run LibreLane through Detailed Routing"
	@echo "  make run      Run the complete Classic RTL-to-GDSII flow"
	@echo "  make gui      Open the latest run in OpenROAD GUI"
	@echo "  make metrics  Print routing-related metrics from latest run"
	@echo "  make reports  Locate routing logs and reports"
	@echo "  make archive  Package latest run reports"
	@echo "  make clean    Remove generated build and run directories"

check:
	@./scripts/check_environment.sh

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

# LibreLane supports --from/--to flow control. These targets intentionally
# stop at the routing stages so students can inspect intermediate databases.
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

clean:
	rm -rf build runs
