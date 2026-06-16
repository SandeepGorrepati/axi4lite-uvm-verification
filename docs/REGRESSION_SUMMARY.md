# AXI4-Lite UVM — Regression Summary

Fill the result cells after the EDA Playground / Questa run (UVM 1.2). The structure is
what an interviewer wants to see: tests, intent, and pass/fail at a glance.

## Regression matrix
| Test (`+UVM_TESTNAME=`) | Purpose | Result |
|---|---|---|
| `axi4lite_sanity_test` | 10 directed write/read pairs (smoke) | _pending run_ |
| `axi4lite_regression_test` | directed corners + 16 wr/rd pairs + 40 random + DECERR error seq | _pending run_ |
| `axi4lite_ral_test` | RAL `regmodel.mem.write/read` access | _pending run_ |
| `axi4lite_regression_test` + `+define+INJECT_WSTRB_BUG` | data-bug must be CAUGHT (scoreboard FAIL) | _expected: caught_ |
| `axi4lite_regression_test` + `+define+INJECT_BRESP_ERR` | protocol-bug must be CAUGHT (SVA fires) | _expected: caught_ |

## Sign-off criteria
- `MISMATCH=0`, `RESP_MISMATCH=0`, `UVM_ERROR=0`, `UVM_FATAL=0` on clean runs.
- Functional coverage = 100% of defined coverpoints/cross (regression test).
- Both injected-bug runs report a failure (proves the checkers work).

## Result snapshot (paste from the run)
```
[SCB] writes=.. reads=.. MATCH=.. MISMATCH=0 RESP_MISMATCH=0
[SCB] RESULT: PASS
[COV] Functional coverage = ..%
UVM_ERROR : 0   UVM_FATAL : 0
```
*(Attach screenshots of the clean PASS, the coverage line, and the two bug-catch FAILs.)*
