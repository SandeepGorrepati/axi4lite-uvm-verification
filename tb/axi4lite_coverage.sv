//==============================================================================
// axi4lite_coverage.sv
// Functional coverage subscriber: real covergroups over operation, address
// range, byte-strobe pattern, and operation x address-range cross.
//==============================================================================
class axi4lite_coverage extends uvm_subscriber #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_coverage)

    axi4lite_seq_item tr;

    covergroup cg_axi;
        option.per_instance = 1;

        cp_dir : coverpoint tr.dir {
            bins write = {axi4lite_seq_item::AXI_WRITE};
            bins read  = {axi4lite_seq_item::AXI_READ};
        }

        cp_addr_range : coverpoint tr.addr {
            bins low  = {[32'h0000_0000 : 32'h0000_00FC]};
            bins mid  = {[32'h0000_0100 : 32'h0000_02FC]};
            bins high = {[32'h0000_0300 : 32'h0000_03FC]};
        }

        cp_strb : coverpoint tr.strb iff (tr.dir == axi4lite_seq_item::AXI_WRITE) {
            bins full   = {4'hF};
            bins single = {4'h1, 4'h2, 4'h4, 4'h8};
            bins other  = default;
        }

        cp_resp : coverpoint tr.resp {
            bins okay = {2'b00};
        }

        x_dir_range : cross cp_dir, cp_addr_range;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_axi = new();
    endfunction

    // uvm_subscriber requires this single write() hook
    function void write(axi4lite_seq_item t);
        tr = t;
        cg_axi.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%",
                  cg_axi.get_inst_coverage()), UVM_LOW)
    endfunction

endclass
