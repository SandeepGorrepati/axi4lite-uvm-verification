# Regression evidence - 2026-10-22

## Observed UVM execution

[Verified workflow run](https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/runs/39755836209), code commit `a1b16ba46cf86a8b247974e92559dc577187c449`. Tools: Verilator 5.052 and upstream UVM 2020.3.1; seed 20261022. Interface assertions were enabled.

| Test | Writes | Reads | Matching in-range reads | Data mismatches | Response mismatches | UVM_ERROR / UVM_FATAL | Reported covergroup coverage |
|---|---:|---:|---:|---:|---:|---|---:|
| sanity | 10 | 10 | 10 | 0 | 0 | 0 / 0 | 72.22% |
| regression | 344 | 108 | 97 | 0 | 0 | 0 / 0 | 100.00% |
| RAL | 8 | 8 | 8 | 0 | 0 | 0 / 0 | 38.89% |

All three scoreboards reported RESULT: PASS. Error-address reads check response policy; they are excluded from matching in-range data totals. Coverage percentages refer only to this environment's declared operation/address/strobe/response/cross bins. They are not exhaustive state, code, or AXI compliance coverage. Verilator is two-state; four-state X/Z behavior and commercial-simulator portability are not established.

## Other independently executed layers

| Flow | Status | Scope |
|---|---|---|
| Icarus protocol oracle | PASS | 1,075 write/read pairs plus reset cancellation/recovery |
| Byte-strobe and response-policy mutations | DETECTED | Each injected RTL defect must cause a matching checker failure and nonzero exit |
| Actual-DUT formal | PASS | Yosys SAT, 24 steps, MEM_WORDS=4, stated master/reset assumptions |

Protocol baseline: https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/runs/39751866343

Actual-DUT SAT baseline: https://github.com/SandeepGorrepati/axi4lite-uvm-verification/actions/runs/39753143283

The prior policy-model induction log applies only to `formal/axi4lite_resp_fv.sv`. Full current workflow logs are retained as Actions artifacts under GitHub retention rules. This page records a dated run; re-run after functional changes.
