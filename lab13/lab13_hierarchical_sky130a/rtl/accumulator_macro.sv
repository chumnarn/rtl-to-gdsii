`timescale 1ns/1ps
`default_nettype none

module accumulator_macro #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             enable_i,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] accum_o
);
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            accum_o <= '0;
        else if (enable_i)
            accum_o <= accum_o + data_i;
    end
endmodule

`default_nettype wire
