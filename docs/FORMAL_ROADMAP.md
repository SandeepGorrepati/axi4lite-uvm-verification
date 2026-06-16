# Formal Verification Roadmap (AXI4-Lite handshake)

The SVA properties already bound in `axi4lite_if.sv` express safety properties that can be
**formally proven** (exhaustively, not just simulated). This is the highest-prestige next
step and is achievable with open-source tools.

## Why this is impressive
Simulation shows bugs you *hit*; formal proves a property holds for **all** legal inputs.
Top-tier DV/verification teams value formal property verification highly.

## Properties worth proving (already written as SVA)
- VALID/payload stable until READY (`$stable`).
- No response without a pending transaction.
- Response is always a legal code (OKAY/DECERR).
- Bounded completion (every accepted access eventually responds).

## Toolchain (open-source)
- **SymbiYosys (sby)** + **Yosys** + a solver (Boolector/Yices/Z3).
- Note: open-source Yosys has *limited* concurrent-SVA support; for full `assert property`
  with sequences you may need a Verific-enabled build or rewrite the properties as simple
  immediate/`$past`-style safety assertions in a formal wrapper.

## Sketch of the flow
```
# 1. write a formal wrapper that instantiates axi4lite_slave and asserts the
#    safety properties (start with simple ones: resp legal, no spurious resp,
#    out-of-range write does not change memory).
# 2. axi4lite_formal.sby:
[options]
mode prove
depth 20
[engines]
smtbmc
[script]
read -formal axi4lite_slave.sv
read -formal axi4lite_formal.sv
prep -top axi4lite_formal
[files]
../rtl/axi4lite_slave.sv
axi4lite_formal.sv

# 3. run:  sby -f axi4lite_formal.sby
```

## Status
Roadmap / planned. The properties exist (in `axi4lite_if.sv`); turning them into a passing
SymbiYosys proof is the next-level item — do it once you have the toolchain set up.
