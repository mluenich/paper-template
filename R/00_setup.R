## R/00_setup.R
## Shared setup for file-based pipeline:
## - load config (config/params.yml via R/99_config.R)
## - apply global settings (seed/options)
## - define paths + directory creation (so each script can run standalone)
## - load required packages (fail-fast if missing)
## - define shared constants + source helper modules (R/helpers/*.R)

## ---- Helpers ----------------------------------------------------------------
`%||%` <- function(x, y) if (!is.null(x)) x else y

stop_if_missing <- function(path) {
  if (!file.exists(path)) stop("Missing file: ", path, call. = FALSE)
}

ensure_dirs <- function(dirs) {
  for (d in dirs) if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

load_pkgs <- function(pkgs, install = FALSE) {
  for (p in pkgs) {
    if (!requireNamespace(p, quietly = TRUE)) {
      if (isTRUE(install)) {
        install.packages(p)
      } else {
        stop("Missing package: ", p, call. = FALSE)
      }
    }
  }
  invisible(TRUE)
}

## ---- Load config ------------------------------------------------------------
stop_if_missing("R/99_config.R")
source("R/99_config.R")

cfg <- read_config()

## ---- Apply global settings --------------------------------------------------
if (!is.null(cfg$analysis$seed)) set.seed(cfg$analysis$seed)

options(scipen = cfg$analysis$scipen)

FAST_MODE <- isTRUE(cfg$analysis$fast_mode)

## ---- Paths (defaults applied in 99_config.R) --------------------------------
paths <- c(cfg$paths, list(render_output_dir = cfg$render$output_dir))

## Create output directories; raw_data_dir must already exist (no silent
## creation of a mistyped or unmounted external data path).
ensure_dirs(unname(paths[setdiff(names(paths), "raw_data_dir")]))

## ---- Standard artifact filenames (convention) -------------------------------
artifacts <- list(
  import_rds  = "01_import.rds",
  clean_rds   = "02_clean.rds",
  models_rds  = "models.rds",
  tables_rds  = "tables_tex.rds",
  report_rds  = "report.rds"
)

## ---- Packages ---------------------------------------------------------------
## Adjust this list to your project's needs.
required_pkgs <- c(
  "here", "readr", "dplyr", "tidyr", "tibble",
  "ggplot2", "ragg", "knitr", "kableExtra", "rmarkdown", "yaml"
)
if (!is.null(cfg$analysis$weight_var)) required_pkgs <- c(required_pkgs, "survey")

load_pkgs(required_pkgs, install = FALSE)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
})

## ---- Shared constants -------------------------------------------------------
miss_codes <- cfg$analysis$miss_codes

## ---- Helper modules ---------------------------------------------------------
## io.R (paths, RDS I/O, missing codes), fmt.R (number formatting),
## tables.R (LaTeX tables), figures.R (save/include figures),
## survey.R (weighted designs), manuscript.R (word count).
for (.f in sort(list.files("R/helpers", pattern = "\\.R$", full.names = TRUE))) {
  source(.f, local = TRUE)
}
if (exists(".f", inherits = FALSE)) rm(.f)

options(tibble.print_max = Inf)
