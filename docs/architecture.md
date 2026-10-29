# Architecture — Paper Template

## TL;DR — Session Bootstrap

Reproducible empirical-paper template: linear R pipeline + R Markdown manuscripts. Entry point: `source("R/00_run_all.R")`. Template version: `config/params.yml` → `template_version` (history in `CHANGELOG.md`). Working rules: `CLAUDE.md`.

**Execution order:** `00_setup.R` → `01_import.R` → `02_clean.R` → `03_analysis.R` → `04_figures_tables.R` → (optional `10_appendix.R`) → render `paper.Rmd` + `appendix.Rmd` → word count → `session_info.txt`.

**Config:** `config/params.yml` (+ gitignored `config/params.local.yml`, merged over it): paths, seed, weights, figure size, render switches, OSF whitelist. Defaults only in `R/99_config.R`. No script hardcodes paths.

**Data flow:** `data/raw/` → `data/derived/*.rds` → `output/checkpoints/*.rds` (models, `tables_tex.rds`, `report.rds`) + `output/figures/` + `output/tables/` → `output/YYMMDD_paper.pdf`, `YYMMDD_appendix.pdf`. Manuscripts load pre-built artifacts only; they never compute.

**Editing a new paper:** replace raw data + adapt `01_import.R`; expand `02_clean.R`; replace model in `03_analysis.R`; build figures (`save_fig()`), tables (`tbl_tex()`) and inline values (`rpt`) in `04_figures_tables.R`; add chunks in `paper.Rmd` / `appendix.Rmd`; update `params.yml`, `references.bib`, title/author.

**Conventions to preserve:** I/O via `path_*()` / `abs_path()` / `write_derived()` / `write_checkpoint()`; artifact names in `artifacts`; tables `tables_tex$t1`, `$tA1` via `tbl_tex()`; figures in `.Rmd` only via `fig_include()`; inline numbers only from `rpt`; LaTeX cross-refs (`\ref{tab:...}`, `\ref{fig:<chunk>}`); `$t$` and `$p$` column labels; fail-fast on missing packages; `use_renv <- FALSE`; LF line endings.

**Current placeholders:** `example.csv` (toy data), example `lm()` in `03_analysis.R`, one figure/table/report list in `04_figures_tables.R`, manuscript sections `[TODO]`, `10_appendix.R` stub, author `[Author 1]`. No `renv.lock` shipped.

---

*The rest of this file is reference material. Read on demand, not every session.*

## Structure

```
config/params.yml          # paths, analysis, figures, render, osf
config/params.local.yml    # optional, gitignored: machine-specific overrides
data/raw/                  # inputs; gitignored except .gitkeep + example.csv
data/derived/              # pipeline .rds outputs (gitignored)
R/99_config.R              # YAML reader + local merge + all defaults
R/00_setup.R               # shared setup: cfg, paths, artifacts, packages, sources R/helpers/
R/00_run_all.R             # orchestrator: pipeline + render + word count + session info
R/01_import.R              # raw → derived
R/02_clean.R               # cleaning, recoding
R/03_analysis.R            # models → checkpoint
R/04_figures_tables.R      # figures (PNG/PDF), tables_tex.rds, report.rds, CSV
R/10_appendix.R            # supplementary analyses (stub)
R/99_export_osf.R          # manual: OSF reproduction zip (whitelist, no raw data)
R/helpers/                 # io, fmt, tables, figures, survey, manuscript
manuscript/_setup.R        # shared setup chunk code for both .Rmd files
manuscript/paper.Rmd       # manuscript — display only
manuscript/appendix.Rmd    # standalone online appendix (A-numbered)
manuscript/references.bib  # BibTeX
manuscript/apa.csl         # APA 7 citation style
output/                    # all gitignored, reproducible
docs/architecture.md       # this file
CLAUDE.md, CHANGELOG.md, .gitattributes, .editorconfig
```

## Pipeline Flow

```
source("R/00_run_all.R")
  ├─ (optional) renv restore
  ├─ source("R/00_setup.R")          → cfg, paths, artifacts, helpers (globalenv)
  ├─ source("R/01_import.R")         → data/derived/01_import.rds
  ├─ source("R/02_clean.R")          → data/derived/02_clean.rds
  ├─ source("R/03_analysis.R")       → output/checkpoints/models.rds
  ├─ source("R/04_figures_tables.R") → output/figures/figure1.png
  │                                   → output/checkpoints/tables_tex.rds
  │                                   → output/checkpoints/report.rds
  │                                   → output/tables/table1.csv
  ├─ (if exists) source("R/10_appendix.R")
  ├─ for each render$inputs (× blind if render$anonymous):
  │     rmarkdown::render()          → output/YYMMDD_<stem>[_blind].pdf (+ .tex)
  ├─ word_count_rmd()                → output/word_count.txt
  └─ session info                    → output/session_info.txt
```

Each pipeline script sources `00_setup.R` and runs standalone. Scripts execute in `new.env()`; setup loads into `globalenv()`. `options(warn = 1)` during the run, reset at the end.

## Config (`params.yml`)

| Section | Keys | Purpose |
|---|---|---|
| top level | `template_version` | template version of this project |
| `paths` | `raw_data_dir`, `derived_data_dir`, `output_dir`, `figures_dir`, `tables_dir`, `checkpoints_dir` | directories |
| `analysis` | `seed`, `fast_mode`, `scipen`, `miss_codes`, `weight_var` | analysis globals; `weight_var` enables survey helpers |
| `figures` | `width`, `height` (in), `dpi`, `pdf` | `save_fig()` defaults |
| `render` | `enable`, `inputs`, `output_dir`, `date_prefix`, `anonymous`, `word_count` | render control |
| `osf` | `include`, `include_derived`, `include_output` | whitelist for `99_export_osf.R` |

