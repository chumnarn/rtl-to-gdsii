`timescale 1ns/1ps
`default_nettype none

module tb_cts_demo;

    localparam integer WIDTH = 32;

    reg                  clk_i;
    reg                  rst_ni;
    reg                  enable_i;
    reg  [7:0]           data_i;
    wire [WIDTH-1:0]     count_o;
    wire [15:0]          checksum_o;
    wire                 event_o;

    integer cycle;
    integer event_count;

    cts_demo #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .enable_i(enable_i),
        .data_i(data_i),
        .count_o(count_o),
        .checksum_o(checksum_o),
        .event_o(event_o)
    );

    always #5 clk_i = ~clk_i;

    initial begin
        $dumpfile("build/cts_demo.vcd");
        $dumpvars(0, tb_cts_demo);

        clk_i       = 1'b0;
        rst_ni      = 1'b0;
        enable_i    = 1'b0;
        data_i      = 8'h00;
        event_count = 0;

        repeat (4) @(posedge clk_i);
        rst_ni = 1'b1;

        @(posedge clk_i);
        enable_i = 1'b1;

        for (cycle = 0; cycle < 40; cycle = cycle + 1) begin
            data_i = cycle[7:0];
            @(posedge clk_i);
            #1;
            if (event_o)
                event_count = event_count + 1;
        end

        enable_i = 1'b0;
        repeat (3) @(posedge clk_i);

        if (checksum_o !== 16'd780) begin
            $display("ERROR: checksum_o=%0d expected=780", checksum_o);
            $fatal(1);
        end

        if (event_count !== 2) begin
            $display("ERROR: event_count=%0d expected=2", event_count);
            $fatal(1);
        end

        $display("PASS: functional simulation completed");
        $display("count_o=0x%08x checksum_o=%0d events=%0d",
                 count_o, checksum_o, event_count);
        $finish;
    end

    initial begin
        #2000;
        $display("ERROR: simulation timeout");
        $fatal(1);
    end

endmodule

`default_nettype wire
