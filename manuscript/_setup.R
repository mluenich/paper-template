## manuscript/_setup.R
## Shared setup for paper.Rmd and appendix.Rmd (sourced in their setup chunk).
## Loads pre-built pipeline artifacts only; no computation here.
## Designed to be rendered by R/00_run_all.R (pipeline 01-04 has run).

## Evaluate chunk code from the project root (where R/00_setup.R expects to
## run); knitr restores the working directory per chunk.
knitr::opts_knit$set(root.dir = here::here())

knitr::opts_chunk$set(
  echo       = FALSE,
  warning    = FALSE,
  message    = FALSE,
  fig.align  = "center",
  fig.pos    = "H",
  out.width  = "100%",
  dpi        = 300
)

## 00_setup.R uses project-relative paths; run it from the project root.
local({
  owd <- setwd(here::here())
  on.exit(setwd(owd))
  source("R/00_setup.R", local = globalenv())
})

## ---- Pipeline artifacts -----------------------------------------------------
library(kableExtra)
tables_tex <- readRDS(abs_path(path_ckpt(artifacts$tables_rds)))  # tables_tex$t1, ...
rpt        <- readRDS(abs_path(path_ckpt(artifacts$report_rds)))  # inline values

## Formatting helpers (fmt_num, fmt_p, fmt_p_inline, fmt_pct) and
## fig_include() are available via 00_setup.R.
