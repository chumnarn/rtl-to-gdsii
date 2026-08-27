`default_nettype none

module floorplan_demo #(
    parameter integer WIDTH = 8
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable_i,
    input  wire                 load_i,
    input  wire [WIDTH-1:0]     data_i,
    output wire [WIDTH-1:0]     count_o,
    output wire                 terminal_o
);

    reg [WIDTH-1:0] count_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count_q <= {WIDTH{1'b0}};
        else if (load_i)
            count_q <= data_i;
        else if (enable_i)
            count_q <= count_q + {{(WIDTH-1){1'b0}}, 1'b1};
    end

    assign count_o    = count_q;
    assign terminal_o = &count_q;

endmodule

`default_nettype wire
