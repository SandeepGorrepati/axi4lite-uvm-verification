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
        axi4lite_directed_seq   d_seq = axi4lite_directed_seq::type_id::create("d_seq");
        axi4lite_write_read_seq wr_seq = axi4lite_write_read_seq::type_id::create("wr_seq");
        axi4lite_random_seq     rnd_seq = axi4lite_random_seq::type_id::create("rnd_seq");

        phase.raise_objection(this);
        d_seq.start(env.agent.sqr);
        assert(wr_seq.randomize() with { num_pairs == 16; });
        wr_seq.start(env.agent.sqr);
        assert(rnd_seq.randomize() with { num_txns == 40; });
        rnd_seq.start(env.agent.sqr);
        phase.phase_done.set_drain_time(this, 200ns);
        phase.drop_objection(this);
    endtask
endclass
