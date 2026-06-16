# AXI4-Lite UVM — Interview Defense

Exactly how to talk about this project under pressure. Read it out loud until fluent.

## 30-second pitch
"I built a full UVM environment verifying an AXI4-Lite slave. It has the standard
hierarchy — sequencer, driver, monitor, agent, env — a reference-model scoreboard that
predicts both data and the response code, covergroups for functional coverage, concurrent
SVA bound to the interface, and a UVM RAL model. I also verify the error path: out-of-range
accesses must return DECERR. And I added two injectable bugs so I can show the testbench
actually catches a data bug and a protocol bug."

## Likely questions → crisp answers
- **"Walk me through the env."** sequence → sequencer → driver → DUT → monitor → analysis
  port → scoreboard + coverage; SVA bound in the interface. (See `ARCHITECTURE.md`.)
- **"How does the scoreboard check?"** Reference model: a predicted memory. On writes it
  updates the model honoring WSTRB; on reads it compares DUT data to the prediction; it also
  predicts the response (OKAY in-range / DECERR out-of-range) and checks it.
- **"Sequencer–driver handshake?"** driver `get_next_item` → drive → `item_done`; sequence
  `start_item`/`finish_item` blocks until `item_done` (back-pressure).
- **"Real SVA or procedural?"** Real concurrent `assert property` bound in `axi4lite_if.sv`
  (handshake stability via `$stable`, no-X, legal response, bounded completion).
- **"Covergroups vs counters?"** Real `covergroup`/`coverpoint`/`cross` (op, addr incl. oob,
  strobe, resp). I drive to closure and read `get_inst_coverage()`.
- **"What is RAL and why?"** Register Abstraction Layer — `uvm_reg_block` + `uvm_mem` + an
  adapter; tests do `regmodel.mem.write/read` instead of hand-driving AW/W/B. Decouples
  test intent from bus mechanics.
- **"Prove it finds bugs."** Two defines: `INJECT_WSTRB_BUG` (data) → scoreboard MISMATCH;
  `INJECT_BRESP_ERR` (protocol) → SVA fires. See `BUG_REPORTS.md`.
- **"How do you reach coverage closure?"** directed corners + constrained-random across
  seeds until every bin hits; write targeted tests for unhit bins.

## Known limitations (own them — don't bluff)
- It's AXI4-**Lite** (single beat, no bursts/IDs) — a deliberate, clean scope.
- The slave always returns OKAY/DECERR (no SLVERR by design); SLVERR is the injected
  protocol bug.
- Run on EDA Playground / Questa (UVM + covergroups need a commercial simulator).

## If asked "what would you add next?"
"Random back-pressure and outstanding/interleaved transactions, and a formal proof of the
handshake properties (the SVA already expresses them) — see `FORMAL_ROADMAP.md`."
