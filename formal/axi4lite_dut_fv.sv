// Bounded safety checks instantiate the actual slave, not a policy replica.
module axi4lite_dut_fv(input aclk);
  (* anyseq *) reg aresetn;
  (* anyseq *) reg [31:0] awaddr,wdata,araddr;
  (* anyseq *) reg [3:0] wstrb;
  (* anyseq *) reg awvalid,wvalid,bready,arvalid,rready;
  wire awready,wready,bvalid,arready,rvalid;
  wire [1:0] bresp,rresp;
  wire [31:0] rdata;
  // Reduced memory depth keeps bounded proofs inexpensive; RTL is unchanged.
  axi4lite_slave #(.MEM_WORDS(4)) dut(.*);
  reg past_valid=0;
  reg [5:0] aw_credit,w_credit,r_credit;
  always @(posedge aclk) begin
    past_valid <= 1;
    if(!past_valid) assume(!aresetn);
    if(!aresetn) begin aw_credit<=0; w_credit<=0; r_credit<=0; end
    else begin
      aw_credit <= aw_credit + (awvalid && awready) - (bvalid && bready);
      w_credit <= w_credit + (wvalid && wready) - (bvalid && bready);
      r_credit <= r_credit + (arvalid && arready) - (rvalid && rready);
      if(bvalid) begin
        assert(aw_credit>0); assert(w_credit>0);
        assert(bresp==0 || bresp==3);
      end
      if(rvalid) begin
        assert(r_credit>0);
        assert(rresp==0 || rresp==3);
      end
    end
    if(past_valid && $past(aresetn) && aresetn) begin
      // Only legal master persistence is assumed. READY may stall indefinitely.
      if($past(awvalid && !awready)) begin assume(awvalid); assume(awaddr==$past(awaddr)); end
      if($past(wvalid && !wready)) begin assume(wvalid); assume(wdata==$past(wdata)); assume(wstrb==$past(wstrb)); end
      if($past(arvalid && !arready)) begin assume(arvalid); assume(araddr==$past(araddr)); end
      if($past(bvalid && !bready)) begin assert(bvalid); assert(bresp==$past(bresp)); end
      if($past(rvalid && !rready)) begin assert(rvalid); assert(rdata==$past(rdata)); assert(rresp==$past(rresp)); end
    end
  end
endmodule
