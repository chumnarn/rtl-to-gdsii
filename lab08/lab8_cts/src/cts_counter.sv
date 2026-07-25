module cts_counter #(
    parameter int unsigned WIDTH = 32
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             enable_i,
    output logic [WIDTH-1:0] count_o,
    output logic             event_o
);

    logic [WIDTH-1:0] count_q;
    logic [WIDTH-1:0] shadow_q;
    logic [7:0]       cycle_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_q  <= '0;
            shadow_q <= '0;
            cycle_q  <= '0;
            event_o  <= 1'b0;
        end else begin
            event_o <= 1'b0;
            if (enable_i) begin
                count_q <= count_q + {{(WIDTH-1){1'b0}}, 1'b1};
                cycle_q <= cycle_q + 8'd1;
                if (cycle_q == 8'hff) begin
                    shadow_q <= count_q;
                    event_o  <= 1'b1;
                end
            end
        end
    end

    assign count_o = count_q ^ shadow_q;

endmodule
