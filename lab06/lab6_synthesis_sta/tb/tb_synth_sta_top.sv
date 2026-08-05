`timescale 1ns/1ps
`default_nettype none

module tb_synth_sta_top;

    localparam int unsigned DATA_WIDTH = 8;
    localparam int unsigned ACC_WIDTH  = 24;
    localparam time CLK_PERIOD = 10ns;

    logic                  clk_i;
    logic                  rst_ni;
    logic                  valid_i;
    logic [DATA_WIDTH-1:0] a_i;
    logic [DATA_WIDTH-1:0] b_i;
    logic                  valid_o;
    logic [ACC_WIDTH-1:0]  result_o;

    logic [ACC_WIDTH-1:0] expected_acc;
    logic [ACC_WIDTH-1:0] expected_queue[$];

    int unsigned checks;
    int unsigned errors;

    synth_sta_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) dut (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .valid_i  (valid_i),
        .a_i      (a_i),
        .b_i      (b_i),
        .valid_o  (valid_o),
        .result_o (result_o)
    );

    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    task automatic drive(
        input logic                  v,
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b
    );
        @(negedge clk_i);
        valid_i = v;
        a_i     = a;
        b_i     = b;
    endtask

    /*
     * Reference model:
     * - Update the accumulated expected value whenever valid_i is sampled.
     * - Push each expected output transaction into a FIFO queue.
     * - Compare the oldest expected value whenever valid_o is asserted.
     */
    always @(posedge clk_i or negedge rst_ni) begin : scoreboard
        logic [(2*DATA_WIDTH)-1:0] product;
        logic [ACC_WIDTH-1:0]      extended_product;
        logic [ACC_WIDTH-1:0]      next_expected;
        logic [ACC_WIDTH-1:0]      expected_result;

        if (!rst_ni) begin
            expected_acc = '0;
            expected_queue.delete();
            checks = 0;
            errors = 0;
        end else begin
            if (valid_i) begin
                product = a_i * b_i;
                extended_product = {{(ACC_WIDTH-(2*DATA_WIDTH)){1'b0}}, product};
                next_expected = expected_acc + extended_product;

                expected_acc = next_expected;
                expected_queue.push_back(next_expected);

                $display(
                    "[%0t] INPUT : a=%0d b=%0d queued_expected=%0d",
                    $time, a_i, b_i, next_expected
                );
            end

            /*
             * Allow DUT nonblocking assignments at this rising edge
             * to update valid_o and result_o before checking them.
             */
            #1ps;

            if (valid_o) begin
                checks = checks + 1;

                if (expected_queue.size() == 0) begin
                    $error(
                        "Unexpected valid_o at %0t: result_o=%0d",
                        $time, result_o
                    );
                    errors = errors + 1;
                end else begin
                    expected_result = expected_queue.pop_front();

                    if (result_o !== expected_result) begin
                        $error(
                            "Mismatch at %0t: result_o=%0d expected=%0d",
                            $time, result_o, expected_result
                        );
                        errors = errors + 1;
                    end else begin
                        $display(
                            "[%0t] OUTPUT: result_o=%0d expected=%0d PASS",
                            $time, result_o, expected_result
                        );
                    end
                end
            end
        end
    end

    initial begin
        rst_ni       = 1'b0;
        valid_i      = 1'b0;
        a_i          = '0;
        b_i          = '0;
        expected_acc = '0;
        checks       = 0;
        errors       = 0;

        repeat (3) @(negedge clk_i);
        rst_ni = 1'b1;

        drive(1'b1, 8'd3,  8'd4);   // +12       = 12
        drive(1'b1, 8'd5,  8'd6);   // +30       = 42
        drive(1'b0, 8'd0,  8'd0);
        drive(1'b1, 8'd10, 8'd7);   // +70       = 112
        drive(1'b1, 8'd2,  8'd9);   // +18       = 130

        // Stop issuing transactions and drain the DUT pipeline.
        drive(1'b0, 8'd0, 8'd0);
        repeat (6) @(posedge clk_i);
        #1ns;

        if (expected_queue.size() != 0) begin
            $error(
                "Simulation ended with %0d expected transaction(s) pending",
                expected_queue.size()
            );
            errors = errors + 1;
        end

        if ((errors == 0) && (checks == 4)) begin
            $display("PASS: %0d output transactions checked", checks);
        end else begin
            $fatal(
                1,
                "FAIL: checks=%0d errors=%0d pending=%0d",
                checks, errors, expected_queue.size()
            );
        end

        $finish;
    end

    initial begin
        $dumpfile("build/lab6.vcd");
        $dumpvars(0, tb_synth_sta_top);
    end

endmodule

`default_nettype wire
