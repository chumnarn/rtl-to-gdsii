# Lab 6: Synthesis and Static Timing Analysis
# Target PDK: IHP SG13G2

set clk_port [get_ports clk_i]

create_clock \
    -name core_clk \
    -period 10.000 \
    -waveform {0.000 5.000} \
    $clk_port

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

# Functional inputs only; exclude clock and asynchronous reset.
set data_inputs [get_ports {
    valid_i
    a_i[*]
    b_i[*]
}]

set_input_delay 2.000 \
    -clock [get_clocks core_clk] \
    $data_inputs

set_input_transition 0.150 $data_inputs

set_output_delay 4.000 \
    -clock [get_clocks core_clk] \
    [all_outputs]

set_load 0.033442 [all_outputs]

set_false_path -from [get_ports rst_ni]
