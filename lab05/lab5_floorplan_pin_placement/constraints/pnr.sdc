# Lab 5 PnR constraints: 100 MHz target clock

set CLK_PERIOD 10.0

create_clock \
    -name core_clk \
    -period $CLK_PERIOD \
    [get_ports clk]

set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition  0.15 [get_clocks core_clk]

set non_clock_inputs [all_inputs -no_clocks]

set_input_delay  2.0 -clock core_clk $non_clock_inputs
set_output_delay 4.0 -clock core_clk [all_outputs]
set_load 0.033442 [all_outputs]
