# AXI4-Lite UVM — Coverage Plan

Functional coverage model (in `tb/axi4lite_coverage.sv`) and the closure intent.

## Coverpoints
| Coverpoint | Bins | Intent |
|---|---|---|
| `cp_dir` | write, read | both transaction directions exercised |
| `cp_addr_range` | low (0x000–0x0FC), mid (0x100–0x2FC), high (0x300–0x3FC), **oob** (≥0x400) | full address map incl. out-of-range |
| `cp_strb` (writes) | full (0xF), single (1/2/4/8), other | byte-enable patterns |
| `cp_resp` | okay (2'b00), **decerr** (2'b11) | both response codes |
| `x_dir_range` | cp_dir × cp_addr_range | read & write across every region incl. oob |

## Closure strategy
- `axi4lite_directed_seq` → strobe + boundary corners.
- `axi4lite_write_read_seq` + `axi4lite_random_seq` → low/mid/high spread.
- `axi4lite_error_seq` → closes `oob` + `decerr` bins and their cross columns.
- Read the number from the report: `[COV] Functional coverage = NN.NN%`.
- Target: **100%** of defined coverpoints/cross with the `regression` test.

## Result (fill after run)
| Metric | Value |
|---|---|
| Functional coverage | _pending EDA Playground run_ |
| Unhit bins | _pending_ |

> If a bin is unhit, write a targeted directed test for it — the coverage-driven loop.