Override: `Sys.setenv(PAPER_CONFIG = "config/params_alt.yml")`. `config/params.local.yml` (or `<name>.local.yml` next to the active config) is merged via `utils::modifyList()`.

`99_config.R`: `read_config(path) → list`: reads YAML, merges local overrides, applies all defaults (old key `render$input` still accepted).

## `00_setup.R` Exports

Side effects: `set.seed()`, `options(scipen)`, creates output dirs (not `raw_data_dir`), attaches `dplyr`/`tidyr`/`tibble`, sources `R/helpers/*.R`.

| Export | Description |
|---|---|
| `cfg` | parsed config list |
| `paths` | `cfg$paths` + `render_output_dir` |
| `artifacts` | `import_rds`, `clean_rds`, `models_rds`, `tables_rds`, `report_rds` |
| `FAST_MODE`, `miss_codes` | from config |
| `stop_if_missing`, `ensure_dirs`, `load_pkgs`, `%||%` | guards, dir creation, package check, null-coalescing |

Required packages: `here`, `readr`, `dplyr`, `tidyr`, `tibble`, `ggplot2`, `ragg`, `knitr`, `kableExtra`, `rmarkdown`, `yaml` (+ `survey` if `weight_var` set; `zip` for OSF export).

## Helpers (`R/helpers/`)

| File | Functions |
|---|---|
| `io.R` | `path_raw/derived/out_fig/out_tab/ckpt(...)`, `write_derived(x, fn)` / `read_derived(fn)`, `write_checkpoint(x, fn)` / `read_checkpoint(fn)`, `abs_path(p)` (anchor at project root), `recode_missing(df, vars, codes)` |
| `fmt.R` | `fmt_num(x, d=3, lead0=FALSE)` (strips leading zero unless `lead0 = TRUE`, NA → dash), `fmt_p(p)` (table: `<.001`), `fmt_p_inline(p)` (text: `< .001` / `= .012`), `fmt_pct(p, d=1)` (input in %, no sign) |
| `tables.R` | `esc4(x)`, `tbl_tex(x, caption, label, col.names, align, escape = FALSE, note, font_size = 10, scale_down = FALSE, ...)` |
| `figures.R` | `save_fig(plot, filename, width, height, dpi, pdf)`, `fig_include(filename)` |
| `survey.R` | `make_design(df, weighted)`, `w_desc(df, vars)`, `w_props(df, var)`, `gm_table(df, y, by)` |
| `manuscript.R` | `word_count_rmd(file)` → `file`, `abstract`, `main_text` |

## Pipeline Modules

| Script | Input | Output | Logic |
|---|---|---|---|
| `01_import` | `data/raw/example.csv` | `01_import.rds` | `readr::read_csv()` (UTF-8); `haven::read_sav()` example commented |
| `02_clean` | `01_import.rds` | `02_clean.rds` | type coercion; `recode_missing()` available |
| `03_analysis` | `02_clean.rds` | `models.rds` | `lm(y ~ x + group)` (example) |
| `04_figures_tables` | `02_clean.rds` + `models.rds` | `figure1.png`, `tables_tex.rds`, `report.rds`, `table1.csv` | ggplot2 → `save_fig()`; `tbl_tex()` → named list; formatted inline values |
| `10_appendix` | (none) | (none) | stub; may append `tables_tex$tA*` |
| `99_export_osf` | whitelist | `output/YYMMDD_osf_package.zip` | manual; excludes raw data and local config |

## Manuscripts (`paper.Rmd`, `appendix.Rmd`)

PDF via `xelatex`, `keep_tex: true`, `number_sections: true`, 12pt, 1.5 spacing, 2.5 cm margins, APA 7 via `csl: apa.csl` + Pandoc citeproc. LaTeX packages: booktabs, longtable, array, float, amsmath, graphicx, setspace, geometry, threeparttable(x), multirow, rotating, caption.

Setup chunk sources `manuscript/_setup.R`: sets `root.dir = here::here()` and chunk options, sources `00_setup.R` from the project root (scoped `setwd`, restored), loads `tables_tex` and `rpt`. Tables via `results='asis'` chunks; figures via `fig_include()`; inline values via `` `r rpt$...` ``.

`params: anonymous` (set by `00_run_all.R`) switches the author line for the blind version. `appendix.Rmd` numbers sections A, B, … and tables/figures A1, A2, … .

Sections (paper): Abstract `{-}` → Introduction (§1) → Method → Results → Discussion → Conclusion → References `{-}`.

## Design Notes

- Table labels from `kbl(label=)` → `\label{tab:...}`; figure labels from chunk name → `\label{fig:<chunk>}`.
- `fig_include()` passes an absolute path with `error = FALSE`: knitr writes `../output/figures/...` (no spaces from the Windows project path; resolved from the build dir). Do not reintroduce `tempdir()` copies.
- `tbl_tex()` always applies `esc4()` to the note, because `footnote(escape = FALSE)` strips one backslash level (independent of `kbl(escape)`). Write notes with single escaping as in cells (`"$\\beta$"`).
- APA leading zero: `fmt_num(..., lead0 = TRUE)` for values that can exceed 1 (B, SE, t, M, SD); default strips it (r, β, α, R², p).
- `here::here()` requires `.Rproj` or `.here` marker (present).
- Word count is source-based (approximation): inline R, citation keys and `\ref{}` count as one word each.
- No `renv.lock` shipped; user must init renv and `renv::snapshot()` separately.
