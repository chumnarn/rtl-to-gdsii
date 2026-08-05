`default_nettype none

module routing_demo #(
    parameter int unsigned WIDTH = 32
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 enable,
    input  logic                 load,
    input  logic [WIDTH-1:0]     load_data,
    output logic [WIDTH-1:0]     count,
    output logic                 terminal_count,
    output logic                 parity
);

    logic [WIDTH-1:0] next_count;

    always_comb begin
        next_count = count;

        if (load) begin
            next_count = load_data;
        end
        else if (enable) begin
            next_count = count + {{(WIDTH-1){1'b0}}, 1'b1};
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end
        else begin
            count <= next_count;
        end
    end

    assign terminal_count = &count;
    assign parity         = ^count;

endmodule

`default_nettype wire
