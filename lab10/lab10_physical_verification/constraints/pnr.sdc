# Lab 10 PnR timing constraints
# Clock period: 20 ns = 50 MHz

create_clock -name core_clk -period 20.000 [get_ports clk]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 2.000 -clock core_clk [get_ports {enable}]
set_output_delay 4.000 -clock core_clk [get_ports {count[*]}]
set_load 0.033442 [get_ports {count[*]}]

# rst_n is an asynchronous reset and is not a synchronous data path.
set_false_path -from [get_ports rst_n]
