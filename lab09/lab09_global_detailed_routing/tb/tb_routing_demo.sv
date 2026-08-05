`timescale 1ns/1ps
`default_nettype none

module tb_routing_demo;
    localparam int unsigned WIDTH = 32;

    logic             clk;
    logic             rst_n;
    logic             enable;
    logic             load;
    logic [WIDTH-1:0] load_data;
    logic [WIDTH-1:0] count;
    logic             terminal_count;
    logic             parity;

    logic [WIDTH-1:0] expected_count;

    routing_demo #(
        .WIDTH(WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .enable         (enable),
        .load           (load),
        .load_data      (load_data),
        .count          (count),
        .terminal_count (terminal_count),
        .parity         (parity)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_outputs(input string test_name);
        #1;
        if (count !== expected_count) begin
            $error("%s: count=%h expected=%h", test_name, count, expected_count);
            $fatal(1);
        end
        if (terminal_count !== (&expected_count)) begin
            $error("%s: terminal_count mismatch", test_name);
            $fatal(1);
        end
        if (parity !== (^expected_count)) begin
            $error("%s: parity mismatch", test_name);
            $fatal(1);
        end
    endtask

    initial begin
        rst_n          = 1'b0;
        enable         = 1'b0;
        load           = 1'b0;
        load_data      = '0;
        expected_count = '0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        check_outputs("reset release");

        load      = 1'b1;
        load_data = 32'h1234_5678;
        @(posedge clk);
        expected_count = 32'h1234_5678;
        load = 1'b0;
        check_outputs("parallel load");

        enable = 1'b1;
        repeat (10) begin
            @(posedge clk);
            expected_count = expected_count + 1'b1;
            check_outputs("increment");
        end

        enable = 1'b0;
        repeat (3) begin
            @(posedge clk);
            check_outputs("hold");
        end

        load      = 1'b1;
        load_data = '1;
        @(posedge clk);
        expected_count = '1;
        load = 1'b0;
        check_outputs("terminal count");

        enable = 1'b1;
        @(posedge clk);
        expected_count = '0;
        enable = 1'b0;
        check_outputs("wrap around");

        $display("PASS: routing_demo self-checking simulation completed.");
        $finish;
    end

endmodule

`default_nettype wire
