`timescale 1ns/1ps
`default_nettype none

module tb_floorplan_demo;

    localparam integer WIDTH = 8;

    reg                  clk;
    reg                  rst_n;
    reg                  enable_i;
    reg                  load_i;
    reg  [WIDTH-1:0]     data_i;
    wire [WIDTH-1:0]     count_o;
    wire                 terminal_o;

    integer errors;

    floorplan_demo #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable_i(enable_i),
        .load_i(load_i),
        .data_i(data_i),
        .count_o(count_o),
        .terminal_o(terminal_o)
    );

    always #5 clk = ~clk;

    task check;
        input [WIDTH-1:0] expected_count;
        input             expected_terminal;
        input [255:0]     test_name;
        begin
            #1;
            if ((count_o !== expected_count) ||
                (terminal_o !== expected_terminal)) begin
                $display("FAIL: %0s count=%02x expected=%02x terminal=%b expected=%b",
                         test_name, count_o, expected_count,
                         terminal_o, expected_terminal);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("build/floorplan_demo.vcd");
        $dumpvars(0, tb_floorplan_demo);

        clk      = 1'b0;
        rst_n    = 1'b0;
        enable_i = 1'b0;
        load_i   = 1'b0;
        data_i   = 8'h00;
        errors   = 0;

        #2;
        check(8'h00, 1'b0, "asynchronous reset");

        @(negedge clk);
        rst_n  = 1'b1;
        load_i = 1'b1;
        data_i = 8'hFC;

        @(posedge clk);
        check(8'hFC, 1'b0, "parallel load");

        @(negedge clk);
        load_i   = 1'b0;
        enable_i = 1'b1;

        @(posedge clk);
        check(8'hFD, 1'b0, "count FD");

        @(posedge clk);
        check(8'hFE, 1'b0, "count FE");

        @(posedge clk);
        check(8'hFF, 1'b1, "terminal count");

        @(posedge clk);
        check(8'h00, 1'b0, "wrap around");

        @(negedge clk);
        enable_i = 1'b0;

        @(posedge clk);
        check(8'h00, 1'b0, "hold");

        rst_n = 1'b0;
        #1;
        check(8'h00, 1'b0, "reset assertion");

        if (errors == 0) begin
            $display("======================================");
            $display("LAB 5 RTL SIMULATION PASSED");
            $display("======================================");
            $finish;
        end else begin
            $display("LAB 5 FAILED: %0d error(s)", errors);
            $finish_and_return(1);
        end
    end

endmodule

`default_nettype wire
