`timescale 1ns/1ps
`default_nettype none

module tb_counter;

    localparam int unsigned WIDTH = 8;
    localparam time CLK_PERIOD = 20ns;

    logic clk;
    logic rst_n;
    logic enable;
    logic [WIDTH-1:0] count;
    logic [WIDTH-1:0] expected_count;

    counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .count  (count)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task automatic check_count(input logic [WIDTH-1:0] expected);
        #1ns;
        assert (count === expected)
            else $fatal(1, "count mismatch: expected=%0d actual=%0d time=%0t",
                        expected, count, $time);
    endtask

    initial begin
        $dumpfile("build/counter.vcd");
        $dumpvars(0, tb_counter);

        rst_n = 1'b0;
        enable = 1'b0;
        expected_count = '0;

        repeat (2) @(posedge clk);
        check_count('0);

        @(negedge clk);
        rst_n = 1'b1;
        enable = 1'b1;

        repeat (10) begin
            @(posedge clk);
            expected_count = expected_count + 1'b1;
            check_count(expected_count);
        end

        @(negedge clk);
        enable = 1'b0;

        repeat (3) begin
            @(posedge clk);
            check_count(expected_count);
        end

        @(negedge clk);
        enable = 1'b1;

        repeat (5) begin
            @(posedge clk);
            expected_count = expected_count + 1'b1;
            check_count(expected_count);
        end

        // Verify asynchronous reset.
        #3ns;
        rst_n = 1'b0;
        #1ns;
        check_count('0);

        $display("PASS: counter RTL simulation completed successfully.");
        $finish;
    end

    initial begin
        #2000ns;
        $fatal(1, "Timeout: simulation did not finish.");
    end

endmodule

`default_nettype wire
