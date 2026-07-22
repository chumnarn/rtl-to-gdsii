# Lab 8 CTS — IHP SG13G2 PnR constraints
# 20 ns period = 50 MHz

current_design $::env(DESIGN_NAME)
set_units -time ns

create_clock \
    -name core_clk \
    -period 20.000 \
    -waveform {0.000 10.000} \
    [get_ports clk_i]

set clocks [get_clocks core_clk]

# Implementation margins
set_clock_uncertainty 0.250 $clocks
set_clock_transition  0.150 $clocks

# Input interface timing, excluding asynchronous reset and clock
set data_inputs [get_ports {enable_i data_i[*]}]
set_input_delay -min 0.000 -clock $clocks $data_inputs
set_input_delay -max 2.000 -clock $clocks $data_inputs

# Asynchronous reset is not a synchronous data path.
set_false_path -from [get_ports rst_ni]

# Output interface timing and load
set outputs [get_ports {count_o[*] checksum_o[*] event_o}]
set_output_delay -min 0.000 -clock $clocks $outputs
set_output_delay -max 4.000 -clock $clocks $outputs
set_load 0.033442 $outputs

# Conservative implementation derating.
set_timing_derate -early 0.95
set_timing_derate -late  1.05

# LibreLane/OpenROAD should use the real clock network after CTS.
set_propagated_clock $clocks
