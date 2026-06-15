//==============================================================================
// axi4lite_driver.sv
// UVM driver: converts transactions into AXI4-Lite pin wiggles.
//==============================================================================
class axi4lite_driver extends uvm_driver #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_driver)

    virtual axi4lite_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set for driver")
    endfunction

    task run_phase(uvm_phase phase);
        // idle the master signals out of reset
        reset_signals();
        @(posedge vif.aresetn);
        @(vif.drv_cb);
        forever begin
            axi4lite_seq_item tr;
            seq_item_port.get_next_item(tr);
            if (tr.dir == axi4lite_seq_item::AXI_WRITE) drive_write(tr);
            else                                        drive_read(tr);
            seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        vif.drv_cb.awvalid <= 1'b0;
        vif.drv_cb.wvalid  <= 1'b0;
        vif.drv_cb.bready  <= 1'b0;
        vif.drv_cb.arvalid <= 1'b0;
        vif.drv_cb.rready  <= 1'b0;
        vif.drv_cb.awaddr  <= '0;
        vif.drv_cb.wdata   <= '0;
        vif.drv_cb.wstrb   <= '0;
        vif.drv_cb.araddr  <= '0;
    endtask

    //--------------------------------------------------------------------------
    // AXI4-Lite write: drive AW and W concurrently, then accept B response.
    //--------------------------------------------------------------------------
    task drive_write(axi4lite_seq_item tr);
        // Launch address and data phases together
        vif.drv_cb.awaddr  <= tr.addr;
        vif.drv_cb.awvalid <= 1'b1;
        vif.drv_cb.wdata   <= tr.data;
        vif.drv_cb.wstrb   <= tr.strb;
        vif.drv_cb.wvalid  <= 1'b1;
        vif.drv_cb.bready  <= 1'b1;

        // Drop AW once it is accepted
        fork
            begin
                do @(vif.drv_cb); while (!vif.drv_cb.awready);
                vif.drv_cb.awvalid <= 1'b0;
            end
            begin
                do @(vif.drv_cb); while (!vif.drv_cb.wready);
                vif.drv_cb.wvalid <= 1'b0;
            end
        join

        // Wait for the write response
        do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
        tr.resp = vif.drv_cb.bresp;
        @(vif.drv_cb);
        vif.drv_cb.bready <= 1'b0;
    endtask

    //--------------------------------------------------------------------------
    // AXI4-Lite read: drive AR, then capture R.
    //--------------------------------------------------------------------------
    task drive_read(axi4lite_seq_item tr);
        vif.drv_cb.araddr  <= tr.addr;
        vif.drv_cb.arvalid <= 1'b1;
        vif.drv_cb.rready  <= 1'b1;

        do @(vif.drv_cb); while (!vif.drv_cb.arready);
        vif.drv_cb.arvalid <= 1'b0;

        do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
        tr.data = vif.drv_cb.rdata;     // result returned to the sequence
        tr.resp = vif.drv_cb.rresp;
        @(vif.drv_cb);
        vif.drv_cb.rready <= 1'b0;
    endtask

endclass
