`timescale 1ns/1ps
`default_nettype none

module tb_counter;
    localparam int WIDTH = 8;
    localparam time CLK_PERIOD = 20ns;

    logic clk_i = 1'b0;
    logic rst_ni = 1'b0;
    logic en_i = 1'b0;
    logic [WIDTH-1:0] count_o;
    logic overflow_o;
    logic [WIDTH-1:0] expected;

    counter #(.WIDTH(WIDTH)) dut (.*);

    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic check(input logic [WIDTH-1:0] exp_count, input logic exp_overflow);
        #1;
        if ((count_o !== exp_count) || (overflow_o !== exp_overflow)) begin
            $error("Mismatch: count=%0h expected=%0h overflow=%0b expected=%0b",
                   count_o, exp_count, overflow_o, exp_overflow);
            $fatal(1);
        end
    endtask

    initial begin
        $dumpfile("build/tb_counter.vcd");
        $dumpvars(0, tb_counter);

        repeat (3) @(posedge clk_i);
        rst_ni <= 1'b1;
        expected = '0;
        check(expected, 1'b0);

        en_i <= 1'b1;
        repeat (10) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check(expected, 1'b0);
        end

        en_i <= 1'b0;
        repeat (3) begin
            @(posedge clk_i);
            check(expected, 1'b0);
        end

        en_i <= 1'b1;
        while (expected != '1) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check(expected, 1'b0);
        end

        @(posedge clk_i);
        expected = '0;
        check(expected, 1'b1);

        @(posedge clk_i);
        expected = expected + 1'b1;
        check(expected, 1'b0);

        rst_ni <= 1'b0;
        @(negedge clk_i);
        check('0, 1'b0);

        $display("PASS: counter self-checking simulation completed.");
        $finish;
    end
endmodule

`default_nettype wire
