## R/00_run_all.R

## ---- Settings ---------------------------------------------------------------
use_renv <- FALSE

## Optional local override (config still applies)
render_manuscript <- TRUE

## Warnings (1 = print as they occur; 2 = turn warnings into errors)
.warn_prev <- getOption("warn")
options(warn = 1)
on.exit(options(warn = .warn_prev), add = TRUE)

## ---- Helpers ----------------------------------------------------------------
run_step <- function(label, expr) {
  message("\n==> ", label)
  t0 <- Sys.time()
  force(expr)
  t1 <- Sys.time()
  message("Done: ", label, " (",
          round(as.numeric(difftime(t1, t0, units = "secs")), 1), "s)")
}

## ---- Infer project root (robust for sourcing from R/ or project root) -------
script_dir <- tryCatch(
  normalizePath(dirname(sys.frame(1)$ofile)),
  error = function(e) NA_character_
)
if (!is.na(script_dir) && basename(script_dir) == "R") {
  setwd(dirname(script_dir))
}

## ---- Optional: renv restore (BEFORE setup/package loads) --------------------
## ---- Optional: renv restore (BEFORE setup/package loads) --------------------
if (use_renv) {
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  if (file.exists("renv.lock")) {
    run_step("renv::restore()", renv::restore(prompt = FALSE))
  } else {
    run_step("renv::init()", renv::init(bare = TRUE))
    message("No renv.lock found — initialised renv. ",
            "Run renv::snapshot() after installing packages.")
  }
}

## ---- Setup (loads config + paths + packages + helpers) ----------------------
## Sourced into globalenv() so cfg, paths, artifacts, helpers are available
## both here and in the manuscript at render time.
source("R/00_setup.R", local = globalenv())

## ---- Run pipeline steps (isolated envs) -------------------------------------
pipeline_scripts <- c(
  "R/01_import.R",
  "R/02_clean.R",
  "R/03_analysis.R",
  "R/04_figures_tables.R"
)

for (s in pipeline_scripts) {
  stop_if_missing(s)
  run_step(basename(s), source(s, local = new.env()))
}

## ---- Optional appendix scripts ----------------------------------------------
appendix_scripts <- c("R/10_appendix.R")
for (s in appendix_scripts) {
  if (file.exists(s)) {
    run_step(basename(s), source(s, local = new.env()))
  }
}

## ---- Render manuscript (from config) ----------------------------------------
render_manuscript <- isTRUE(render_manuscript) && isTRUE(cfg$render$enable)

if (render_manuscript) {

  manuscript_input <- cfg$render$input
  stop_if_missing(manuscript_input)

  manuscript_type <- if (grepl("\\.qmd$", manuscript_input, ignore.case = TRUE)) {
    "quarto"
  } else {
    "rmarkdown"
  }

  add_date_prefix <- function(out_file) {
    if (!isTRUE(cfg$render$date_prefix)) return(out_file)

    date_prefix <- format(Sys.Date(), "%Y%m%d_")

    if (length(out_file) < 1 || is.null(out_file) || is.na(out_file[1])) {
      stop("Render did not return an output file path.", call. = FALSE)
    }
    out_file <- out_file[1]
    if (!file.exists(out_file)) {
      stop("Rendered file not found: ", out_file, call. = FALSE)
    }
    new_file <- file.path(dirname(out_file),
                          paste0(date_prefix, basename(out_file)))
    if (file.exists(new_file)) file.remove(new_file)
    ok <- file.rename(out_file, new_file)
    if (!ok) stop("Failed to rename output to: ", new_file, call. = FALSE)
    new_file
  }

  if (manuscript_type == "quarto") {
    if (!requireNamespace("quarto", quietly = TRUE)) install.packages("quarto")

    run_step("Render Quarto manuscript", {
      out_file <- quarto::quarto_render(
        input      = manuscript_input,
        output_dir = cfg$render$output_dir
      )
      add_date_prefix(out_file)
    })

  } else {
    if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")

    run_step("Knit R Markdown manuscript", {
      out_file <- rmarkdown::render(
        input      = manuscript_input,
        output_dir = cfg$render$output_dir,
        clean      = TRUE
      )
      add_date_prefix(out_file)
    })
  }
}

message("\nAll done.")
