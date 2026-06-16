# AXI4-Lite UVM — Test Plan & Traceability

Verification plan for the AXI4-Lite slave UVM environment: features → stimulus →
checking → coverage → status. (Status/coverage cells marked *pending* are filled in
after the EDA Playground run; see `REGRESSION_SUMMARY.md`.)

## DUT
AXI4-Lite slave, 256 × 32-bit word memory, byte-strobed writes, OKAY for in-range
accesses, **DECERR** for out-of-range (`addr ≥ 0x400`).

## Verification environment
`sequence → sequencer → driver → DUT → monitor → scoreboard (+ coverage)`; concurrent
SVA bound in the interface; reference-model scoreboard predicts data **and** response.

## Traceability matrix
| ID | Feature | Stimulus (test/sequence) | Checker | Coverage point | Status |
|----|---------|--------------------------|---------|----------------|--------|
| T1 | Write → readback | `axi4lite_write_read_seq` | scoreboard data | cp_dir, cp_addr_range | pending run |
| T2 | Byte-strobe partial write | `axi4lite_directed_seq` | scoreboard (ref honors WSTRB) | cp_strb (single/full) | pending run |
| T3 | Overwrite (latest wins) | `axi4lite_directed_seq` | scoreboard | cp_addr_range | pending run |
| T4 | Address boundaries (low/mid/high) | `axi4lite_random_seq` | scoreboard | cp_addr_range cross | pending run |
| T5 | Out-of-range → DECERR | `axi4lite_error_seq` | scoreboard response-prediction | cp_resp(decerr), cp_addr_range(oob) | pending run |
| T6 | Handshake stability / no-X / legal resp | all sequences | SVA (interface) | assertion pass | pending run |
| T7 | RAL register/memory access | `axi4lite_ral_test` | RAL status (IS_OK/NOT_OK) | — | pending run |
| B1 | Injected data bug (WSTRB ignored) | `+define+INJECT_WSTRB_BUG` | scoreboard READ MISMATCH | — | caught (expected fail) |
| B2 | Injected protocol bug (SLVERR) | `+define+INJECT_BRESP_ERR` | SVA `A_BRESP_LEGAL` fires | — | caught (expected fail) |

## Pass criteria
- Scoreboard: `MISMATCH=0` and `RESP_MISMATCH=0`, `reads>0`.
- SVA: no assertion failures in clean runs; both injected bugs **do** fire.
- Coverage: 100% of defined coverpoints/cross closed by the `regression` test.

## How to run
EDA Playground (UVM 1.2, Questa): `+UVM_TESTNAME=axi4lite_regression_test`, then
`axi4lite_ral_test`, then a buggy run with `+define+INJECT_WSTRB_BUG`.
