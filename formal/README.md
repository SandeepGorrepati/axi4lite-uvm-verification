# Formal Verification — AXI4-Lite response/handshake properties

This directory **formally proves** (not just simulates) the response and decode
policy of the AXI4-Lite slave using **SymbiYosys + Z3** with **temporal
k-induction** — an unbounded proof that the properties hold in *every* reachable
state, for *all* input sequences.

`axi4lite_resp_fv.sv` is a compact, synthesizable model of the slave's response
logic (in-range → `OKAY`, out-of-range → `DECERR`, single outstanding response),
written so an open-source formal flow can read it.

## Properties proven

| ID | Property | Meaning |
|----|----------|---------|
| P1 | `bresp ∈ {OKAY, DECERR}` always | response code is never the reserved 01/10 |
| P2 | new `bvalid` ⇒ a request occurred | no spurious / phantom responses |
| P3 | accepted in-range write ⇒ `OKAY` | correct success decode |
| P4 | accepted out-of-range write ⇒ `DECERR` | correct error decode |
| P5 | `bvalid` held until `bready` | response is never dropped (stable handshake) |

## Result

```
BMC base case (depth 25):        PASSED
Temporal k-induction:            PASSED  -> unbounded proof
```

All five properties are **proven**. See `PROOF_LOG.txt` for the tool output.

## How to run

**With SymbiYosys (recommended):**
```bash
sby -f axi4lite_resp_fv.sby
```

**Manual Yosys + yosys-smtbmc flow (what was used here):**
```bash
yosys -p "read_verilog -sv -formal axi4lite_resp_fv.sv; \
          prep -top axi4lite_resp_fv; write_smt2 -wires model.smt2"
yosys-smtbmc -s z3 -t 25 model.smt2      # base case
yosys-smtbmc -s z3 -i -t 25 model.smt2   # k-induction (unbounded proof)
```

## Why this matters
Directed/constrained-random simulation (the UVM env in this repo) *finds* bugs by
exercising cases. Formal *proves* the absence of a class of bugs over all inputs —
here, that the slave can never emit an illegal response code, a phantom response,
a wrong decode, or a dropped handshake. The two approaches are complementary; this
repo demonstrates both.
