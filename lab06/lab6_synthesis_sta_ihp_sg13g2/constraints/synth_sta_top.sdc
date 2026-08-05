cat > constraints/synth_sta_top.sdc <<'EOF'
# Lab 6: Synthesis and Static Timing Analysis
# Target PDK: IHP SG13G2
#
# Timing assumptions:
#   Clock period       = 10.000 ns (100 MHz)
#   Clock uncertainty  = 0.250 ns
#   Clock transition   = 0.150 ns
#   Input delay        = 2.000 ns
#   Output delay       = 4.000 ns

set clk_port [get_ports clk_i]

create_clock \
    -name core_clk \
    -period 10.000 \
    -waveform {0.000 5.000} \
    $clk_port

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

set data_inputs [all_inputs -no_clocks]

set_input_delay 2.000 \
    -clock [get_clocks core_clk] \
    $data_inputs

set_input_transition 0.150 $data_inputs

set_output_delay 4.000 \
    -clock [get_clocks core_clk] \
    [all_outputs]

set_load 0.033442 [all_outputs]

set_false_path -from [get_ports rst_ni]
EOF
