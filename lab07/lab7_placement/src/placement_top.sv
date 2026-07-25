module placement_top #(
    parameter int unsigned WIDTH = 32
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             enable_i,
    input  logic [WIDTH-1:0] data_a_i,
    input  logic [WIDTH-1:0] data_b_i,
    input  logic [WIDTH-1:0] data_c_i,
    input  logic [WIDTH-1:0] data_d_i,
    output logic [WIDTH-1:0] result_o
);

    logic [WIDTH-1:0] stage0_q;
    logic [WIDTH-1:0] stage1_q;
    logic [WIDTH-1:0] stage2_q;
    logic [WIDTH-1:0] stage3_q;

    logic [WIDTH-1:0] add0_w;
    logic [WIDTH-1:0] add1_w;
    logic [WIDTH-1:0] xor0_w;
    logic [WIDTH-1:0] mix0_w;

    assign add0_w = data_a_i + data_b_i;
    assign add1_w = data_c_i + data_d_i;
    assign xor0_w = stage0_q ^ stage1_q;
    assign mix0_w = stage2_q[0]
                  ? (xor0_w + stage2_q)
                  : (xor0_w ^ stage2_q);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            stage0_q <= '0;
            stage1_q <= '0;
            stage2_q <= '0;
            stage3_q <= '0;
        end else if (enable_i) begin
            stage0_q <= add0_w;
            stage1_q <= add1_w;
            stage2_q <= stage0_q + stage1_q;
            stage3_q <= mix0_w;
        end
    end

    assign result_o = stage3_q;

endmodule
