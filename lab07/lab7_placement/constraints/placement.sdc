# Lab 7: Placement Optimization
# Target PDK: IHP SG13G2

create_clock -name core_clk -period 10.000 \
    -waveform {0.000 5.000} \
    [get_ports clk_i]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

set data_inputs [get_ports {
    enable_i
    data_a_i[*]
    data_b_i[*]
    data_c_i[*]
    data_d_i[*]
}]

set_input_delay 2.000 \
    -clock [get_clocks core_clk] \
    $data_inputs

set_input_transition 0.150 $data_inputs

set_output_delay 4.000 \
    -clock [get_clocks core_clk] \
    [get_ports {result_o[*]}]

set_load 0.033442 [get_ports {result_o[*]}]

set_false_path -from [get_ports rst_ni]
