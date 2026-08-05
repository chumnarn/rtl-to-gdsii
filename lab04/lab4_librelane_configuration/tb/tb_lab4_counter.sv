`timescale 1ns/1ps

module tb_lab4_counter;

    localparam int WIDTH = 8;
    localparam time CLK_PERIOD = 10ns;

    logic clk_i;
    logic rst_ni;
    logic en_i;
    logic [WIDTH-1:0] count_o;

    lab4_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .en_i    (en_i),
        .count_o (count_o)
    );

    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    always @(posedge clk_i) begin
        $display(
            "[%0t] rst_ni=%b en_i=%b count_o=0x%0h",
            $time,
            rst_ni,
            en_i,
            count_o
        );
    end

    task automatic check_count(
        input logic [WIDTH-1:0] expected
    );
        if (count_o !== expected) begin
            $fatal(
                1,
                "count_o mismatch: expected=0x%0h actual=0x%0h time=%0t",
                expected,
                count_o,
                $time
            );
        end
    endtask

    initial begin
        rst_ni = 1'b0;
        en_i   = 1'b0;

        // Hold active-low reset for several clock cycles.
        repeat (4) @(posedge clk_i);

        // Change control signals away from posedge to avoid races.
        @(negedge clk_i);
        rst_ni = 1'b1;

        @(negedge clk_i);
        en_i = 1'b1;

        repeat (60) @(posedge clk_i);

        // Disable after the 60th count event.
        @(negedge clk_i);
        en_i = 1'b0;

        // Allow nonblocking assignment updates to settle.
        #1ns;
        check_count(8'h3c);

        $display(
            "PASS: expected=0x3c actual=0x%0h time=%0t",
            count_o,
            $time
        );

        $finish;
    end

    initial begin
        $dumpfile("build/lab4_counter.vcd");
        $dumpvars(0, tb_lab4_counter);
    end

endmodule
