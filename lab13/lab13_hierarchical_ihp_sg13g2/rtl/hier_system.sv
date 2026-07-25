`timescale 1ns/1ps
`default_nettype none

module hier_system (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  logic       counter_enable_i,
    input  logic       accum_enable_i,
    input  logic [7:0] data_i,
    input  logic       select_i,
    output logic [7:0] result_o
);
    logic [7:0] count_value;
    logic [7:0] accum_value;

    counter_macro u_counter_macro (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (counter_enable_i),
        .count_o  (count_value)
    );

    accumulator_macro u_accumulator_macro (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (accum_enable_i),
        .data_i   (data_i),
        .accum_o  (accum_value)
    );

    always_comb begin
        result_o = select_i ? accum_value : count_value;
    end
endmodule

`default_nettype wire
