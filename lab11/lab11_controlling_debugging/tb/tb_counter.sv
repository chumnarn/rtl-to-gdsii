`timescale 1ns/1ps
`default_nettype none

module tb_counter;
    localparam int unsigned WIDTH = 8;

    logic             clk_i;
    logic             rst_ni;
    logic             enable_i;
    logic [WIDTH-1:0] count_o;
    logic [WIDTH-1:0] expected;

    counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (enable_i),
        .count_o  (count_o)
    );

    initial clk_i = 1'b0;
    always #10 clk_i = ~clk_i;

    task automatic check_count(input logic [WIDTH-1:0] value);
        if (count_o !== value) begin
            $error("count_o=%0d expected=%0d at t=%0t", count_o, value, $time);
            $fatal(1);
        end
    endtask

    initial begin
        $dumpfile("build/counter.vcd");
        $dumpvars(0, tb_counter);

        rst_ni   = 1'b0;
        enable_i = 1'b0;
        expected = '0;

        repeat (2) @(posedge clk_i);
        #1;
        check_count('0);

        rst_ni = 1'b1;
        enable_i = 1'b1;

        repeat (10) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            #1;
            check_count(expected);
        end

        enable_i = 1'b0;
        repeat (3) begin
            @(posedge clk_i);
            #1;
            check_count(expected);
        end

        enable_i = 1'b1;
        repeat (5) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            #1;
            check_count(expected);
        end

        rst_ni = 1'b0;
        #1;
        check_count('0);

        $display("PASS: counter self-checking simulation completed.");
        $finish;
    end

endmodule

`default_nettype wire
