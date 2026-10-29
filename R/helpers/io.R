## R/helpers/io.R
## Path builders, RDS I/O, survey missing-code recoding.
## Sourced by R/00_setup.R (requires `paths`, `miss_codes`).

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

## Absolute path: project-relative paths are anchored at the project root
## (works regardless of the current working directory, e.g. in .Rmd chunks).
abs_path <- function(p) {
  ifelse(grepl("^(/|\\\\|[A-Za-z]:)", p), p, here::here(p))
}

## ---- Small utilities --------------------------------------------------------
recode_missing <- function(df, vars, codes = miss_codes) {
  df %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(vars),
      ~ { x <- .x; if (is.character(x)) return(x); x[x %in% codes] <- NA; x }
    ))
}
