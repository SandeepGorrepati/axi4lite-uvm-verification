//==============================================================================
// axi4lite_pkg.sv
// UVM package: pulls in every class in dependency order.
//==============================================================================
package axi4lite_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi4lite_seq_item.sv"
    `include "axi4lite_sequences.sv"
    `include "axi4lite_driver.sv"
    `include "axi4lite_monitor.sv"
    `include "axi4lite_scoreboard.sv"
    `include "axi4lite_coverage.sv"
    `include "axi4lite_agent.sv"
    `include "axi4lite_env.sv"
    `include "axi4lite_ral.sv"
    `include "axi4lite_test.sv"
endpackage
