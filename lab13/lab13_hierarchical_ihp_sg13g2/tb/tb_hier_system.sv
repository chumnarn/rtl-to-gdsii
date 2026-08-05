  GNU nano 8.7.1                                       tb/tb_hier_system.sv
`timescale 1ns/1ps
`default_nettype none

module tb_hier_system;
    localparam time CLK_PERIOD = 10ns;

    logic clk_i = 1'b0;
    logic rst_ni = 1'b0;
    logic counter_enable_i = 1'b0;
    logic accum_enable_i = 1'b0;
    logic [7:0] data_i = 8'h00;
    logic select_i = 1'b0;
    logic [7:0] result_o;

    hier_system dut (.*);
    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic check_result(input logic [7:0] expected, input string label);
        #1;
        if (result_o !== expected) begin
            $error("[FAIL] %s expected=0x%02h actual=0x%02h", label, expected, result_o);
            $fatal(1);
        end
        $display("[PASS] %s value=0x%02h", label, result_o);
    endtask

    initial begin
        $dumpfile("hier_system.vcd");
        $dumpvars(0, tb_hier_system);

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_ni = 1'b1;

        counter_enable_i = 1'b1;
        repeat (5) @(posedge clk_i);
        #1;
        counter_enable_i = 1'b0;
        select_i = 1'b0;
        check_result(8'h05, "counter counts five cycles");

        @(negedge clk_i);
        data_i = 8'h03;
        accum_enable_i = 1'b1;
        repeat (4) @(posedge clk_i);
        #1;
        accum_enable_i = 1'b0;
        select_i = 1'b1;
        check_result(8'h0c, "accumulator adds four times");

        @(negedge clk_i);
        rst_ni = 1'b0;
        #1;
        select_i = 1'b0;
        check_result(8'h00, "counter asynchronous reset");
        select_i = 1'b1;
        check_result(8'h00, "accumulator asynchronous reset");

        $display("[PASS] Lab 13 RTL simulation completed");
        $finish;
    end
endmodule

`default_nettype wire
