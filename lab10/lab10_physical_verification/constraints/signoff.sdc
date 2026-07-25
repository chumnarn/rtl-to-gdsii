# Lab 10 signoff timing constraints
# Clock period: 20 ns = 50 MHz

create_clock -name core_clk -period 20.000 [get_ports clk]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 2.000 -clock core_clk [get_ports {enable}]
set_output_delay 4.000 -clock core_clk [get_ports {count[*]}]
set_load 0.033442 [get_ports {count[*]}]

set_false_path -from [get_ports rst_n]

# Simple early/late derating for the training signoff exercise.
set_timing_derate -early 0.95
set_timing_derate -late  1.05
