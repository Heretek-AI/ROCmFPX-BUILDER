# Engine Patches for q38rocm (Strix Halo gfx1151)

These patches are applied during the `q38rocm` automated build pipeline targeting AMD Strix Halo (`gfx1151`).

| Patch | Fixes | Where it ships | Upstream Drop Condition |
|---|---|---|---|
| `mtp-prompt-cache-fix.patch` | MTP checkpoint restore aborted on checkpoints captured during prefill (`common_speculative_set_state` with no boundary rows) | ✅ q38rocm build | Upstream `ROCmFPX` (or `llama.cpp`) handles empty draft state on rollback |
| `router-loading-child-stop-timeout.patch` | Router waited the full `stop-timeout` (10 s) before SIGTERMing a child that was still loading | ✅ q38rocm build | Upstream router skips graceful handshake for children still loading |
