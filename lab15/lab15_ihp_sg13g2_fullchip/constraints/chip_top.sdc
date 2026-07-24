current_design $::env(DESIGN_NAME)
set_units -time ns

# The clock begins at the internal p2c pin of the clock pad.
create_clock \
    -name core_clk \
    -period $::env(CLOCK_PERIOD) \
    [get_pins clk_pad/p2c]

set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition 0.15 [get_clocks core_clk]

set_input_delay -min 0.0 -clock core_clk [get_ports enable_PAD]
set_input_delay -max 2.0 -clock core_clk [get_ports enable_PAD]

set_output_delay -min 0.0 -clock core_clk [get_ports {count_PAD[*]}]
set_output_delay -max 4.0 -clock core_clk [get_ports {count_PAD[*]}]

set_false_path -from [get_ports rst_n_PAD]
set_load 0.033442 [get_ports {count_PAD[*]}]

set_timing_derate -early 0.95
set_timing_derate -late  1.05
