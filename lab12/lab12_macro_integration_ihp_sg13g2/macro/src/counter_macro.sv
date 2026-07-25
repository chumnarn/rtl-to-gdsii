`default_nettype none

module counter_macro (
`ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
`endif
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    input  wire       load_i,
    input  wire [7:0] load_data_i,
    output reg  [7:0] count_o,
    output wire       terminal_o
);

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o <= 8'h00;
        end else if (load_i) begin
            count_o <= load_data_i;
        end else if (en_i) begin
            count_o <= count_o + 8'h01;
        end
    end

    assign terminal_o = &count_o;

endmodule

`default_nettype wire
