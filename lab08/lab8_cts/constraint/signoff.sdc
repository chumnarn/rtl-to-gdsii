# Lab 8: signoff constraints (50 MHz)
create_clock -name core_clk -period 20.000 -waveform {0.000 10.000} [get_ports clk_i]

set_clock_uncertainty 0.250 [get_clocks core_clk]

set_input_delay 2.000 -clock [get_clocks core_clk] [get_ports enable_i]
set_false_path -from [get_ports rst_ni]

set_output_delay 4.000 -clock [get_clocks core_clk] [get_ports {count_o[*] event_o}]
set_load 0.033442 [get_ports {count_o[*] event_o}]

set_timing_derate -early 0.95
set_timing_derate -late 1.05
