//==============================================================================
// axi4lite_ral.sv
// UVM Register Abstraction Layer (RAL) for the AXI4-Lite slave.
//
// The slave's 256 x 32-bit space is modeled as a uvm_mem (a memory region in the
// register model). A uvm_reg_adapter converts RAL bus operations <-> the
// axi4lite_seq_item the driver understands, so tests can do:
//     regmodel.mem.write(status, index, value, .parent(seq));
//     regmodel.mem.read (status, index, value, .parent(seq));
// instead of hand-driving addresses.
//
// This is an ADDITIVE layer: it has its own test (axi4lite_ral_test) and does not
// affect the default regression. Run with +UVM_TESTNAME=axi4lite_ral_test.
//==============================================================================

// ---------------------------------------------------------------------------
// Register block: one memory covering the 256-word space (word-addressed).
// ---------------------------------------------------------------------------
class axi4lite_reg_block extends uvm_reg_block;
    `uvm_object_utils(axi4lite_reg_block)

    rand uvm_mem mem;

    function new(string name = "axi4lite_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN);
        // 256 entries, 32-bit each, RW
        mem = uvm_mem::type_id::create("mem");
        mem.configure(this, 256, 32, "RW", 0);
        default_map.add_mem(mem, 'h0, "RW");
        lock_model();
    endfunction
endclass

// ---------------------------------------------------------------------------
// Adapter: RAL <-> axi4lite_seq_item
// ---------------------------------------------------------------------------
class axi4lite_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(axi4lite_reg_adapter)

    function new(string name = "axi4lite_reg_adapter");
        super.new(name);
        // this slave returns read data in the same item we drive (no separate rsp item)
        supports_byte_enable = 0;
        provides_responses    = 0;
    endfunction

    // RAL operation -> bus transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        axi4lite_seq_item t = axi4lite_seq_item::type_id::create("ral_item");
        t.dir  = (rw.kind == UVM_WRITE) ? axi4lite_seq_item::AXI_WRITE
                                        : axi4lite_seq_item::AXI_READ;
        t.addr = rw.addr;          // map already scales index -> byte address
        t.data = rw.data;
        t.strb = 4'hF;
        t.oob  = (rw.addr >= 32'h0000_0400);
        return t;
    endfunction

    // bus transaction -> RAL (capture read data + response status)
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axi4lite_seq_item t;
        if (!$cast(t, bus_item)) begin
            `uvm_fatal("RAL_ADAPTER", "bus_item is not an axi4lite_seq_item")
            return;
        end
        rw.kind   = (t.dir == axi4lite_seq_item::AXI_WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr   = t.addr;
        rw.data   = t.data;
        // OKAY (2'b00) -> IS_OK; anything else (DECERR) -> ERROR
        rw.status = (t.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;
    endfunction
endclass
