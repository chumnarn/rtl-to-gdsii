# Lab 9 signoff constraints
create_clock -name core_clk -period 20.000 [get_ports clk]
set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

set_input_delay 2.000 -clock [get_clocks core_clk] \
    [get_ports {enable load load_data*}]
set_output_delay 4.000 -clock [get_clocks core_clk] \
    [get_ports {count* terminal_count parity}]
set_load 0.033442 [get_ports {count* terminal_count parity}]
set_false_path -from [get_ports rst_n]
