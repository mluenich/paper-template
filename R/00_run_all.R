use_renv <- FALSE
render_manuscript <- TRUE

manuscript_file_rmd <- "manuscript/paper.Rmd"
render_output_dir <- "output"

options(warn = 1)

stop_if_missing <- function(path) {
  if (!file.exists(path)) stop("Missing file: ", path, call. = FALSE)
}

run_step <- function(label, expr) {
  message("\n==> ", label)
  t0 <- Sys.time()
  force(expr)
  t1 <- Sys.time()
  message("Done: ", label, " (", round(as.numeric(difftime(t1, t0, units = "secs")), 1), "s)")
}

ensure_dirs <- function(dirs) {
  for (d in dirs) if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

script_dir <- tryCatch(normalizePath(dirname(sys.frame(1)$ofile)), error = function(e) NA_character_)
if (!is.na(script_dir) && basename(script_dir) == "R") {
  setwd(dirname(script_dir))
}

ensure_dirs(c(
  "data/raw",
  "data/derived",
  "output/figures",
  "output/tables",
  "output/checkpoints"
))

if (use_renv && file.exists("renv.lock")) {
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  run_step("renv::restore()", renv::restore(prompt = FALSE))
}

stop_if_missing("R/01_import.R")
stop_if_missing("R/02_clean.R")
stop_if_missing("R/03_analysis.R")
stop_if_missing("R/04_figures_tables.R")

run_step("01_import.R", source("R/01_import.R", local = new.env()))
run_step("02_clean.R", source("R/02_clean.R", local = new.env()))
run_step("03_analysis.R", source("R/03_analysis.R", local = new.env()))
run_step("04_figures_tables.R", source("R/04_figures_tables.R", local = new.env()))

if (render_manuscript) {
  stop_if_missing(manuscript_file_rmd)
  if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")

  date_prefix <- format(Sys.Date(), "%Y%m%d_")

  add_date_prefix <- function(out_file) {
    if (length(out_file) < 1 || is.null(out_file) || is.na(out_file[1])) {
      stop("Render did not return an output file path.", call. = FALSE)
    }
    out_file <- out_file[1]
    if (!file.exists(out_file)) {
      stop("Rendered file not found: ", out_file, call. = FALSE)
    }
    new_file <- file.path(dirname(out_file), paste0(date_prefix, basename(out_file)))
    if (file.exists(new_file)) file.remove(new_file)
    ok <- file.rename(out_file, new_file)
    if (!ok) stop("Failed to rename output to: ", new_file, call. = FALSE)
    new_file
  }

  run_step("Knit R Markdown manuscript", {
    out_file <- rmarkdown::render(
      input = manuscript_file_rmd,
      output_dir = render_output_dir,
      clean = TRUE
    )
    add_date_prefix(out_file)
  })
}

message("\nAll done.")
