//==============================================================================
// axi4lite_test.sv
// Test library. Base test builds the env; derived tests pick a sequence.
//==============================================================================
class axi4lite_base_test extends uvm_test;
    `uvm_component_utils(axi4lite_base_test)

    axi4lite_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4lite_env::type_id::create("env", this);
    endfunction

    // Drop objection after the chosen sequence finishes (overridden below)
    virtual task run_phase(uvm_phase phase); endtask
endclass

//------------------------------------------------------------------------------
// Smoke / sanity: directed write-read pairs.
//------------------------------------------------------------------------------
class axi4lite_sanity_test extends axi4lite_base_test;
    `uvm_component_utils(axi4lite_sanity_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi4lite_write_read_seq seq = axi4lite_write_read_seq::type_id::create("seq");
        phase.raise_objection(this);
        assert(seq.randomize() with { num_pairs == 10; });
        seq.start(env.agent.sqr);
        phase.phase_done.set_drain_time(this, 100ns);
        phase.drop_objection(this);
    endtask
endclass

//------------------------------------------------------------------------------
// Regression: directed corner cases + constrained-random traffic + readbacks,
// to push functional coverage up. This is the default test.
//------------------------------------------------------------------------------
class axi4lite_regression_test extends axi4lite_base_test;
    `uvm_component_utils(axi4lite_regression_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi4lite_directed_seq   d_seq   = axi4lite_directed_seq::type_id::create("d_seq");
        axi4lite_write_read_seq wr_seq  = axi4lite_write_read_seq::type_id::create("wr_seq");
        axi4lite_random_seq     rnd_seq = axi4lite_random_seq::type_id::create("rnd_seq");
        axi4lite_error_seq      err_seq = axi4lite_error_seq::type_id::create("err_seq");

        phase.raise_objection(this);
        d_seq.start(env.agent.sqr);
        assert(wr_seq.randomize() with { num_pairs == 16; });
        wr_seq.start(env.agent.sqr);
        assert(rnd_seq.randomize() with { num_txns == 40; });
        rnd_seq.start(env.agent.sqr);
        err_seq.start(env.agent.sqr);          // out-of-range -> DECERR error path
        phase.phase_done.set_drain_time(this, 200ns);
        phase.drop_objection(this);
    endtask
endclass

//------------------------------------------------------------------------------
// RAL test: access the slave memory through the register-abstraction layer
// (regmodel.mem.write/read) instead of hand-driving addresses.
// Run with +UVM_TESTNAME=axi4lite_ral_test
//------------------------------------------------------------------------------
class axi4lite_ral_test extends axi4lite_base_test;
    `uvm_component_utils(axi4lite_ral_test)

    axi4lite_reg_block   regmodel;
    axi4lite_reg_adapter adapter;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);                 // builds env (agent/scoreboard/cov)
        regmodel = axi4lite_reg_block::type_id::create("regmodel");
        regmodel.build();                          // configures uvm_mem + locks model
    endfunction

    function void connect_phase(uvm_phase phase);
        adapter = axi4lite_reg_adapter::type_id::create("adapter");
        regmodel.default_map.set_sequencer(env.agent.sqr, adapter);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        phase.raise_objection(this);
        for (int i = 0; i < 8; i++) begin
            regmodel.mem.write(status, i, 32'hA000_0000 + i, .parent(null));
            regmodel.mem.read (status, i, rdata,            .parent(null));
            if (rdata !== (32'hA000_0000 + i))
                `uvm_error("RAL", $sformatf("mem[%0d] expected 0x%08h got 0x%08h",
                           i, 32'hA000_0000 + i, rdata))
            else
                `uvm_info("RAL", $sformatf("mem[%0d] OK = 0x%08h", i, rdata), UVM_LOW)
        end
        phase.phase_done.set_drain_time(this, 200ns);
        phase.drop_objection(this);
    endtask
endclass
