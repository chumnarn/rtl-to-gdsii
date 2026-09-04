PDK     ?= ihp-sg13g2
CONFIG  ?= config.yaml
TAG     ?= lab15_ihp_fullchip

.PHONY: help prepare preflight lint synth floorplan padring run \
        openroad klayout reports clean

help:
	@echo "make prepare    Check the PDK and obtain the official bondpad GDS"
	@echo "make preflight  Check tools, I/O macros, bondpad and RTL"
	@echo "make lint       Run Verilator lint"
	@echo "make synth      Run through Yosys.Synthesis"
	@echo "make floorplan  Run through OpenROAD.Floorplan"
	@echo "make padring    Run through OpenROAD.PadRing"
	@echo "make run        Run the complete LibreLane Chip flow"
	@echo "make openroad   Open the latest run in OpenROAD"
	@echo "make klayout    Open the latest run in KLayout"
	@echo "make reports    Summarize timing, routing, DRC and LVS"
	@echo "make clean      Remove generated runs"

prepare:
	python3 scripts/prepare.py

preflight:
	bash scripts/preflight.sh

lint:
	verilator \
		--lint-only \
		--Wall \
		--Wno-DECLFILENAME \
		--Wno-PINMISSING \
        --Wno-MODMISSING \
        --Wno-UNDRIVEN \
        --Wno-UNUSEDSIGNAL \
		--top-module chip_top \
		src/counter_core.sv \
		src/chip_top.sv

synth: prepare
	librelane \
		--pdk $(PDK) \
		--flow Chip \
		--run-tag $(TAG)_synth \
		--to Yosys.Synthesis \
		$(CONFIG)

floorplan: prepare
	librelane \
		--pdk $(PDK) \
		--flow Chip \
		--run-tag $(TAG)_floorplan \
		--to OpenROAD.Floorplan \
		$(CONFIG)

padring: prepare
	librelane \
		--pdk $(PDK) \
		--flow Chip \
		--run-tag $(TAG)_padring \
		--to OpenROAD.PadRing \
		$(CONFIG)

run: prepare
	librelane \
		--pdk $(PDK) \
		--flow Chip \
		--run-tag $(TAG) \
		$(CONFIG)

openroad:
	librelane \
		--pdk $(PDK) \
		--last-run \
		--flow OpenInOpenROAD \
		$(CONFIG)

klayout:
	librelane \
		--pdk $(PDK) \
		--last-run \
		--flow OpenInKLayout \
		$(CONFIG)

reports:
	bash scripts/report_results.sh runs

clean:
	rm -rf runs
	rm -f ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
