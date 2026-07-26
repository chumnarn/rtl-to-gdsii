SHELL := /bin/bash

TOP          := counter_tb
DUT_TOP      := counter
RTL          := rtl/counter.sv
TB           := tb/counter_tb.sv

BUILD_DIR    := build
OBJ_DIR      := $(BUILD_DIR)/obj_dir
SIM_BIN      := $(OBJ_DIR)/counter_sim
WAVE_DIR     := waves
WAVE_FILE    := $(WAVE_DIR)/counter.fst
LOG_DIR      := logs

VERILATOR    ?= verilator
YOSYS        ?= yosys
GTKWAVE      ?= gtkwave
LIBRELANE    ?= librelane
PDK          ?= ihp-sg13g2

VERILATOR_COMMON := \
	--timing \
	--trace-fst \
	--Wall \
	--Wno-fatal \
	--top-module $(TOP)

.PHONY: all help check-tools lint build sim run wave yosys librelane \
        openroad klayout clean distclean

all: sim

help:
	@echo "Lab 2 targets"
	@echo "  make check-tools  Check required commands"
	@echo "  make lint         Lint RTL and testbench with Verilator"
	@echo "  make build        Compile the Verilator simulator"
	@echo "  make sim          Build and run self-checking simulation"
	@echo "  make run          Alias for make sim"
	@echo "  make wave         Open waves/counter.fst in GTKWave"
	@echo "  make yosys        Run standalone Yosys synthesis"
	@echo "  make librelane    Run LibreLane Classic flow using config.yaml"
	@echo "  make openroad     Open the latest LibreLane result in OpenROAD"
	@echo "  make klayout      Open the latest LibreLane result in KLayout"
	@echo "  make clean        Delete simulation and synthesis products"
	@echo "  make distclean    Also delete LibreLane run/"
	@echo ""
	@echo "Variables: PDK=$(PDK), VERILATOR, YOSYS, GTKWAVE, LIBRELANE"

check-tools:
	@bash scripts/check_tools.sh

lint:
	@mkdir -p $(LOG_DIR)
	$(VERILATOR) \
		--lint-only \
		$(VERILATOR_COMMON) \
		$(RTL) $(TB) \
		2>&1 | tee $(LOG_DIR)/verilator_lint.log

build: $(SIM_BIN)

$(SIM_BIN): $(RTL) $(TB)
	@mkdir -p $(OBJ_DIR) $(WAVE_DIR) $(LOG_DIR)
	$(VERILATOR) \
		--binary \
		$(VERILATOR_COMMON) \
		--Mdir $(OBJ_DIR) \
		-o counter_sim \
		$(RTL) $(TB) \
		2>&1 | tee $(LOG_DIR)/verilator_build.log

sim: build
	@mkdir -p $(WAVE_DIR) $(LOG_DIR)
	./$(SIM_BIN) 2>&1 | tee $(LOG_DIR)/simulation.log
	@test -s $(WAVE_FILE)
	@grep -q "LAB RESULT      : PASS" $(LOG_DIR)/simulation.log
	@echo "Simulation PASS; waveform: $(WAVE_FILE)"

run: sim

wave:
	@test -s $(WAVE_FILE) || { echo "Waveform not found. Run 'make sim' first."; exit 1; }
	$(GTKWAVE) $(WAVE_FILE)

yosys:
	@mkdir -p $(BUILD_DIR) $(LOG_DIR)
	$(YOSYS) -s yosys/synth.ys 2>&1 | tee $(LOG_DIR)/yosys.log
	@test -s $(BUILD_DIR)/counter_synth.v

librelane:
	$(LIBRELANE) --pdk $(PDK) config.yaml

openroad:
	$(LIBRELANE) --pdk $(PDK) config.yaml --last-run --flow OpenInOpenROAD

klayout:
	$(LIBRELANE) --pdk $(PDK) config.yaml --last-run --flow OpenInKLayout

clean:
	rm -rf $(OBJ_DIR)
	rm -f $(WAVE_FILE)
	rm -f $(BUILD_DIR)/counter_synth.v
	rm -rf $(LOG_DIR)

distclean: clean
	rm -rf run
