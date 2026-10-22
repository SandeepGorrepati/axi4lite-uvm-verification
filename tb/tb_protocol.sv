`timescale 1ns/1ps
// Free Icarus test of the real DUT; this is separate from the UVM environment.
module tb_protocol;
  reg aclk=0, aresetn=0;
  always #5 aclk=~aclk;
  reg [31:0] awaddr=0,wdata=0,araddr=0;
  reg [3:0] wstrb=0;
  reg awvalid=0,wvalid=0,bready=0,arvalid=0,rready=0;
  wire awready,wready,bvalid,arready,rvalid;
  wire [1:0] bresp,rresp;
  wire [31:0] rdata;
  axi4lite_slave dut(.*);
  task automatic send_aw(input [31:0] a,input integer delay_cycles);
    repeat(delay_cycles) @(negedge aclk);
    @(negedge aclk); awaddr=a; awvalid=1;
    do @(posedge aclk); while(!awready);
    @(negedge aclk); awvalid=0;
  endtask
  task automatic send_w(input [31:0] d,input [3:0] s,input integer delay_cycles);
    repeat(delay_cycles) @(negedge aclk);
    @(negedge aclk); wdata=d; wstrb=s; wvalid=1;
    do @(posedge aclk); while(!wready);
    @(negedge aclk); wvalid=0;
  endtask
  task automatic write_word(input [31:0] a,d,input [3:0] s,input integer ad,wd,bh,input [1:0] exp);
    fork send_aw(a,ad); send_w(d,s,wd); join
    wait(bvalid); @(negedge aclk);
    repeat(bh) begin
      if(bvalid !== 1 || bresp !== exp) $fatal(1,"B response/stability addr=%h",a);
      @(negedge aclk);
    end
    if(bvalid !== 1 || bresp !== exp) $fatal(1,"B response addr=%h",a);
    bready=1; @(negedge aclk); bready=0;
  endtask
  task automatic read_word(input [31:0] a,exp,input integer rh,input [1:0] er);
    @(negedge aclk); araddr=a; arvalid=1;
    do @(posedge aclk); while(!arready);
    @(negedge aclk); arvalid=0;
    wait(rvalid); @(negedge aclk);
    repeat(rh) begin
      if(rvalid !== 1 || rresp !== er || rdata !== exp)
        $fatal(1,"R response/stability addr=%h got=%h expected=%h",a,rdata,exp);
      @(negedge aclk);
    end
    if(rvalid !== 1 || rresp !== er || rdata !== exp)
      $fatal(1,"R response addr=%h got=%h expected=%h",a,rdata,exp);
    rready=1; @(negedge aclk); rready=0;
  endtask
  integer f,rc,n=0,ad,wd,bh,rh,br,rr;
  reg [31:0] a,d,s,ra,exp;
  initial begin
    repeat(3) @(negedge aclk); aresetn=1;
    f=$fopen("build/vectors.txt","r");
    if(!f) $fatal(1,"missing oracle vectors");
    while(!$feof(f)) begin
      rc=$fscanf(f,"%h %h %h %h %h %h %h %h %h %h %h\n",a,d,s,ad,wd,bh,rh,ra,exp,br,rr);
      if(rc != 11) $fatal(1,"malformed vector %0d",n);
      write_word(a,d,s[3:0],ad,wd,bh,br[1:0]);
      read_word(ra,exp,rh,rr[1:0]); n=n+1;
    end
    $fclose(f);
    // Reset cancels a partial write; no orphan response may appear.
    send_aw(0,0);
    aresetn=0; repeat(3) @(negedge aclk); aresetn=1;
    repeat(8) begin @(negedge aclk); if(bvalid || rvalid) $fatal(1,"orphan response after reset"); end
    write_word(0,32'h12345678,15,0,0,4,0);
    read_word(0,32'h12345678,4,0);
    $display("PASS: %0d oracle write/read pairs; AW/W skew, 16 strobes, backpressure, DECERR, alias protection, reset",n);
    $finish;
  end
  initial begin #2000000; $fatal(1,"protocol regression watchdog"); end
endmodule
