//==============================================================================
// axi4lite_if.sv
// AXI4-Lite interface + bound protocol assertions (SVA).
//==============================================================================
`timescale 1ns/1ps

interface axi4lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
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
    // SVA — concurrent protocol assertions
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

    // 5. No spurious responses: BVALID only after an accepted AW and W
    //    (bounded liveness: every accepted write eventually produces BVALID)
    A_WRITE_GETS_BRESP : assert property
        ((awvalid && awready) ##[1:$] (bvalid && bready))
        else $error("[SVA] Accepted write never produced a BVALID/BREADY");

    // 6. Every accepted read address eventually returns read data
    A_READ_GETS_RDATA : assert property
        ((arvalid && arready) |-> ##[1:$] (rvalid))
        else $error("[SVA] Accepted read never produced RVALID");
    // synopsys translate_on

endinterface
