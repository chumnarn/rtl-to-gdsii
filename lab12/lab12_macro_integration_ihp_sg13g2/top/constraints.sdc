# macro_wrapper timing constraints

set clk_period 10.0

create_clock \
    -name clk \
    -period $clk_period \
    [get_ports clk]

set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition 0.15 [get_clocks clk]

# Input delay for non-clock input ports
set_input_delay 2.0 \
    -clock [get_clocks clk] \
    [all_inputs -no_clocks]

# Output delay
set_output_delay 2.0 \
    -clock [get_clocks clk] \
    [all_outputs]

# External output load
set_load 0.033442 [all_outputs]
