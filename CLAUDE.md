# Working rules for LLM sessions

Structure, data flow and conventions: read the TL;DR of `docs/architecture.md`
first; read the rest only on demand.

## Editing
- KAMAI: keep the user's code and prose verbatim; make targeted diffs, no
  stylistic rewrites. When the user supplies a modified file, adopt it as the
  new base and apply only the requested change.
- `R/01_import.R`: only additive edits, explicitly flagged in the reply.
- No hardcoded paths: use `path_*()`, `abs_path()`, `write_derived()`,
  `write_checkpoint()`; new artifacts go into `artifacts` in `R/00_setup.R`.
- The manuscript only displays: numbers come from `report.rds`, tables from
  `tables_tex.rds`, figures via `fig_include()`. No computation in `.Rmd`.
- Tables via `tbl_tex()`; result tables label statistics `$t$` and `$p$`.
- Keep `use_renv <- FALSE` in `R/00_run_all.R`.

## Style
- Code, comments, manuscript, docs: English. Discussion with the user: German.
- No em-dashes in generated prose.
- Line endings LF, UTF-8 (`.gitattributes`, `.editorconfig`).

## Verification and delivery
- Verify changes by running `source("R/00_run_all.R")` (pipeline + PDF).
- Report and deliver only the files that changed.
- Update `docs/architecture.md` and `CHANGELOG.md` when structure or
  conventions change; bump `template_version` in `config/params.yml`.
