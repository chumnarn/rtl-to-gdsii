`timescale 1ns/1ps
`default_nettype none

module tb_counter;
    localparam int unsigned WIDTH = 8;
    localparam time CLK_PERIOD = 10ns;

    logic clk_i = 1'b0;
    logic rst_ni = 1'b0;
    logic en_i = 1'b0;
    logic [WIDTH-1:0] count_o;
    logic [WIDTH-1:0] expected = '0;

    counter #(.WIDTH(WIDTH)) dut (.*);

    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic sample_and_check(input logic [WIDTH-1:0] exp);
        @(negedge clk_i);
        assert (count_o === exp)
            else $fatal(1,
                "FAIL time=%0t expected=0x%0h actual=0x%0h",
                $time, exp, count_o);
    endtask

    initial begin
        $dumpfile("waves/counter.vcd");
        $dumpvars(0, tb_counter);

        // Synchronous active-low reset.
        repeat (2) @(posedge clk_i);
        sample_and_check('0);

        // Count for 20 cycles.
        rst_ni = 1'b1;
        en_i = 1'b1;
        repeat (20) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            sample_and_check(expected);
        end

        // Disable and hold the value.
        en_i = 1'b0;
        repeat (4) begin
            @(posedge clk_i);
            sample_and_check(expected);
        end

        // Resume counting.
        en_i = 1'b1;
        repeat (8) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            sample_and_check(expected);
        end

        // Reset at a rising edge.
        rst_ni = 1'b0;
        @(posedge clk_i);
        expected = '0;
        sample_and_check(expected);

        $display("PASS: self-checking counter simulation completed");
        $finish;
    end

    initial begin
        #(200 * CLK_PERIOD);
        $fatal(1, "TIMEOUT");
    end
endmodule

`default_nettype wire
