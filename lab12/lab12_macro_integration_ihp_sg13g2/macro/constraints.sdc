set clk [get_ports clk_i]

create_clock \
    -name core_clk \
    -period 20.000 \
    -waveform {0.000 10.000} \
    $clk

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set data_inputs [remove_from_collection [all_inputs] $clk]

set_input_delay -clock core_clk -max 2.000 $data_inputs
set_input_delay -clock core_clk -min 0.000 $data_inputs

set_output_delay -clock core_clk -max 4.000 [all_outputs]
set_output_delay -clock core_clk -min 0.000 [all_outputs]

set_load 0.033442 [all_outputs]
