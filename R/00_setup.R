## R/00_setup.R
## Shared setup for file-based pipeline:
## - load config (config/params.yml via R/99_config.R)
## - apply global settings (seed/options)
## - define paths + directory creation (so each script can run standalone)
## - load required packages (fail-fast if missing)
## - define shared constants + small utility helpers

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

config_path <- Sys.getenv("PAPER_CONFIG", unset = "config/params.yml")
cfg <- read_config()

## ---- Apply global settings --------------------------------------------------
if (!is.null(cfg$analysis$seed)) set.seed(cfg$analysis$seed)

options(scipen = cfg$analysis$scipen %||% 5)

FAST_MODE <- isTRUE(cfg$analysis$fast_mode %||% FALSE)

## ---- Paths (from config with fallbacks) -------------------------------------
paths <- list(
  raw_data_dir      = cfg$paths$raw_data_dir     %||% "data/raw",
  derived_data_dir  = cfg$paths$derived_data_dir %||% "data/derived",
  output_dir        = cfg$paths$output_dir       %||% "output",
  figures_dir       = cfg$paths$figures_dir      %||% file.path("output", "figures"),
  tables_dir        = cfg$paths$tables_dir       %||% file.path("output", "tables"),
  checkpoints_dir   = cfg$paths$checkpoints_dir  %||% file.path("output", "checkpoints"),
  render_output_dir = cfg$render$output_dir      %||% "output"
)

ensure_dirs(unname(paths))

## ---- Standard artifact filenames (convention) -------------------------------
artifacts <- list(
  import_rds  = "01_import.rds",
  clean_rds   = "02_clean.rds",
  models_rds  = "models.rds"
)

## ---- IO wrappers ------------------------------------------------------------
path_raw     <- function(...) file.path(paths$raw_data_dir, ...)
path_derived <- function(...) file.path(paths$derived_data_dir, ...)
path_out_fig <- function(...) file.path(paths$figures_dir, ...)
path_out_tab <- function(...) file.path(paths$tables_dir, ...)
path_ckpt    <- function(...) file.path(paths$checkpoints_dir, ...)

write_derived <- function(x, filename, compress = "xz") {
  saveRDS(x, file = path_derived(filename), compress = compress)
  invisible(path_derived(filename))
}

read_derived <- function(filename) {
  readRDS(path_derived(filename))
}

write_checkpoint <- function(x, filename, compress = "xz") {
  saveRDS(x, file = path_ckpt(filename), compress = compress)
  invisible(path_ckpt(filename))
}

read_checkpoint <- function(filename) {
  readRDS(path_ckpt(filename))
}

## ---- Packages ---------------------------------------------------------------
## Adjust this list to your project's needs.
required_pkgs <- c(
  "here", "readr", "dplyr", "tidyr", "tibble",
  "ggplot2", "knitr", "kableExtra"
)

load_pkgs(required_pkgs, install = FALSE)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
})

## ---- Shared constants -------------------------------------------------------
miss_codes <- cfg$analysis$miss_codes %||% c(-98, -99)

## ---- Small utilities --------------------------------------------------------
recode_missing <- function(df, vars, codes = miss_codes) {
  df %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(vars),
      ~ { x <- .x; if (is.character(x)) return(x); x[x %in% codes] <- NA; x }
    ))
}

## Formatting helpers (shared across analysis + manuscript)
strip_leading_zero <- function(x) gsub("^(-?)0\\.", "\\1.", x)

fmt_num <- function(x, d = 3) {
  strip_leading_zero(ifelse(is.na(x), "\u2014", formatC(x, digits = d, format = "f")))
}

fmt_p <- function(p, d = 3, thr = 0.001) {
  strip_leading_zero(ifelse(is.na(p), "\u2014",
    ifelse(p < thr, "<.001", formatC(p, digits = d, format = "f"))))
}

options(tibble.print_max = Inf)
