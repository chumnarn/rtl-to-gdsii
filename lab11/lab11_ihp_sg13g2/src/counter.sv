`default_nettype none

module counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             en_i,
    output logic [WIDTH-1:0] count_o,
    output logic             overflow_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o    <= '0;
            overflow_o <= 1'b0;
        end else begin
            overflow_o <= 1'b0;
            if (en_i) begin
                count_o <= count_o + 1'b1;
                if (&count_o) begin
                    overflow_o <= 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire
