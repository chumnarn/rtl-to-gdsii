`default_nettype none

(* blackbox *)
module counter_macro (
`ifdef USE_POWER_PINS
    inout wire VPWR,
    inout wire VGND,
`endif
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    input  wire       load_i,
    input  wire [7:0] load_data_i,
    output wire [7:0] count_o,
    output wire       terminal_o
);

endmodule

`default_nettype wire
