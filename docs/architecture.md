# Architecture — Paper Template

> Context-reconstruction file for LLM sessions. Read instead of scanning source files.

## Goal

Linear R pipeline (import → clean → analyse → figures/tables) + R Markdown manuscript rendering from pre-built artifacts. All paths/seeds/switches in `config/params.yml`; no hardcoded paths.

## Structure

```
config/params.yml          # paths, analysis params, render switches
data/raw/                  # immutable inputs (tracked)
data/derived/              # pipeline .rds outputs (gitignored)
R/99_config.R              # YAML reader + defaults
R/00_setup.R               # shared setup: cfg, paths, packages, helpers
R/00_run_all.R             # orchestrator: pipeline + render
R/01_import.R              # raw → derived
R/02_clean.R               # cleaning, recoding
R/03_analysis.R            # models → checkpoint
R/04_figures_tables.R      # figures (PNG) + LaTeX table objects (RDS)
R/10_appendix.R            # supplementary analyses (stub)
manuscript/paper.Rmd       # manuscript — display only, no computation
manuscript/references.bib  # BibTeX
output/{figures,tables,checkpoints}/  # all gitignored, reproducible
docs/architecture.md       # this file
```

## Pipeline Flow

```
source("R/00_run_all.R")
  ├─ source("R/00_setup.R")          → cfg, paths, artifacts, helpers
  ├─ source("R/01_import.R")         → data/derived/01_import.rds
  ├─ source("R/02_clean.R")          → data/derived/02_clean.rds
  ├─ source("R/03_analysis.R")       → output/checkpoints/models.rds
  ├─ source("R/04_figures_tables.R") → output/figures/figure1.png
  │                                   → output/checkpoints/tables_tex.rds
  │                                   → output/tables/table1.csv
  ├─ (if exists) source("R/10_appendix.R")
  └─ rmarkdown::render(paper.Rmd)    → output/<YYYYMMDD>_paper.pdf
```

Each pipeline script sources `00_setup.R` and runs standalone. Scripts execute in `new.env()`; setup loads into `globalenv()`.

## Config (`params.yml`)

| Section    | Keys | Purpose |
|------------|------|---------|
| `paths`    | `raw_data_dir`, `derived_data_dir`, `output_dir`, `figures_dir`, `tables_dir`, `checkpoints_dir` | directories |
| `analysis` | `seed`, `fast_mode`, `scipen`, `miss_codes` | analysis globals |
| `render`   | `enable`, `input`, `output_dir`, `date_prefix` | render control |

Override: `Sys.setenv(PAPER_CONFIG = "config/params_alt.yml")`.

`99_config.R`: `read_config(path) → list` — reads YAML, applies defaults for missing fields.

## `00_setup.R` Exports

Sourced by every script. Side effects: `set.seed()`, `options(scipen)`, creates output dirs, attaches `dplyr`/`tidyr`/`tibble`.

| Export | Description |
|--------|-------------|
| `cfg` | parsed config list |
| `paths` | named list of 7 directory paths |
| `artifacts` | filenames: `import_rds`, `clean_rds`, `models_rds` |
| `FAST_MODE` | logical from config |
| `miss_codes` | numeric vector, default `c(-98, -99)` |
| `path_raw/derived/out_fig/out_tab/ckpt(...)` | path builders via `file.path()` |
| `write_derived(x, fn)` / `read_derived(fn)` | RDS I/O to `data/derived/` |
| `write_checkpoint(x, fn)` / `read_checkpoint(fn)` | RDS I/O to `output/checkpoints/` |
| `recode_missing(df, vars, codes)` | replace `miss_codes` with `NA` |
| `fmt_num(x, d=3)` | format numeric, strip leading zero, NA → em-dash |
| `fmt_p(p, d=3, thr=.001)` | format p-value, `< .001` threshold |
| `stop_if_missing(path)` | fail if file absent |
| `ensure_dirs(dirs)` | mkdir -p |
| `load_pkgs(pkgs, install)` | fail-fast package check |
| `%||%` | null-coalescing |

Required packages: `here`, `readr`, `dplyr`, `tidyr`, `tibble`, `ggplot2`, `knitr`, `kableExtra`.

## `00_run_all.R`

Flags: `use_renv` (default `FALSE`), `render_manuscript` (default `TRUE`, AND-ed with `cfg$render$enable`). Saves/restores `warn` via `on.exit()`. Detects `.qmd` vs `.Rmd` for render engine. `add_date_prefix()` renames output with `YYYYMMDD_` if configured.

## Pipeline Modules

| Script | Input | Output | Logic |
|--------|-------|--------|-------|
| `01_import` | `data/raw/example.csv` | `data/derived/01_import.rds` | `readr::read_csv()` (UTF-8) |
| `02_clean` | `01_import.rds` | `02_clean.rds` | type coercion; `recode_missing()` available |
| `03_analysis` | `02_clean.rds` | `models.rds` | `lm(y ~ x + group)` (example) |
| `04_figures_tables` | `02_clean.rds` + `models.rds` | `figure1.png`, `tables_tex.rds`, `table1.csv` | base plot → PNG; `kbl(format="latex")` → named list |
| `10_appendix` | — | — | stub; auto-sourced if present |

Table convention: `tables_tex$t1`, `$t2`, etc. Labels via `kbl(... label = "x")` → `\ref{tab:x}`.

## Manuscript (`paper.Rmd`)

PDF via `xelatex`, `keep_tex: true` (gitignored), `number_sections: true`, 12pt, 1.5 spacing, 2.5cm margins. LaTeX packages: booktabs, longtable, array, float, amsmath, graphicx, setspace, geometry, threeparttable(x), multirow, rotating, caption.

`root.dir = here::here()`. Setup chunk sources `00_setup.R`, loads `dat`, `fit`, `tables_tex` from pre-built artifacts. Tables via `results='asis'` chunks. Figures via `knitr::include_graphics(path_out_fig(...))`. Cross-refs: `\ref{tab:...}` / `\ref{fig:...}` (LaTeX native). Bibliography via Pandoc citeproc; CSL slot commented out.

Sections: Abstract `{-}` → Introduction (§1) → Method → Results → Discussion → Conclusion → References.

## Customisation Checklist

1. Replace `data/raw/example.csv`; adapt `01_import.R`
2. Expand `02_clean.R` (recoding, filtering, variable construction)
3. Replace model in `03_analysis.R`
4. Add figures/tables in `04_figures_tables.R` + corresponding chunks in `paper.Rmd`
5. Edit `required_pkgs` in `00_setup.R`
6. Adjust `config/params.yml`
7. Manuscript metadata: title, author, CSL in `paper.Rmd` YAML
8. Populate `references.bib`; uncomment `csl:` if needed
9. Expand `R/10_appendix.R` for supplementary analyses

## Design Notes

- Table labels from `kbl(label=)` → `\label{tab:...}`; figure labels from chunk name → `\label{fig:...}`. Two different mechanisms.
- `here::here()` requires `.Rproj` or `.here` marker (present).
- No `renv.lock` shipped; user must init renv and `renv::snapshot()` separately.
