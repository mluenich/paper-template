# Changelog

Template version is recorded in `config/params.yml` (`template_version`) and as
Git tag `vX.Y.Z`. Projects derived from the template keep their version entry,
so fixes can be traced and backported.

## 1.1.0 (2026-10-29)

### Fixed
- PDF render failed: figures are now included via `fig_include()` (absolute
  path, `error = FALSE`), so LaTeX resolves `../output/figures/...` from the
  build directory.
- Removed persistent `setwd()` from the manuscript setup chunk.
- `options(warn = 1)` in `00_run_all.R` was reset immediately by a top-level
  `on.exit()`; now reset explicitly at the end of the script.
- Example regression table now uses `fmt_num()`/`fmt_p()`.
- References section unnumbered (APA).
- Example figure: ggplot2 with fitted lines per group (replaces `abline()` on a
  three-coefficient model).

### Changed
- Fail-fast everywhere: no silent `install.packages()` for `yaml`,
  `rmarkdown`, `quarto`; `yaml`, `rmarkdown`, `ragg` added to `required_pkgs`.
- Config defaults live only in `R/99_config.R`; `00_setup.R` uses
  `cfg$paths` directly. `raw_data_dir` is no longer auto-created.
- Date prefix of rendered files: `YYMMDD_`.
- Helpers moved from `00_setup.R` to `R/helpers/` (`io.R`, `fmt.R`,
  `tables.R`, `figures.R`, `survey.R`, `manuscript.R`).
- `render$input` replaced by `render$inputs` (list; old key still read).
- Manuscript setup shared via `manuscript/_setup.R`; manuscripts load
  `tables_tex.rds` and `report.rds` only.

### Added
- `tbl_tex()` and `esc4()` (APA table with threeparttable note; LaTeX in notes
  is escaped automatically).
- `fmt_p_inline()` (running text), `fmt_pct()`; `fmt_num(lead0 = TRUE)` keeps
  the leading zero (APA: B, SE, t, M, SD).
- `save_fig()` (ragg PNG, optional PDF; size/DPI from `figures` config).
- Survey helpers (`make_design()`, `w_desc()`, `w_props()`, `gm_table()`),
  active when `analysis$weight_var` is set.
- `report.rds`: pre-formatted inline values for the manuscript.
- `manuscript/appendix.Rmd` (standalone, A-numbered), `manuscript/apa.csl`
  (APA 7, CC BY-SA 3.0, citation-style-language/styles).
- Blind version (`render$anonymous`), word count (`render$word_count`,
  `output/word_count.txt`), `output/session_info.txt` (sessionInfo, Git commit).
- `R/99_export_osf.R`: whitelist-based OSF reproduction zip without raw data.
- `config/params.local.yml` (gitignored) merged over `params.yml`.
- `.gitattributes` (LF), `CLAUDE.md` (working rules for LLM sessions).
- `.gitignore`: raw data except example, local config, knitr/LaTeX
  intermediates; `*.tex` restricted to `manuscript/`.

## 1.0.0

Baseline (commit `00f1338`): linear R pipeline + R Markdown manuscript, YAML
config layer, `docs/architecture.md`.
