# LibreLane/OpenROAD constraints for Lab 14.
set clk_port [get_ports clk]
create_clock -name clk -period 20.000 $clk_port

set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]

set non_clock_inputs [remove_from_collection [all_inputs] $clk_port]
set_input_delay 2.0 -clock clk $non_clock_inputs
set_output_delay 4.0 -clock clk [all_outputs]

set_load 0.033442 [all_outputs]
