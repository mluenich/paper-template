## R/00_run_all.R

## ---- Settings ---------------------------------------------------------------
use_renv <- FALSE

## Optional local override (config still applies)
render_manuscript <- TRUE

## Warnings (1 = print as they occur; 2 = turn warnings into errors)
## (reset at the end of this script; on.exit() does not work at top level)
.warn_prev <- getOption("warn")
options(warn = 1)

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

## ---- Render manuscript(s) (from config) -------------------------------------
render_manuscript <- isTRUE(render_manuscript) && isTRUE(cfg$render$enable)

if (render_manuscript) {

  manuscript_inputs <- cfg$render$inputs
  for (f in manuscript_inputs) stop_if_missing(f)

  add_date_prefix <- function(out_file) {
    if (!isTRUE(cfg$render$date_prefix)) return(out_file)

    date_prefix <- format(Sys.Date(), "%y%m%d_")

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

  ## Versions: regular, plus *_blind (author info hidden) if render$anonymous
  versions <- list(list(suffix = "", anonymous = FALSE))
  if (isTRUE(cfg$render$anonymous)) {
    versions <- c(versions, list(list(suffix = "_blind", anonymous = TRUE)))
  }

  for (manuscript_input in manuscript_inputs) {

    manuscript_type <- if (grepl("\\.qmd$", manuscript_input, ignore.case = TRUE)) {
      "quarto"
    } else {
      "rmarkdown"
    }
    stem <- tools::file_path_sans_ext(basename(manuscript_input))

    for (v in versions) {
      label <- paste0(basename(manuscript_input), if (v$anonymous) " (blind)" else "")

      if (manuscript_type == "quarto") {
        if (!requireNamespace("quarto", quietly = TRUE)) {
          stop("Missing package: quarto", call. = FALSE)
        }

        run_step(paste("Render Quarto:", label), {
          out_file <- quarto::quarto_render(
            input          = manuscript_input,
            output_dir     = cfg$render$output_dir,
            output_file    = paste0(stem, v$suffix, ".pdf"),
            execute_params = list(anonymous = v$anonymous)
          )
          add_date_prefix(out_file)
        })

      } else {
        run_step(paste("Knit R Markdown:", label), {
          out_file <- rmarkdown::render(
            input       = manuscript_input,
            output_dir  = cfg$render$output_dir,
            output_file = paste0(stem, v$suffix),
            params      = list(anonymous = v$anonymous),
            envir       = new.env(),
            clean       = TRUE
          )
          add_date_prefix(out_file)
        })
      }
    }
  }

  ## ---- Word count (source-based approximation, see R/helpers/manuscript.R) --
  if (isTRUE(cfg$render$word_count)) {
    wc <- do.call(rbind, lapply(manuscript_inputs, word_count_rmd))
    wc_file <- file.path(cfg$render$output_dir, "word_count.txt")
    writeLines(c(
      paste("Word count (approximate), generated", format(Sys.time(), "%Y-%m-%d %H:%M")),
      "Main text excludes abstract, keywords, tables, figures, references.",
      "",
      utils::capture.output(print(wc, row.names = FALSE))
    ), wc_file)
    message("\nWord count:\n", paste(utils::capture.output(print(wc, row.names = FALSE)),
                                     collapse = "\n"))
  }
}

## ---- Session info (reproducibility record) ----------------------------------
## NULL if git is unavailable or this is not a repository
git_info <- function(args) {
  out <- tryCatch(suppressWarnings(system2("git", args, stdout = TRUE, stderr = FALSE)),
                  error = function(e) NULL)
  if (!is.null(attr(out, "status"))) NULL else out
}
git_hash  <- git_info(c("rev-parse", "--short", "HEAD"))
git_dirty <- git_info(c("status", "--porcelain"))
git_line  <- if (length(git_hash) == 0) {
  "n/a"
} else {
  paste(git_hash[1], if (length(git_dirty) > 0) "(uncommitted changes)" else "(clean)")
}
writeLines(c(
  paste("Run:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("Template version:", cfg$template_version),
  paste("Git commit:", git_line),
  paste("Config:", config_path_default(),
        if (!is.null(cfg$local_config)) paste("+", cfg$local_config) else ""),
  "",
  utils::capture.output(utils::sessionInfo())
), file.path(paths$output_dir, "session_info.txt"))

options(warn = .warn_prev)
message("\nAll done.")
