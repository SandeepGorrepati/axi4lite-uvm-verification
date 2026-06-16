# AXI4-Lite UVM — Bug Reports

Two deliberately injectable bugs demonstrate that the environment *catches* real
defects (not just passes). Each is a mini bug report: symptom → detection → root cause
→ how the checker found it.

---

## BUG-001 — Write ignores byte strobes (data bug)
- **Enable:** compile with `+define+INJECT_WSTRB_BUG`
- **Symptom:** a partial-strobe write (`WSTRB=0x1`) corrupts the un-strobed bytes.
- **Repro:** write `0xFFFFFFFF` to `0x20`, then write `0x000000AA` with `WSTRB=0x1`.
- **Expected:** `0xFFFFFFAA` (only byte 0 updated). **Buggy DUT:** `0x000000AA`.
- **Detection:** reference-model scoreboard (honors WSTRB) flags:
  `[SCB] READ MISMATCH addr=0x00000020 expected=0xFFFFFFAA got=0x000000AA`
- **Root cause:** write path writes the full word instead of masking by `WSTRB`.
- **Found by:** scoreboard data comparison. **Class:** functional / data-integrity.

---

## BUG-002 — Illegal response code (protocol bug)
- **Enable:** compile with `+define+INJECT_BRESP_ERR`
- **Symptom:** slave returns `SLVERR (2'b10)` on a normal read/write.
- **Expected:** `OKAY (2'b00)` in-range, or `DECERR (2'b11)` out-of-range — `SLVERR` is illegal for this slave.
- **Detection:** bound concurrent assertion fires:
  `[SVA] BRESP illegal (not OKAY/DECERR)`
- **Root cause:** response-code assignment driving an unsupported value.
- **Found by:** SVA `A_BRESP_LEGAL` / `A_RRESP_LEGAL`. **Class:** protocol.

---

## Takeaway
Two independent checking mechanisms — **scoreboard** (data) and **SVA** (protocol) —
each catch a different class of bug. That's the point of the environment: it finds
defects, and the failure log points straight at the root cause.

*(Attach the actual failing-run screenshots here after the EDA Playground run.)*
