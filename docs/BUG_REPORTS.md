# Defects and checker mutations

## Fixed defects

| Defect | Root cause | Correction |
|---|---|---|
| Write completion property | Bare SVA sequence, AW-only trigger, unbounded delay | Pair accepted AW/W, implication, finite response bound |
| Missing B stall check | No BVALID/BRESP persistence assertion | A_B_STABLE assertion |
| UVM compile failures | Reserved `matches` identifier; declaration after statements | Rename counter; put declarations before statements |
| RAL memory creation | Incorrect uvm_mem.configure signature | Construct with size/width/access, then configure(parent) |
| Random read expectation | Assumed unwritten DUT memory is zero | Initialize all words through actual bus writes before random traffic |
| No independent channel stress | AW/W launched together; READY always high | Timed channels, response stalls, all-mask timing sequence |

## Mutation checks

`INJECT_WSTRB_BUG` deliberately overwrites all bytes despite WSTRB. `INJECT_BRESP_ERR` deliberately returns SLVERR where this DUT promises OKAY/DECERR. Both are test-only compile-time defects.

The protocol CI compiles each mutant and requires a nonzero simulation exit containing a corresponding B/R response mismatch. If a mutant passes, CI fails. The checker validates an actual faulty RTL execution, not merely a hard-coded failing log.

SLVERR is an AXI response code; the error here is violating this DUT's documented response policy, not claiming AXI universally forbids SLVERR. Original illustrative UVM error strings are not execution evidence. See current workflow logs and REGRESSION_SUMMARY.md.
