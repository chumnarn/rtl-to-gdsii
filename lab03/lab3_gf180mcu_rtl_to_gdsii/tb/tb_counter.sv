`timescale 1ns/1ps
`default_nettype none

module tb_counter;
    localparam int unsigned WIDTH = 8;
    localparam time CLK_PERIOD = 24ns;

    logic clk_i;
    logic rst_ni;
    logic en_i;
    logic [WIDTH-1:0] count_o;
    logic [WIDTH-1:0] expected;

    counter #(.WIDTH(WIDTH)) dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .en_i    (en_i),
        .count_o (count_o)
    );

    initial clk_i = 1'b0;
    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic check_count(input logic [WIDTH-1:0] value);
        #1ns;
        assert (count_o === value)
            else $fatal(1, "count mismatch: expected=%0d actual=%0d", value, count_o);
    endtask

    initial begin
        $dumpfile("waves/counter.vcd");
        $dumpvars(0, tb_counter);

        rst_ni  = 1'b0;
        en_i    = 1'b0;
        expected = '0;

        repeat (2) begin
            @(posedge clk_i);
            check_count('0);
        end

        rst_ni = 1'b1;
        en_i   = 1'b1;
        repeat (20) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check_count(expected);
        end

        en_i = 1'b0;
        repeat (4) begin
            @(posedge clk_i);
            check_count(expected);
        end

        en_i = 1'b1;
        repeat (4) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check_count(expected);
        end

        rst_ni = 1'b0;
        @(posedge clk_i);
        check_count('0);

        $display("PASS: self-checking counter simulation completed");
        $finish;
    end

    initial begin
        #(CLK_PERIOD * 100);
        $fatal(1, "Timeout");
    end
endmodule

`default_nettype wire
