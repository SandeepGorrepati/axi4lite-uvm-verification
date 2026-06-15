//==============================================================================
// axi4lite_slave.sv
// Simple AXI4-Lite slave with an internal word-addressable memory.
//
// - 32-bit data, 32-bit address (only ADDR_LSB+MEM_AW bits decoded)
// - Independent AW / W acceptance, single outstanding response
// - Always returns OKAY (2'b00) response
// - Byte-enables (WSTRB) honored on writes
//
// Intentionally simple and spec-clean so it is a good DUT for a UVM testbench:
// every handshake is observable, every write is read-backable.
//==============================================================================
`timescale 1ns/1ps

module axi4lite_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORDS  = 256          // 256 x 32-bit words
)(
    input  logic                    aclk,
    input  logic                    aresetn,   // active-low reset

    // Write address channel
    input  logic [ADDR_WIDTH-1:0]   awaddr,
    input  logic                    awvalid,
    output logic                    awready,

    // Write data channel
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic [DATA_WIDTH/8-1:0] wstrb,
    input  logic                    wvalid,
    output logic                    wready,

    // Write response channel
    output logic [1:0]              bresp,
    output logic                    bvalid,
    input  logic                    bready,

    // Read address channel
    input  logic [ADDR_WIDTH-1:0]   araddr,
    input  logic                    arvalid,
    output logic                    arready,

    // Read data channel
    output logic [DATA_WIDTH-1:0]   rdata,
    output logic [1:0]              rresp,
    output logic                    rvalid,
    input  logic                    rready
);

    localparam int ADDR_LSB = $clog2(DATA_WIDTH/8);          // byte offset bits
    localparam int MEM_AW   = $clog2(MEM_WORDS);             // word index bits
    localparam logic [1:0] RESP_OKAY = 2'b00;

    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    // Latched write address / data when the two channels arrive separately
    logic [ADDR_WIDTH-1:0] awaddr_q;
    logic                  aw_hs_q;     // write-address captured, awaiting data
    logic [DATA_WIDTH-1:0] wdata_q;
    logic [DATA_WIDTH/8-1:0] wstrb_q;
    logic                  w_hs_q;      // write-data captured, awaiting address

    function automatic [MEM_AW-1:0] word_index(input logic [ADDR_WIDTH-1:0] a);
        word_index = a[ADDR_LSB +: MEM_AW];
    endfunction

    //--------------------------------------------------------------------------
    // Write address channel handshake
    //--------------------------------------------------------------------------
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready  <= 1'b0;
            awaddr_q <= '0;
            aw_hs_q  <= 1'b0;
        end else begin
            // Accept a new write address when we are not already holding one
            if (awvalid && !awready && !aw_hs_q) begin
                awready  <= 1'b1;
                awaddr_q <= awaddr;
            end else begin
                awready  <= 1'b0;
            end

            // Track that an address handshake has occurred and is pending data
            if (awvalid && awready)
                aw_hs_q <= 1'b1;
            else if (do_write)
                aw_hs_q <= 1'b0;
        end
    end

    //--------------------------------------------------------------------------
    // Write data channel handshake
    //--------------------------------------------------------------------------
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wready  <= 1'b0;
            wdata_q <= '0;
            wstrb_q <= '0;
            w_hs_q  <= 1'b0;
        end else begin
            if (wvalid && !wready && !w_hs_q) begin
                wready  <= 1'b1;
                wdata_q <= wdata;
                wstrb_q <= wstrb;
            end else begin
                wready  <= 1'b0;
            end

            if (wvalid && wready)
                w_hs_q <= 1'b1;
            else if (do_write)
                w_hs_q <= 1'b0;
        end
    end

    // A write commits once both address and data have been captured
    wire do_write = aw_hs_q && w_hs_q && !bvalid;

    //--------------------------------------------------------------------------
    // Memory write with byte strobes + write response channel
    //--------------------------------------------------------------------------
    integer b;
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
            bresp  <= RESP_OKAY;
        end else begin
            if (do_write) begin
`ifdef INJECT_WSTRB_BUG
                // -------- DELIBERATE BUG (enable with +define+INJECT_WSTRB_BUG) --------
                // Ignores WSTRB and writes the full 32-bit word on every write.
                // A partial-strobe write should only update selected bytes; this
                // corrupts the others. The scoreboard's reference model honors
                // WSTRB, so the byte-strobe directed test produces a READ MISMATCH,
                // and you can see exactly which bytes differ. Demonstrates the
                // testbench actually catches a real RTL bug. See README "Bug Injection".
                mem[word_index(awaddr_q)] <= wdata_q;
`else
                for (b = 0; b < DATA_WIDTH/8; b++) begin
                    if (wstrb_q[b])
                        mem[word_index(awaddr_q)][b*8 +: 8] <= wdata_q[b*8 +: 8];
                end
`endif
                bvalid <= 1'b1;
                bresp  <= RESP_OKAY;
            end else if (bvalid && bready) begin
                bvalid <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Read address + read data channels
    //--------------------------------------------------------------------------
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            arready <= 1'b0;
            rvalid  <= 1'b0;
            rdata   <= '0;
            rresp   <= RESP_OKAY;
        end else begin
            // Accept a read address when not currently returning data
            if (arvalid && !arready && !rvalid) begin
                arready <= 1'b1;
                rdata   <= mem[word_index(araddr)];
                rresp   <= RESP_OKAY;
            end else begin
                arready <= 1'b0;
            end

            // Present read data one cycle after address handshake
            if (arvalid && arready)
                rvalid <= 1'b1;
            else if (rvalid && rready)
                rvalid <= 1'b0;
        end
    end

endmodule
