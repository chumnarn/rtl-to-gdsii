`timescale 1ns/1ps
`default_nettype none

module tb_lab4_counter;
    localparam int unsigned WIDTH      = 8;
    localparam time         CLK_PERIOD = 20ns;

    logic                 clk_i;
    logic                 rst_ni;
    logic                 enable_i;
    logic                 load_i;
    logic                 up_i;
    logic [WIDTH-1:0]     data_i;
    logic [WIDTH-1:0]     count_o;
    logic                 carry_o;

    logic [WIDTH-1:0] expected_count;
    int unsigned      error_count;

    lab4_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (enable_i),
        .load_i   (load_i),
        .up_i     (up_i),
        .data_i   (data_i),
        .count_o  (count_o),
        .carry_o  (carry_o)
    );

    initial clk_i = 1'b0;
    always #(CLK_PERIOD / 2) clk_i = ~clk_i;

    task automatic check_count(input logic [WIDTH-1:0] expected);
        @(negedge clk_i);
        if (count_o !== expected) begin
            $error("count_o mismatch: expected=0x%0h actual=0x%0h time=%0t",
                   expected, count_o, $time);
            error_count++;
        end
    endtask

    task automatic apply_reset;
        rst_ni   = 1'b0;
        enable_i = 1'b0;
        load_i   = 1'b0;
        up_i     = 1'b1;
        data_i   = '0;
        repeat (3) @(posedge clk_i);
        rst_ni = 1'b1;
        check_count('0);
    endtask

    initial begin
        $dumpfile("reports/lab4_counter.vcd");
        $dumpvars(0, tb_lab4_counter);

        error_count   = 0;
        expected_count = '0;
        apply_reset();

        // Load a known value.
        @(negedge clk_i);
        data_i = 8'h3C;
        load_i = 1'b1;
        @(posedge clk_i);
        load_i = 1'b0;
        expected_count = 8'h3C;
        check_count(expected_count);

        // Count upward five cycles.
        enable_i = 1'b1;
        up_i     = 1'b1;
        repeat (5) begin
            @(posedge clk_i);
            expected_count++;
            check_count(expected_count);
        end

        // Hold value while disabled.
        enable_i = 1'b0;
        repeat (3) begin
            @(posedge clk_i);
            check_count(expected_count);
        end

        // Count downward four cycles.
        enable_i = 1'b1;
        up_i     = 1'b0;
        repeat (4) begin
            @(posedge clk_i);
            expected_count--;
            check_count(expected_count);
        end

        // Verify upward overflow and carry pulse.
        @(negedge clk_i);
        data_i = 8'hFF;
        load_i = 1'b1;
        @(posedge clk_i);
        load_i = 1'b0;
        check_count(8'hFF);

        enable_i = 1'b1;
        up_i     = 1'b1;
        @(posedge clk_i);
        check_count(8'h00);
        if (carry_o !== 1'b1) begin
            $error("carry_o must pulse on upward overflow");
            error_count++;
        end

        // Verify downward underflow and carry pulse.
        up_i = 1'b0;
        @(posedge clk_i);
        check_count(8'hFF);
        if (carry_o !== 1'b1) begin
            $error("carry_o must pulse on downward underflow");
            error_count++;
        end

        if (error_count == 0) begin
            $display("LAB4 TEST PASS");
            $finish;
        end

        $fatal(1, "LAB4 TEST FAIL: %0d error(s)", error_count);
    end
endmodule

`default_nettype wire
