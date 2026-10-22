//==============================================================================
// axi4lite_if.sv
// AXI4-Lite interface + bound protocol assertions (SVA).
//==============================================================================
`timescale 1ns/1ps

interface axi4lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MAX_RESPONSE_CYCLES = 32
)(input logic aclk, input logic aresetn);

    // Write address
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic                    awvalid;
    logic                    awready;
    // Write data
    logic [DATA_WIDTH-1:0]   wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;
    // Write response
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;
    // Read address
    logic [ADDR_WIDTH-1:0]   araddr;
    logic                    arvalid;
    logic                    arready;
    // Read data
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rvalid;
    logic                    rready;

    //--------------------------------------------------------------------------
    // Clocking block for the driver (drives master signals)
    //--------------------------------------------------------------------------
    clocking drv_cb @(posedge aclk);
        default input #1step output #1;
        output awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready;
        input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid;
    endclocking

    //--------------------------------------------------------------------------
    // Clocking block for the monitor (samples everything)
    //--------------------------------------------------------------------------
    clocking mon_cb @(posedge aclk);
        default input #1step;
        input awaddr, awvalid, awready, wdata, wstrb, wvalid, wready,
              bresp, bvalid, bready, araddr, arvalid, arready,
              rdata, rresp, rvalid, rready;
    endclocking

    modport DRV (clocking drv_cb, input aclk, input aresetn);
    modport MON (clocking mon_cb, input aclk, input aresetn);

    //==========================================================================
    // SVA â€” concurrent protocol assertions
    // These fire in any SVA-capable simulator (Questa / VCS / Xcelium).
    //==========================================================================
    // synopsys translate_off
    default clocking cb_assert @(posedge aclk); endclocking
    default disable iff (!aresetn);

    // 1. No unknown (X/Z) on control/data when VALID is asserted
    A_AWADDR_KNOWN : assert property (awvalid |-> !$isunknown(awaddr))
        else $error("[SVA] AWADDR is X/Z while AWVALID asserted");
    A_WDATA_KNOWN  : assert property (wvalid  |-> !$isunknown({wdata, wstrb}))
        else $error("[SVA] WDATA/WSTRB is X/Z while WVALID asserted");
    A_ARADDR_KNOWN : assert property (arvalid |-> !$isunknown(araddr))
        else $error("[SVA] ARADDR is X/Z while ARVALID asserted");

    // 2. VALID/payload must remain stable until the matching READY (no retraction)
    A_AW_STABLE : assert property
        (awvalid && !awready |=> awvalid && $stable(awaddr))
        else $error("[SVA] AW channel changed/dropped before AWREADY");
    A_W_STABLE  : assert property
        (wvalid && !wready |=> wvalid && $stable(wdata) && $stable(wstrb))
        else $error("[SVA] W channel changed/dropped before WREADY");
    A_AR_STABLE : assert property
        (arvalid && !arready |=> arvalid && $stable(araddr))
        else $error("[SVA] AR channel changed/dropped before ARREADY");

    // 3. Read data must be stable until accepted
    A_R_STABLE  : assert property
        (rvalid && !rready |=> rvalid && $stable(rdata) && $stable(rresp))
        else $error("[SVA] R channel changed/dropped before RREADY");

    // 4. Responses must be a LEGAL AXI4-Lite code for this slave: OKAY (in-range) or
    //    DECERR (out-of-range). SLVERR (2'b10) and the reserved code (2'b01) are illegal
    //    here, so +define+INJECT_BRESP_ERR (which forces SLVERR) still trips these.
    A_BRESP_LEGAL : assert property (bvalid |-> (bresp inside {2'b00, 2'b11}))
        else $error("[SVA] BRESP illegal (not OKAY/DECERR): %b", bresp);
    A_RRESP_LEGAL : assert property (rvalid |-> (rresp inside {2'b00, 2'b11}))
        else $error("[SVA] RRESP illegal (not OKAY/DECERR): %b", rresp);

    A_B_STABLE : assert property
        (bvalid && !bready |=> bvalid && $stable(bresp))
        else $error("[SVA] B channel changed/dropped before BREADY");

    // Collect independently accepted AW and W. Completion starts only after
    // both have arrived; BREADY is deliberately excluded from slave liveness.
    logic aw_seen, w_seen;
    wire aw_accept = awvalid && awready;
    wire w_accept = wvalid && wready;
    wire write_pair = (aw_seen || aw_accept) && (w_seen || w_accept);
    always_ff @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin aw_seen <= 0; w_seen <= 0; end
        else if(write_pair) begin aw_seen <= 0; w_seen <= 0; end
        else begin
            if(aw_accept) aw_seen <= 1;
            if(w_accept) w_seen <= 1;
        end
    end
    // These bounds are this DUT's verification contract, not AXI requirements.
    A_WRITE_GETS_BRESP : assert property
        (write_pair |-> ##[1:MAX_RESPONSE_CYCLES] bvalid)
        else $error("[SVA] Accepted AW/W pair exceeded response bound");
    A_READ_GETS_RDATA : assert property
        ((arvalid && arready) |-> ##[1:MAX_RESPONSE_CYCLES] rvalid)
        else $error("[SVA] Accepted read exceeded response bound");
    // synopsys translate_on

endinterface

