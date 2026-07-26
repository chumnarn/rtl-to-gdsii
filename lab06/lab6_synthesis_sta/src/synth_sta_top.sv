`default_nettype none

module synth_sta_top #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned ACC_WIDTH  = 24
) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  valid_i,
    input  logic [DATA_WIDTH-1:0] a_i,
    input  logic [DATA_WIDTH-1:0] b_i,
    output logic                  valid_o,
    output logic [ACC_WIDTH-1:0]  result_o
);

    localparam int unsigned PRODUCT_WIDTH = 2 * DATA_WIDTH;

    logic [DATA_WIDTH-1:0]    a_q;
    logic [DATA_WIDTH-1:0]    b_q;
    logic                     valid_q;
    logic [PRODUCT_WIDTH-1:0] product_comb;
    logic [ACC_WIDTH-1:0]     product_ext;
    logic [ACC_WIDTH-1:0]     accumulator_q;

    initial begin
        if (ACC_WIDTH < PRODUCT_WIDTH) begin
            $error("ACC_WIDTH (%0d) must be >= 2*DATA_WIDTH (%0d)",
                   ACC_WIDTH, PRODUCT_WIDTH);
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            a_q     <= '0;
            b_q     <= '0;
            valid_q <= 1'b0;
        end else begin
            valid_q <= valid_i;
            if (valid_i) begin
                a_q <= a_i;
                b_q <= b_i;
            end
        end
    end

    always_comb begin
        product_comb = a_q * b_q;
        product_ext  = {{(ACC_WIDTH-PRODUCT_WIDTH){1'b0}}, product_comb};
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            accumulator_q <= '0;
            result_o      <= '0;
            valid_o       <= 1'b0;
        end else begin
            valid_o <= valid_q;
            if (valid_q) begin
                accumulator_q <= accumulator_q + product_ext;
                result_o      <= accumulator_q + product_ext;
            end
        end
    end

endmodule

`default_nettype wire
