`default_nettype none

module cts_demo #(
    parameter integer WIDTH = 32
) (
    input  wire                 clk_i,
    input  wire                 rst_ni,
    input  wire                 enable_i,
    input  wire [7:0]           data_i,
    output wire [WIDTH-1:0]     count_o,
    output wire [15:0]          checksum_o,
    output wire                 event_o
);

    reg [WIDTH-1:0] count_q;
    reg [WIDTH-1:0] shadow_q;
    reg [15:0]      checksum_q;
    reg [7:0]       cycle_q;
    reg             event_q;

    wire [WIDTH-1:0] data_ext;
    assign data_ext = {{(WIDTH-8){1'b0}}, data_i};

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_q    <= {WIDTH{1'b0}};
            shadow_q   <= {WIDTH{1'b0}};
            checksum_q <= 16'h0000;
            cycle_q    <= 8'h00;
            event_q    <= 1'b0;
        end else begin
            event_q <= 1'b0;

            if (enable_i) begin
                count_q    <= count_q + {{(WIDTH-1){1'b0}}, 1'b1};
                checksum_q <= checksum_q + {8'h00, data_i};
                cycle_q    <= cycle_q + 8'h01;

               if (cycle_q[3:0] == 4'hf) begin
                    shadow_q <= count_q ^ data_ext;
                    event_q  <= 1'b1;
                end
            end
        end
    end

    assign count_o    = count_q ^ shadow_q;
    assign checksum_o = checksum_q;
    assign event_o    = event_q;

endmodule

`default_nettype wire
