# Lab 11 IHP SG13G2 timing constraints
create_clock -name core_clk -period 25.000 [get_ports clk_i]
set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay  2.000 -clock core_clk [get_ports en_i]
set_output_delay 4.000 -clock core_clk [get_ports {count_o[*] overflow_o}]

# Asynchronous reset is not a functional data path.
set_false_path -from [get_ports rst_ni]

# Representative output load for the lab.
set_load 0.033442 [get_ports {count_o[*] overflow_o}]
