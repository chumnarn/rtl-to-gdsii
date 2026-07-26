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
    int unsigned checks;
    int unsigned errors;

    synth_sta_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) dut (
        .clk_i,
        .rst_ni,
        .valid_i,
        .a_i,
        .b_i,
        .valid_o,
        .result_o
    );

    initial clk_i = 1'b0;
    always #(CLK_PERIOD/2) clk_i = ~clk_i;

    task automatic drive(input logic v,
                         input logic [DATA_WIDTH-1:0] a,
                         input logic [DATA_WIDTH-1:0] b);
        @(negedge clk_i);
        valid_i <= v;
        a_i     <= a;
        b_i     <= b;
    endtask

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            expected_acc <= '0;
            checks       <= 0;
            errors       <= 0;
        end else if (valid_o) begin
            checks <= checks + 1;
            if (result_o !== expected_acc) begin
                $error("Mismatch at %0t: result_o=%0d expected=%0d",
                       $time, result_o, expected_acc);
                errors <= errors + 1;
            end
        end
    end

    // Update the reference model when the DUT accepts an input transaction.
    // DUT output becomes valid two rising edges after valid_i is sampled.
    always @(posedge clk_i) begin
        if (rst_ni && valid_i)
            expected_acc <= expected_acc + (a_i * b_i);
    end

    initial begin
        rst_ni  = 1'b0;
        valid_i = 1'b0;
        a_i     = '0;
        b_i     = '0;
        expected_acc = '0;
        checks  = 0;
        errors  = 0;

        repeat (3) @(negedge clk_i);
        rst_ni <= 1'b1;

        drive(1'b1, 8'd3,  8'd4);   // +12
        drive(1'b1, 8'd5,  8'd6);   // +30 => 42
        drive(1'b0, 8'd0,  8'd0);
        drive(1'b1, 8'd10, 8'd7);   // +70 => 112
        drive(1'b1, 8'd2,  8'd9);   // +18 => 130
        drive(1'b0, 8'd0,  8'd0);
        drive(1'b0, 8'd0,  8'd0);
        drive(1'b0, 8'd0,  8'd0);

        repeat (2) @(posedge clk_i);

        if (errors == 0 && checks == 4)
            $display("PASS: %0d output transactions checked", checks);
        else
            $fatal(1, "FAIL: checks=%0d errors=%0d", checks, errors);

        $finish;
    end

    initial begin
        $dumpfile("build/lab6.vcd");
        $dumpvars(0, tb_synth_sta_top);
    end

endmodule

`default_nettype wire
