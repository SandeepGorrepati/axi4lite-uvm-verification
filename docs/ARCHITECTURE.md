# AXI4-Lite UVM — Architecture

```text
                         +---------------------- axi4lite_env ----------------------+
                         |                                                          |
  sequences  --------->  sequencer --> driver --> [ AXI4-Lite interface ] --> DUT   |
  (write_read,           |                              |   (axi4lite_slave: 256x32 |
   random, directed,     |                              |    mem, byte strobes,     |
   error/DECERR)         |                           monitor                        |
                         |                              | (analysis port)           |
                         |                +-------------+-------------+              |
                         |                v                           v              |
                         |        scoreboard                     coverage            |
                         |   (reference model:                (covergroups:          |
                         |    data + response                  op, addr incl. oob,    |
                         |    prediction)                      strobe, resp, cross)   |
                         |                                                          |
                         |   RAL: uvm_reg_block + uvm_mem + adapter (axi4lite_ral)   |
                         +----------------------------------------------------------+

   Bound SVA (in axi4lite_if): handshake stability ($stable), no-X on payload,
   legal response (OKAY/DECERR), bounded write/read completion.

   Injectable bugs:  +define+INJECT_WSTRB_BUG  (data -> scoreboard catches)
                     +define+INJECT_BRESP_ERR  (protocol -> SVA catches)
```

## Component roles
- **sequencer/driver** — arbitrate and drive AXI4-Lite handshakes from transactions.
- **monitor** — reconstruct completed transactions, broadcast on an analysis port.
- **scoreboard** — predicted-memory reference model; checks read data **and** the
  response code (OKAY in-range / DECERR out-of-range).
- **coverage** — functional coverage model (see `COVERAGE_PLAN.md`).
- **RAL** — register/memory abstraction (`regmodel.mem.write/read`).
- **SVA** — protocol legality, bound in the interface.
