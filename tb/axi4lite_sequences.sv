//==============================================================================
// axi4lite_sequences.sv
// Sequence library: write/read pairs, constrained-random traffic, directed.
//==============================================================================

// Base sequence
class axi4lite_base_seq extends uvm_sequence #(axi4lite_seq_item);
    `uvm_object_utils(axi4lite_base_seq)
    function new(string name = "axi4lite_base_seq"); super.new(name); endfunction
endclass

//------------------------------------------------------------------------------
// Write a value to an address, then read it back. Self-targeting pairs make
// the scoreboard check meaningful (read should return last written data).
//------------------------------------------------------------------------------
class axi4lite_write_read_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_write_read_seq)

    rand int unsigned num_pairs;
    constraint c_num { soft num_pairs inside {[8:16]}; }

    function new(string name = "axi4lite_write_read_seq"); super.new(name); endfunction

    virtual task body();
        bit [31:0] last_addr;
        for (int i = 0; i < num_pairs; i++) begin
            axi4lite_seq_item wr = axi4lite_seq_item::type_id::create("wr");
            axi4lite_seq_item rd;
            // WRITE
            start_item(wr);
            assert(wr.randomize() with { dir == axi4lite_seq_item::AXI_WRITE; });
            last_addr = wr.addr;
            finish_item(wr);
            `uvm_info("SEQ", $sformatf("WRITE %s", wr.convert2string()), UVM_MEDIUM)

            // READ BACK same address
            rd = axi4lite_seq_item::type_id::create("rd");
            start_item(rd);
            assert(rd.randomize() with { dir == axi4lite_seq_item::AXI_READ;
                                         addr == last_addr; });
            finish_item(rd);
            `uvm_info("SEQ", $sformatf("READ  %s", rd.convert2string()), UVM_MEDIUM)
        end
    endtask
endclass

//------------------------------------------------------------------------------
// Pure constrained-random traffic (mix of reads and writes across the map).
//------------------------------------------------------------------------------
class axi4lite_random_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_random_seq)

    rand int unsigned num_txns;
    constraint c_num { soft num_txns inside {[20:40]}; }

    function new(string name = "axi4lite_random_seq"); super.new(name); endfunction

    virtual task body();
        for (int i = 0; i < num_txns; i++) begin
            axi4lite_seq_item t = axi4lite_seq_item::type_id::create("t");
            start_item(t);
            assert(t.randomize());
            finish_item(t);
        end
    endtask
endclass

//------------------------------------------------------------------------------
// Directed corner cases: byte-strobe writes, address boundaries, overwrite.
//------------------------------------------------------------------------------
class axi4lite_directed_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_directed_seq)
    function new(string name = "axi4lite_directed_seq"); super.new(name); endfunction

    task do_write(bit [31:0] a, bit [31:0] d, bit [3:0] s);
        axi4lite_seq_item t = axi4lite_seq_item::type_id::create("t");
        start_item(t);
        assert(t.randomize() with { dir == axi4lite_seq_item::AXI_WRITE;
                                    addr == a; data == d; strb == s; });
        finish_item(t);
    endtask

    task do_read(bit [31:0] a);
        axi4lite_seq_item t = axi4lite_seq_item::type_id::create("t");
        start_item(t);
        assert(t.randomize() with { dir == axi4lite_seq_item::AXI_READ; addr == a; });
        finish_item(t);
    endtask

    virtual task body();
        // lowest and highest words
        do_write(32'h0000_0000, 32'hDEAD_BEEF, 4'hF); do_read(32'h0000_0000);
        do_write(32'h0000_03FC, 32'hCAFE_BABE, 4'hF); do_read(32'h0000_03FC);
        // overwrite same address (latest wins)
        do_write(32'h0000_0010, 32'h1111_1111, 4'hF);
        do_write(32'h0000_0010, 32'h2222_2222, 4'hF); do_read(32'h0000_0010);
        // partial byte-strobe write over a known value
        do_write(32'h0000_0020, 32'hFFFF_FFFF, 4'hF);
        do_write(32'h0000_0020, 32'h0000_00AA, 4'h1); do_read(32'h0000_0020);
    endtask
endclass

//------------------------------------------------------------------------------
// Error-path: out-of-range accesses must return DECERR (and not corrupt memory).
// The scoreboard predicts DECERR for addr >= 0x400 and checks the response.
//------------------------------------------------------------------------------
class axi4lite_error_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_error_seq)

    rand int unsigned num_txns;
    constraint c_num { soft num_txns inside {[6:12]}; }

    function new(string name = "axi4lite_error_seq"); super.new(name); endfunction

    virtual task body();
        // directed out-of-range corners (write + read) -> expect DECERR
        foreach_oob_pair(32'h0000_0400);
        foreach_oob_pair(32'h0000_8000);
        foreach_oob_pair(32'h0000_FFFC);
        // randomized out-of-range traffic
        for (int i = 0; i < num_txns; i++) begin
            axi4lite_seq_item t = axi4lite_seq_item::type_id::create("t");
            start_item(t);
            assert(t.randomize() with { oob == 1'b1; });
            finish_item(t);
        end
    endtask

    task foreach_oob_pair(bit [31:0] a);
        axi4lite_seq_item wr = axi4lite_seq_item::type_id::create("wr");
        start_item(wr);
        assert(wr.randomize() with { dir == axi4lite_seq_item::AXI_WRITE; oob == 1'b1; addr == a; });
        finish_item(wr);
        begin
            axi4lite_seq_item rd = axi4lite_seq_item::type_id::create("rd");
            start_item(rd);
            assert(rd.randomize() with { dir == axi4lite_seq_item::AXI_READ; oob == 1'b1; addr == a; });
            finish_item(rd);
        end
    endtask
endclass


// Prime all words so random reads compare defined data in four-state simulators.
class axi4lite_init_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_init_seq)
    function new(string name="axi4lite_init_seq"); super.new(name); endfunction
    task body();
        for(int i=0;i<256;i++) begin
            axi4lite_seq_item t=axi4lite_seq_item::type_id::create("init_word");
            start_item(t);
            t.dir=axi4lite_seq_item::AXI_WRITE; t.addr=i*4;
            t.data=0; t.strb=15; t.oob=0;
            finish_item(t);
        end
    endtask
endclass

// All 16 masks with simultaneous, AW-first and W-first traffic, and response stalls.
class axi4lite_timing_seq extends axi4lite_base_seq;
    `uvm_object_utils(axi4lite_timing_seq)
    function new(string name="axi4lite_timing_seq"); super.new(name); endfunction
    task body();
        for(int profile=0;profile<3;profile++) begin
            for(int mask=0;mask<16;mask++) begin
                axi4lite_seq_item wr=axi4lite_seq_item::type_id::create("timed_wr");
                axi4lite_seq_item rd=axi4lite_seq_item::type_id::create("timed_rd");
                start_item(wr);
                wr.dir=axi4lite_seq_item::AXI_WRITE;
                wr.addr=(profile==0)?0:((profile==1)?32'h100:32'h3fc);
                wr.data=32'ha5c3f00f ^ mask;
                wr.strb=mask[3:0];
                wr.aw_delay=(profile==2)?6:0;
                wr.w_delay=(profile==1)?6:0;
                wr.b_delay=6;
                finish_item(wr);
                start_item(rd);
                rd.dir=axi4lite_seq_item::AXI_READ; rd.addr=wr.addr;
                rd.r_delay=6;
                finish_item(rd);
            end
        end
    endtask
endclass
