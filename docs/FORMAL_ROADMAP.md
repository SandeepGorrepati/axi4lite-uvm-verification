# Formal status and next meaningful extensions

Implemented: `formal/axi4lite_dut_fv.sv` instantiates the actual RTL and checks response credits, legal response codes, and stall stability through 24 steps. Run instructions and assumptions are in `formal/README.md`.

The older `axi4lite_resp_fv.sv` proof covers a separate policy model only.

Future work, not completed claims: symbolic-address memory-data/byte-enable equivalence, cover witnesses for each transaction/error path, induction for invariant safety, parameter sweeps beyond four words, and liveness under explicit fairness assumptions. These require additional harnesses and evidence rather than a stronger label on existing results.
