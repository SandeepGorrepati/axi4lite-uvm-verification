# AXI4-Lite verification: UVM, protocol simulation, and bounded formal

![Protocol regression](https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/workflows/regression.yml/badge.svg)
![DUT bounded formal](https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/workflows/formal.yml/badge.svg)
![UVM](https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/workflows/uvm.yml/badge.svg)

Verification of a 256x32 AXI4-Lite memory slave with independent AW/W acceptance, byte strobes, and OKAY/DECERR responses. Evidence is separated by execution method: the free protocol test is not presented as a UVM run, and a policy-model proof is not presented as proof of the real RTL.

## Implemented verification layers

| Layer | Implementation | Evidence |
|---|---|---|
| Real-DUT protocol regression | Icarus + independent Python byte-memory oracle | 1,075 write/read pairs passed |
| Checker mutation | `INJECT_WSTRB_BUG` ignores byte enables | Regression must fail on data mismatch; CI confirms detection |
| Real-DUT bounded safety | Yosys SAT, actual slave with four-word memory | 24-step bounded check passed; arbitrary legal master timing |
| UVM | agent, driver, monitor, scoreboard, constrained sequences, covergroups, RAL | See current [regression summary](docs/REGRESSION_SUMMARY.md) |
| Historical formal model | Separate response-policy model in `axi4lite_resp_fv.sv` | Its historical proof applies only to that model |

## Reproduce the protocol test for free

Install Python 3 and Icarus Verilog. From the repository root:

```bash
python3 scripts/gen_vectors.py
iverilog -g2012 -s tb_protocol -o build/protocol rtl/axi4lite_slave.sv tb/tb_protocol.sv
vvp build/protocol
```

The deterministic oracle seeds all 256 words, exercises all 16 WSTRB masks, simultaneous/AW-first/W-first channels, response backpressure, out-of-range accesses, alias protection, and complete valid-memory readback. The test also cancels a partial write with reset and checks that no orphan response appears. A watchdog and case-inequality data checks turn failures into nonzero process status. The Python model stores individual bytes; it does not copy the DUT's pending-channel implementation.

## UVM architecture and tests

The sequencer/driver drives `axi4lite_if`; the passive monitor publishes completed transactions to a scoreboard and functional-coverage subscriber. The scoreboard models byte updates and predicts response codes. The RAL adapter maps a 256-word `uvm_mem` onto bus transactions.

- `axi4lite_sanity_test`: ten write/read pairs.
- `axi4lite_regression_test`: initialize all memory, directed corners, 48 write/read pairs covering every mask in three AW/W timing profiles, 16 additional write/read pairs, 40 random transactions, and directed/random DECERR traffic.
- `axi4lite_ral_test`: eight RAL write/read pairs with operation-status and data checks.

Randomized AW/W launch delays and B/R response stalls range from zero to six cycles. The default driver serializes complete transactions; the monitor is not claimed to support arbitrary multiple outstanding/interleaved streams. Initialization is required because AXI does not guarantee unwritten memory contains zero. UVM mid-transaction reset recovery is not implemented; reset cancellation is tested in the independent protocol flow.

The interface assertions check known payloads, VALID/payload persistence, legal response codes for this DUT, and bounded completion. Write completion starts after both AW and W are accepted and does not require BREADY. Response bounds are this environment's contract, not an AXI protocol latency requirement.

The open-source workflow builds pinned Verilator 5.052 and upstream UVM 2020.3.1, enables assertions and coverage, and requires zero UVM_ERROR/UVM_FATAL plus scoreboard PASS. Four-state X/Z behavior is not validated by a two-state simulator. Do not infer coverage closure from a green compile or protocol-only result.

## Actual-DUT formal scope

The harness instantiates `axi4lite_slave`, reducing MEM_WORDS to four to keep checks inexpensive. Inputs are symbolic; master VALID/payload persistence is assumed across stalls, initial reset is required, and READY may stall indefinitely. Checks cover legal responses, response transaction credits, and B/R persistence while stalled.

This is bounded safety through 24 steps, not an unbounded proof, AXI certification, memory-data equivalence proof, or liveness proof under arbitrary backpressure. See [formal instructions](formal/README.md).

## Bugs corrected during the upgrade

- Replaced a bare write-response SVA sequence with a request-triggered implication and explicit finite bound.
- Added B response stability; retained R payload stability checks.
- Corrected UVM sequence declaration order and RAL memory construction.
- Primed memory before random reads rather than assuming reset initializes the DUT array.
- Added real channel skew/backpressure and a checker mutation gate.

Full evidence and limitations are in [regression summary](docs/REGRESSION_SUMMARY.md) and Actions logs. No paid simulator, FPGA board, or subscription is required for the protocol and formal flows.
