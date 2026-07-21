`default_nettype none

module chip_top #(
    parameter int NUM_VDD_PADS   = 1,
    parameter int NUM_VSS_PADS   = 1,
    parameter int NUM_IOVDD_PADS = 1,
    parameter int NUM_IOVSS_PADS = 1
) (
`ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
`endif
    inout wire       clk_PAD,
    inout wire       rst_n_PAD,
    inout wire       enable_PAD,
    inout wire [7:0] count_PAD
);

    wire       clk_core;
    wire       rst_n_core;
    wire       enable_core;
    wire [7:0] count_core;

    // ------------------------------------------------------------
    // Core-domain and I/O-domain supply pads
    // ------------------------------------------------------------

    generate
        for (genvar i = 0; i < NUM_IOVDD_PADS; i++) begin : iovdd_pads
            (* keep *)
            sg13g2_IOPadIOVdd iovdd_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < NUM_IOVSS_PADS; i++) begin : iovss_pads
            (* keep *)
            sg13g2_IOPadIOVss iovss_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < NUM_VDD_PADS; i++) begin : vdd_pads
            (* keep *)
            sg13g2_IOPadVdd vdd_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end

        for (genvar i = 0; i < NUM_VSS_PADS; i++) begin : vss_pads
            (* keep *)
            sg13g2_IOPadVss vss_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end
    endgenerate

    // ------------------------------------------------------------
    // Input pads
    // ------------------------------------------------------------

    sg13g2_IOPadIn clk_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
        .p2c(clk_core),
        .pad(clk_PAD)
    );

    sg13g2_IOPadIn rst_n_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
        .p2c(rst_n_core),
        .pad(rst_n_PAD)
    );

    sg13g2_IOPadIn enable_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
        .p2c(enable_core),
        .pad(enable_PAD)
    );

    // ------------------------------------------------------------
    // Counter core
    // ------------------------------------------------------------

    counter_core #(.WIDTH(8)) i_counter_core (
        .clk_i    (clk_core),
        .rst_ni   (rst_n_core),
        .enable_i (enable_core),
        .count_o  (count_core)
    );

    // ------------------------------------------------------------
    // Output pads
    // ------------------------------------------------------------

    generate
        for (genvar i = 0; i < 8; i++) begin : outputs
            sg13g2_IOPadOut30mA output_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
                .c2p(count_core[i]),
                .pad(count_PAD[i])
            );
        end
    endgenerate

endmodule

`default_nettype wire
