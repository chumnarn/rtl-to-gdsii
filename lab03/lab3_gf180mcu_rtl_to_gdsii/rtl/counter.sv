`default_nettype none

module counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 en_i,
    output logic [WIDTH-1:0]     count_o
);

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else if (en_i) begin
            count_o <= count_o + {{(WIDTH-1){1'b0}}, 1'b1};
        end
    end

endmodule

`default_nettype wire
