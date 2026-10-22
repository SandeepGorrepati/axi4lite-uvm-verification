# Functional coverage scope

Observed on Verilator 5.052 + UVM 2020.3.1, seed 20261022: sanity 72.22%, regression 100.00%, RAL 38.89%. See REGRESSION_SUMMARY.md for the recorded run.

`cg_axi` samples completed monitor transactions. Coverpoints distinguish read/write, four address regions (low/mid/high/out-of-bounds), grouped write-strobe classes, and OKAY/DECERR. The operation/address cross has eight combinations. Strobe single-bit patterns are grouped into one declared bin; default bins must not be interpreted as an exhaustive mask coverage metric. The separate directed timing sequence and protocol test exercise all 16 masks explicitly.

Initialization writes every word. Directed timed reads span low/mid/high, and error traffic spans both operations out-of-bounds. This makes targeted bin closure reproducible rather than relying on chance.

100% applies only to the declared covergroup and tool calculation. It does not establish all bit/data combinations, code coverage closure, arbitrary concurrent outstanding traffic, reset recovery inside UVM, or four-state correctness. Those are not represented by this percentage.
