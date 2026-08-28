`timescale 1ns/1ps
`default_nettype none

module tb_routing_demo;

localparam int unsigned WIDTH      = 32;
localparam time         CLK_PERIOD = 10ns;

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

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
end

task automatic check_outputs(
    input string test_name
);
    #1ns;

    if (count !== expected_count) begin
        $fatal(
            1,
            "%s: count=%08h expected=%08h",
            test_name,
            count,
            expected_count
        );
    end

    if (terminal_count !== (&expected_count)) begin
        $fatal(
            1,
            "%s: terminal_count=%b expected=%b",
            test_name,
            terminal_count,
            &expected_count
        );
    end

    if (parity !== (^expected_count)) begin
        $fatal(
            1,
            "%s: parity=%b expected=%b",
            test_name,
            parity,
            ^expected_count
        );
    end
endtask

task automatic apply_load(
    input logic [WIDTH-1:0] value,
    input string            test_name
);
    @(negedge clk);
    enable    = 1'b0;
    load      = 1'b1;
    load_data = value;

    @(posedge clk);
    expected_count = value;
    check_outputs(test_name);

    @(negedge clk);
    load = 1'b0;
endtask

task automatic increment_once(
    input string test_name
);
    @(negedge clk);
    load   = 1'b0;
    enable = 1'b1;

    @(posedge clk);
    expected_count = expected_count + {{(WIDTH-1){1'b0}}, 1'b1};
    check_outputs(test_name);
endtask

initial begin
    rst_n          = 1'b0;
    enable         = 1'b0;
    load           = 1'b0;
    load_data      = '0;
    expected_count = '0;

    // Hold asynchronous active-low reset.
    repeat (3) @(posedge clk);

    // Release reset away from the active clock edge.
    @(negedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    check_outputs("reset release");

    // Parallel load.
    apply_load(
        32'h1234_5678,
        "parallel load"
    );

    // Increment ten times.
    repeat (10) begin
        increment_once("increment");
    end

    // Hold the current value for three cycles.
    @(negedge clk);
    enable = 1'b0;
    load   = 1'b0;

    repeat (3) begin
        @(posedge clk);
        check_outputs("hold");
    end

    // Load the maximum value.
    apply_load(
        {WIDTH{1'b1}},
        "terminal count"
    );

    // Increment once and verify wraparound.
    increment_once("wrap around");

    @(negedge clk);
    enable = 1'b0;

    $display(
        "PASS: routing_demo self-checking simulation completed."
    );
    $display(
        "Final count=0x%08h terminal_count=%b parity=%b",
        count,
        terminal_count,
        parity
    );

    $finish;
end

initial begin
    $dumpfile("build/routing_demo.vcd");
    $dumpvars(0, tb_routing_demo);
end

initial begin
    #2000ns;
    $fatal(1, "Simulation timeout");
end

endmodule

`default_nettype wire
