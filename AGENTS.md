# Agent guidelines

- This repo builds ligaturized Fira Mono.
- Source fonts are the OTFs under `Fira-4.106/otf/`. There are exactly three
  upright weights: Regular, Medium, and Bold. Do not assume italics exist.
- Expected outputs land in `fonts/` as `LigaFiraMono-Regular.otf`,
  `LigaFiraMono-Medium.otf`, and `LigaFiraMono-Bold.otf`.
- Promote the Fira Code 6.2 variants `zero` (dotted zero), `cv02` (`g`), `cv10`
  (`l`), `ss03` (`&`), and `ss05` (`@`) to their base glyphs during final
  post-processing. Preserve Fira Mono's 600-unit character advance.
- Keep the existing ligature exclusions: `&&`, `~@`, `\/`, `.?`, `?:`, `?=`,
  `?.`, `??`, `;;`, `/\`.
- Reuse local release archives and the Ligaturizer checkout when available.
  Download missing archives, shallow-clone Ligaturizer, and initialize only
  the `fonts/fira` submodule.
- Respect existing changes; never reset or revert unless explicitly told.
- Prefer fast read/search tools (`rg`, `rg --files`); avoid destructive commands.
- Use `apply_patch` for edits; keep ASCII; add comments only when clarifying
  non-obvious logic.
- Follow sandbox/approval rules; request escalation when network or restricted
  paths are required.
- No heavy formatting in replies; reference files with clickable code paths
  (for example, `fonts/LigaFiraMono-Regular.otf`).
- When automating, include validation or assertions where practical; summarize
  key outcomes succinctly.
