//==============================================================================
// axi4lite_resp_fv.sv
// A compact, FORMAL-FRIENDLY model of the AXI4-Lite slave's response + decode
// logic, written in plain synthesizable Verilog so it can be PROVEN (not just
// simulated) with SymbiYosys + Z3 (k-induction). It mirrors the response policy
// of rtl/axi4lite_slave.sv: in-range -> OKAY, out-of-range -> DECERR, single
// outstanding write response.
//==============================================================================
module axi4lite_resp_fv #(
    parameter ADDR_WIDTH = 16,
    parameter MEM_BYTES  = 1024
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  req,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  bready,
    output reg  [1:0]            bresp,
    output reg                   bvalid
);
    localparam [1:0] OKAY   = 2'b00;
    localparam [1:0] DECERR = 2'b11;
    initial bresp  = 2'b00;
    initial bvalid = 1'b0;
    wire in_range = (addr < MEM_BYTES);

    always @(posedge clk) begin
        if (rst) begin
            bvalid <= 1'b0; bresp <= OKAY;
        end else begin
            if (req && !bvalid) begin
                bvalid <= 1'b1; bresp <= in_range ? OKAY : DECERR;
            end else if (bvalid && bready) begin
                bvalid <= 1'b0;
            end
        end
    end

`ifdef FORMAL
    reg f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @(posedge clk) begin
        assert (bresp == OKAY || bresp == DECERR);                 // P1 legal resp
        if (f_past_valid && !$past(rst)) begin
            if (!$past(bvalid) && bvalid) assert ($past(req));     // P2 no spurious
            if ($past(req) && !$past(bvalid) && ($past(addr) <  MEM_BYTES) && bvalid)
                assert (bresp == OKAY);                            // P3 in-range OKAY
            if ($past(req) && !$past(bvalid) && ($past(addr) >= MEM_BYTES) && bvalid)
                assert (bresp == DECERR);                          // P4 oob DECERR
            if ($past(bvalid) && !$past(bready)) assert (bvalid);  // P5 stable handshake
        end
    end
`endif
endmodule
