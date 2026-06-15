//==============================================================================
// axi4lite_scoreboard.sv
// Reference-model scoreboard. Mirrors the slave memory (with byte strobes) on
// writes and checks every read's data against the predicted value.
//==============================================================================
`uvm_analysis_imp_decl(_axi)

class axi4lite_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4lite_scoreboard)

    uvm_analysis_imp_axi #(axi4lite_seq_item, axi4lite_scoreboard) imp;

    // Reference memory, keyed by word address. Unwritten words read as 0.
    bit [31:0] ref_mem [bit [31:0]];

    int unsigned writes, reads, matches, mismatches;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    // Called for every transaction the monitor publishes
    function void write_axi(axi4lite_seq_item tr);
        if (tr.dir == axi4lite_seq_item::AXI_WRITE) begin
            bit [31:0] cur = ref_mem.exists(tr.addr) ? ref_mem[tr.addr] : 32'h0;
            for (int b = 0; b < 4; b++)
                if (tr.strb[b]) cur[b*8 +: 8] = tr.data[b*8 +: 8];
            ref_mem[tr.addr] = cur;
            writes++;
        end
        else begin
            bit [31:0] expected = ref_mem.exists(tr.addr) ? ref_mem[tr.addr] : 32'h0;
            reads++;
            if (tr.data === expected) begin
                matches++;
                `uvm_info("SCB", $sformatf("READ MATCH  addr=0x%08h data=0x%08h",
                          tr.addr, tr.data), UVM_HIGH)
            end else begin
                mismatches++;
                `uvm_error("SCB", $sformatf(
                    "READ MISMATCH addr=0x%08h expected=0x%08h got=0x%08h",
                    tr.addr, expected, tr.data))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "============ SCOREBOARD SUMMARY ============", UVM_LOW)
        `uvm_info("SCB", $sformatf("writes=%0d reads=%0d MATCH=%0d MISMATCH=%0d",
                  writes, reads, matches, mismatches), UVM_LOW)
        if (mismatches == 0 && reads > 0)
            `uvm_info("SCB", "RESULT: PASS", UVM_LOW)
        else
            `uvm_error("SCB", "RESULT: FAIL")
    endfunction

endclass
