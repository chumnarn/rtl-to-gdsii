`timescale 1ns/1ps
`default_nettype none

module tb_counter;

    localparam int WIDTH = 8;

    logic clk;
    logic rst_n;
    logic enable;
    logic [WIDTH-1:0] count;

    counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .count  (count)
    );

    always #10 clk = ~clk;

    task automatic check_count(input logic [WIDTH-1:0] expected);
        if (count !== expected) begin
            $error("count=%0d expected=%0d at time=%0t", count, expected, $time);
            $fatal(1);
        end
    endtask

    initial begin
        $dumpfile("reports/counter.vcd");
        $dumpvars(0, tb_counter);

        clk    = 1'b0;
        rst_n  = 1'b0;
        enable = 1'b0;

        repeat (3) @(posedge clk);
        #1;
        check_count('0);

        rst_n = 1'b1;
        enable = 1'b1;

        repeat (10) @(posedge clk);
        #1;
        check_count(8'd10);

        enable = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        check_count(8'd10);

        enable = 1'b1;
        repeat (5) @(posedge clk);
        #1;
        check_count(8'd15);

        rst_n = 1'b0;
        #1;
        check_count('0);

        $display("PASS: counter RTL simulation");
        $finish;
    end

endmodule

`default_nettype wire
