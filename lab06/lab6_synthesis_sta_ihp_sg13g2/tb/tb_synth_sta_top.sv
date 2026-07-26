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

    logic [ACC_WIDTH-1:0] expected_accumulator;
    int unsigned sent_count;
    int unsigned recv_count;
    int unsigned error_count;

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

    task automatic send_sample(
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b
    );
        begin
            @(negedge clk_i);
            valid_i = 1'b1;
            a_i     = a;
            b_i     = b;
            sent_count++;
        end
    endtask

    task automatic send_idle();
        begin
            @(negedge clk_i);
            valid_i = 1'b0;
            a_i     = '0;
            b_i     = '0;
        end
    endtask

    always @(posedge clk_i) begin
        logic [ACC_WIDTH-1:0] expected_next;

        if (!rst_ni) begin
            expected_accumulator <= '0;
            recv_count           <= 0;
            error_count          <= 0;
        end else if (dut.valid_q) begin
            expected_next = expected_accumulator +
                            (ACC_WIDTH'(dut.a_q) * ACC_WIDTH'(dut.b_q));
            expected_accumulator <= expected_next;

            #1ps;
            recv_count <= recv_count + 1;

            if (!valid_o) begin
                $error("valid_o was low for expected result %0d", expected_next);
                error_count <= error_count + 1;
            end else if (result_o !== expected_next) begin
                $error("Mismatch: expected=%0d actual=%0d",
                       expected_next, result_o);
                error_count <= error_count + 1;
            end else begin
                $display("[%0t] PASS result=%0d", $time, result_o);
            end
        end
    end

    initial begin
        $dumpfile("build/tb_synth_sta_top.vcd");
        $dumpvars(0, tb_synth_sta_top);

        rst_ni     = 1'b0;
        valid_i    = 1'b0;
        a_i        = '0;
        b_i        = '0;
        sent_count = 0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_ni = 1'b1;

        send_sample(8'd3,   8'd4);
        send_sample(8'd7,   8'd9);
        send_idle();
        send_sample(8'd12,  8'd11);
        send_sample(8'd255, 8'd2);
        send_idle();
        send_idle();
        send_idle();

        repeat (3) @(posedge clk_i);

        if (recv_count != sent_count) begin
            $fatal(1, "Transaction count mismatch: sent=%0d received=%0d",
                   sent_count, recv_count);
        end

        if (error_count != 0) begin
            $fatal(1, "FAIL: %0d errors", error_count);
        end

        $display("PASS: %0d output transactions checked", recv_count);
        $finish;
    end

    initial begin
        #2000ns;
        $fatal(1, "Simulation timeout");
    end

endmodule

`default_nettype wire
