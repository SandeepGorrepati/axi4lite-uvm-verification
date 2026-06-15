//==============================================================================
// axi4lite_seq_item.sv
// UVM sequence item (transaction) for AXI4-Lite.
//==============================================================================
class axi4lite_seq_item extends uvm_sequence_item;

    typedef enum bit {AXI_READ = 1'b0, AXI_WRITE = 1'b1} dir_e;

    rand dir_e          dir;
    rand bit [31:0]     addr;
    rand bit [31:0]     data;     // write data (stimulus) / read data (result)
    rand bit [3:0]      strb;
    bit [1:0]           resp;     // captured response (OKAY expected)

    // Memory is 256 words; keep addresses word-aligned and in range.
    constraint c_addr_aligned { addr[1:0] == 2'b00; }
    constraint c_addr_range   { addr < 32'h0000_0400; }   // 256 * 4 bytes
    constraint c_strb_full    { soft strb == 4'hF; }       // full-word by default

    `uvm_object_utils_begin(axi4lite_seq_item)
        `uvm_field_enum(dir_e, dir, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4lite_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s addr=0x%08h data=0x%08h strb=0x%1h resp=%0d",
                         dir.name(), addr, data, strb, resp);
    endfunction

endclass
