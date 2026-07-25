`default_nettype none

module macro_wrapper (
`ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
`endif
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    input  wire       load_i,
    input  wire [7:0] load_data_i,
    output wire [7:0] count_o,
    output wire       terminal_o,
    output wire       heartbeat_o
);

    reg heartbeat_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            heartbeat_q <= 1'b0;
        else if (terminal_o)
            heartbeat_q <= ~heartbeat_q;
    end

    assign heartbeat_o = heartbeat_q;

    counter_macro u_counter_macro (
`ifdef USE_POWER_PINS
        .VDD        (VDD),
        .VSS        (VSS),
`endif
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .en_i       (en_i),
        .load_i     (load_i),
        .load_data_i(load_data_i),
        .count_o    (count_o),
        .terminal_o (terminal_o)
    );

endmodule

`default_nettype wire
