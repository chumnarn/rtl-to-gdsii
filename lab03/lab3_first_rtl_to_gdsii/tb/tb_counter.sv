`timescale 1ns/1ps
`default_nettype none

module tb_counter;
    localparam int unsigned WIDTH      = 8;
    localparam time         CLK_PERIOD = 10ns;

    logic             clk_i;
    logic             rst_ni;
    logic             en_i;
    logic [WIDTH-1:0] count_o;
    logic [WIDTH-1:0] expected;

    counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .en_i    (en_i),
        .count_o (count_o)
    );

    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic check_count(input logic [WIDTH-1:0] exp);
        @(negedge clk_i);
        if (count_o !== exp) begin
            $error("count mismatch: expected=0x%0h actual=0x%0h time=%0t",
                   exp, count_o, $time);
            $fatal(1);
        end
    endtask

    initial begin
        $dumpfile("waves/counter.vcd");
        $dumpvars(0, tb_counter);

        clk_i    = 1'b0;
        rst_ni   = 1'b0;
        en_i     = 1'b0;
        expected = '0;

        // Synchronous active-low reset.
        repeat (2) @(posedge clk_i);
        check_count('0);

        // Enable counting.
        rst_ni = 1'b1;
        en_i   = 1'b1;
        repeat (20) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check_count(expected);
        end

        // Hold the counter while disabled.
        en_i = 1'b0;
        repeat (4) begin
            @(posedge clk_i);
            check_count(expected);
        end

        // Resume counting.
        en_i = 1'b1;
        repeat (8) begin
            @(posedge clk_i);
            expected = expected + 1'b1;
            check_count(expected);
        end

        // Assert reset and verify clearing at the next rising edge.
        rst_ni = 1'b0;
        @(posedge clk_i);
        expected = '0;
        check_count(expected);

        $display("PASS: counter RTL simulation completed successfully");
        $finish;
    end

    initial begin
        #(200 * CLK_PERIOD);
        $fatal(1, "TIMEOUT: simulation did not finish");
    end
endmodule

`default_nettype wire
