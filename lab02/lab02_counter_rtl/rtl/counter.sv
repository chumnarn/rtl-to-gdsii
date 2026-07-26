// SPDX-License-Identifier: Apache-2.0
// Lab 2: 8-bit synchronous up-counter with active-low synchronous reset.

module counter (
    input  logic       clk_i,
    input  logic       rst_ni,
    output logic [7:0] count_o
);

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else begin
            count_o <= count_o + 8'd1;
        end
    end

endmodule
