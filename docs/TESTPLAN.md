# Verification traceability

| Feature | Stimulus/check | Execution scope |
|---|---|---|
| Word data / overwrite / byte enables | Independent Python byte memory and SV readback | Protocol regression, default 256-word DUT |
| All 16 WSTRB masks | Directed vector sweep; all-mask UVM timing sequence | Protocol PASS; see summary for UVM status |
| AW before W / W before AW / simultaneous | Independent delays in protocol test and UVM driver | Protocol PASS; see summary for UVM status |
| B/R stalls | Hold READY low; compare VALID and payload stability | Protocol regression + bounded formal |
| Out-of-range writes/reads | DECERR expectation and valid-memory alias check | Protocol regression |
| Partial write reset cancellation | AW-only acceptance followed by reset; no orphan response; recovery | Protocol regression |
| Response credits / legal codes | Symbolic legal master timing | Actual-DUT bounded formal, 24 steps, four words |
| Data/response mutations | Both injected macros must produce nonzero checker failures | Protocol mutation CI |
| RAL | Eight uvm_mem write/read pairs and status checks | See current regression summary |
| Four-state X/Z / commercial simulator portability | Interface assertions exist | Not established by two-state Verilator execution |

Passing simulation is finite evidence. Coverage is scoped to declared bins. Neither test count nor compile success implies complete AXI compliance. Outstanding/interleaved UVM streams, UVM mid-transaction reset recovery, exhaustive data-space coverage, and unbounded formal proof remain outside this implementation.
