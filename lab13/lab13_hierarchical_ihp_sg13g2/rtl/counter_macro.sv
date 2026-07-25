`timescale 1ns/1ps
`default_nettype none

module counter_macro #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             enable_i,
    output logic [WIDTH-1:0] count_o
);
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            count_o <= '0;
        else if (enable_i)
            count_o <= count_o + {{(WIDTH-1){1'b0}}, 1'b1};
    end
endmodule

`default_nettype wire
