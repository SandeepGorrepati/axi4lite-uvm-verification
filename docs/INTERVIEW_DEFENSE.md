# Interview walkthrough

## Explain the architecture

AW and W can arrive independently. The DUT retains address/data until both are present, performs byte-enabled memory updates, and returns B. Reads capture an address and return R. The passive UVM monitor reconstructs completed transactions; its scoreboard independently predicts byte updates and response codes.

## Explain one meaningful bug

The original write-completion assertion was a sequence instead of a request-triggered implication. An AW-only trigger also ignores that W can arrive later. The corrected interface collects both handshakes, triggers a finite response expectation, and excludes BREADY from slave response generation. Bounds are an environment contract rather than an AXI latency guarantee.

## Explain how the checker was checked

CI compiles a second real DUT with INJECT_WSTRB_BUG. That version writes disabled bytes. The protocol oracle predicts preservation of those bytes, so a readback mismatch must stop simulation. CI fails if the mutant unexpectedly passes.

## Distinguish evidence

- Icarus protocol simulation drives the actual RTL and compares against a Python byte-memory oracle; it does not execute UVM classes.
- Actual-DUT formal is bounded safety for a four-word configuration and explicit assumptions.
- Historical policy-model induction applies only to a separate simplified state machine.
- UVM execution and covergroup status must be read from REGRESSION_SUMMARY.md and the current workflow logs.

## State the limits

The UVM driver serializes transactions. The monitor does not support arbitrary outstanding/interleaved traffic or reset recovery during an active transaction. Four-state checks need a four-state simulator. No claim of complete AXI compliance, exhaustive correctness, or production signoff is made.
