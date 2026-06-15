//==============================================================================
// axi4lite_monitor.sv
// UVM monitor: observes completed AXI4-Lite transactions on the bus and
// broadcasts reconstructed transactions through an analysis port.
//==============================================================================
class axi4lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi4lite_monitor)

    virtual axi4lite_if vif;
    uvm_analysis_port #(axi4lite_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set for monitor")
    endfunction

    task run_phase(uvm_phase phase);
        @(posedge vif.aresetn);
        fork
            monitor_writes();
            monitor_reads();
        join
    endtask

    //--------------------------------------------------------------------------
    // Reconstruct a write from the AW + W handshakes, publish at B handshake.
    //--------------------------------------------------------------------------
    task monitor_writes();
        forever begin
            bit [31:0] a, d; bit [3:0] s; bit got_aw = 0, got_w = 0;
            // Collect address and data handshakes (order-independent)
            while (!(got_aw && got_w)) begin
                @(vif.mon_cb);
                if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
                    a = vif.mon_cb.awaddr; got_aw = 1;
                end
                if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
                    d = vif.mon_cb.wdata; s = vif.mon_cb.wstrb; got_w = 1;
                end
            end
            // Wait for the response handshake, then publish
            do @(vif.mon_cb); while (!(vif.mon_cb.bvalid && vif.mon_cb.bready));
            begin
                axi4lite_seq_item tr = axi4lite_seq_item::type_id::create("mon_wr");
                tr.dir = axi4lite_seq_item::AXI_WRITE;
                tr.addr = a; tr.data = d; tr.strb = s; tr.resp = vif.mon_cb.bresp;
                ap.write(tr);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Reconstruct a read from the AR handshake + R handshake.
    //--------------------------------------------------------------------------
    task monitor_reads();
        forever begin
            bit [31:0] a;
            do @(vif.mon_cb); while (!(vif.mon_cb.arvalid && vif.mon_cb.arready));
            a = vif.mon_cb.araddr;
            do @(vif.mon_cb); while (!(vif.mon_cb.rvalid && vif.mon_cb.rready));
            begin
                axi4lite_seq_item tr = axi4lite_seq_item::type_id::create("mon_rd");
                tr.dir = axi4lite_seq_item::AXI_READ;
                tr.addr = a; tr.data = vif.mon_cb.rdata; tr.strb = 4'h0;
                tr.resp = vif.mon_cb.rresp;
                ap.write(tr);
            end
        end
    endtask

endclass
