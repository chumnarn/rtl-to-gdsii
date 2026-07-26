`default_nettype none

module lab4_counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 enable_i,
    input  logic                 load_i,
    input  logic                 up_i,
    input  logic [WIDTH-1:0]     data_i,
    output logic [WIDTH-1:0]     count_o,
    output logic                 carry_o
);

    logic [WIDTH-1:0] count_d;
    logic             carry_d;

    always_comb begin
        count_d = count_o;
        carry_d = 1'b0;

        if (load_i) begin
            count_d = data_i;
        end else if (enable_i) begin
            if (up_i) begin
                count_d = count_o + {{(WIDTH-1){1'b0}}, 1'b1};
                carry_d = &count_o;
            end else begin
                count_d = count_o - {{(WIDTH-1){1'b0}}, 1'b1};
                carry_d = ~|count_o;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o <= '0;
            carry_o <= 1'b0;
        end else begin
            count_o <= count_d;
            carry_o <= carry_d;
        end
    end

endmodule

`default_nettype wire
