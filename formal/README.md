# Formal verification scope

There are two different harnesses. Keep their claims separate.

## Actual RTL: bounded safety

`axi4lite_dut_fv.sv` instantiates `rtl/axi4lite_slave.sv` with MEM_WORDS=4. It assumes an initial active reset and legal master VALID/payload persistence across stalls. READY signals remain arbitrary. Response-credit counters check that responses have requests; further assertions check response codes and B/R stability under backpressure.

Reproduce the exact CI check with Yosys:

```bash
mkdir -p build
yosys -Q -T -p 'read_verilog -formal -sv rtl/axi4lite_slave.sv formal/axi4lite_dut_fv.sv; prep -top axi4lite_dut_fv -flatten; async2sync; memory_map; opt; sat -seq 24 -prove-asserts -set-assumes -verify -dump_vcd build/counterexample.vcd'
```

A successful exit and SAT proof success establish the listed assertions only within the 24-step bound and assumptions. They do not establish unbounded correctness, address-decoding/data-model equivalence, coverage reachability, or liveness. Six-bit transaction-credit counters cannot wrap within this bound. The smaller memory configuration is explicit; simulation checks the default 256-word configuration.

## Historical policy model

`axi4lite_resp_fv.sv` implements a separate simplified response-policy state machine. `axi4lite_resp_fv.sby` and `PROOF_LOG.txt` are historical artifacts for that model. Even if its induction proof passes, it does not instantiate or prove the actual AXI slave. Do not attribute its five properties to the full RTL.
