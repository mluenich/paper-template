# Paper template (R Markdown)

Minimal folder structure for writing papers with **R scripts + R Markdown**.

## Structure

- `data/raw/` — raw inputs (do not edit in place)
- `data/derived/` — derived datasets (reproducible outputs of scripts)
- `R/` — analysis pipeline scripts
- `manuscript/` — R Markdown manuscript + bibliography
- `output/` — generated figures/tables/rendered manuscript (safe to delete/rebuild)

## Quick start

1. Open `paper-template.Rproj` in RStudio.
2. Run the full pipeline:

```r
source("R/00_run_all.R")
```

This will:
- create standard folders (if missing)
- run `R/01_import.R` → `R/04_figures_tables.R`
- render `manuscript/paper.Rmd` into `output/`
- rename the rendered file to `yyyymmdd_<originalname>.*`

## Using renv (optional)

If you want pinned package versions:

```r
install.packages("renv")
renv::init()
renv::snapshot()
```

To restore later (e.g., on another machine):

```r
renv::restore()
```

## Notes

- Decide whether to version `data/derived/` outputs in git. Default here is: not versioned.
