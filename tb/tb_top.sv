//==============================================================================
// tb_top.sv
// Top-level: clock/reset generation, DUT + interface instantiation, run_test.
//==============================================================================
`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import axi4lite_pkg::*;

    logic aclk = 0;
    logic aresetn = 0;

    always #5 aclk = ~aclk;     // 100 MHz

    // Interface
    axi4lite_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) intf (.aclk(aclk), .aresetn(aresetn));

    // DUT
    axi4lite_slave #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .MEM_WORDS(256)) dut (
        .aclk    (aclk),
        .aresetn (aresetn),
        .awaddr  (intf.awaddr),  .awvalid (intf.awvalid), .awready (intf.awready),
        .wdata   (intf.wdata),   .wstrb   (intf.wstrb),   .wvalid  (intf.wvalid),
        .wready  (intf.wready),
        .bresp   (intf.bresp),   .bvalid  (intf.bvalid),  .bready  (intf.bready),
        .araddr  (intf.araddr),  .arvalid (intf.arvalid), .arready (intf.arready),
        .rdata   (intf.rdata),   .rresp   (intf.rresp),   .rvalid  (intf.rvalid),
        .rready  (intf.rready)
    );

    // Reset
    initial begin
        aresetn = 0;
        repeat (5) @(posedge aclk);
        aresetn = 1;
    end

    // Hand the interface to the UVM components and launch
    initial begin
        uvm_config_db#(virtual axi4lite_if)::set(null, "*", "vif", intf);
        // default test if +UVM_TESTNAME not supplied
        run_test("axi4lite_regression_test");
    end

    // Waveform dump (FSDB/VCD depending on tool)
    initial begin
        $dumpfile("axi4lite_uvm.vcd");
        $dumpvars(0, tb_top);
    end

    // Safety timeout
    initial begin
        #200000;
        `uvm_fatal("TB_TOP", "Global timeout reached")
    end
endmodule
