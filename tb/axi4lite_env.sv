//==============================================================================
// axi4lite_env.sv
// UVM environment: agent + scoreboard + coverage, with analysis connections.
//==============================================================================
class axi4lite_env extends uvm_env;
    `uvm_component_utils(axi4lite_env)

    axi4lite_agent      agent;
    axi4lite_scoreboard sb;
    axi4lite_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi4lite_agent::type_id::create("agent", this);
        sb    = axi4lite_scoreboard::type_id::create("sb", this);
        cov   = axi4lite_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Monitor broadcasts to both the scoreboard and the coverage collector
        agent.mon.ap.connect(sb.imp);
        agent.mon.ap.connect(cov.analysis_export);
    endfunction

endclass
