`timescale 1ns/1ps

module counter_tb;

    localparam time CLK_PERIOD = 10ns;

    logic       clk_i;
    logic       rst_ni;
    logic [7:0] count_o;

    logic [7:0] expected_count;
    int unsigned error_count;
    int unsigned check_count_total;

    counter dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .count_o (count_o)
    );

    // 100 MHz clock: 10 ns period.
    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    task automatic check_value(
        input logic [7:0] expected,
        input string      test_name
    );
        check_count_total++;

        if (count_o !== expected) begin
            $error(
                "[FAIL] t=%0t %-28s expected=0x%02h actual=0x%02h",
                $time, test_name, expected, count_o
            );
            error_count++;
        end else begin
            $display(
                "[PASS] t=%0t %-28s count=0x%02h",
                $time, test_name, count_o
            );
        end
    endtask

    task automatic wait_and_check_increment(input string test_name);
        @(posedge clk_i);
        expected_count = expected_count + 8'd1;
        #1;
        check_value(expected_count, test_name);
    endtask

    initial begin
        $dumpfile("waves/counter.fst");
        $dumpvars(0, counter_tb);

        rst_ni           = 1'b0;
        expected_count   = 8'h00;
        error_count      = 0;
        check_count_total = 0;

        $display("==================================================");
        $display(" Lab 2: Counter RTL Simulation and Verification");
        $display("==================================================");

        // Test 1: reset must clear and hold the counter at zero.
        repeat (3) begin
            @(posedge clk_i);
            #1;
            check_value(8'h00, "reset asserted");
        end

        // Release reset away from the active sampling edge.
        @(negedge clk_i);
        rst_ni = 1'b1;

        // Test 2: normal counting.
        repeat (10) begin
            wait_and_check_increment("normal increment");
        end

        // Test 3: reset while the counter is operating.
        @(negedge clk_i);
        rst_ni = 1'b0;

        @(posedge clk_i);
        expected_count = 8'h00;
        #1;
        check_value(expected_count, "reset during operation");

        // Hold reset for one more clock.
        @(posedge clk_i);
        #1;
        check_value(8'h00, "reset hold");

        @(negedge clk_i);
        rst_ni = 1'b1;

        // Test 4: exercise a complete 8-bit wraparound.
        // Starting at 0, 256 increments must return to 0.
        repeat (256) begin
            wait_and_check_increment("full-range / overflow");
        end

        // Test 5: verify counting continues after wraparound.
        repeat (4) begin
            wait_and_check_increment("post-overflow increment");
        end

        $display("--------------------------------------------------");
        $display("Checks executed : %0d", check_count_total);
        $display("Errors detected : %0d", error_count);

        if (error_count == 0) begin
            $display("LAB RESULT      : PASS");
            $display("--------------------------------------------------");
            $finish;
        end else begin
            $display("LAB RESULT      : FAIL");
            $display("--------------------------------------------------");
            $fatal(1, "Counter verification failed");
        end
    end

endmodule
