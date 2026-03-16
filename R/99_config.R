## R/99_config.R
## Reads config/params.yml and returns a list with defaults applied.

config_path_default <- function() {
  Sys.getenv("PAPER_CONFIG", unset = "config/params.yml")
}

read_config <- function(path = config_path_default()) {
  if (!requireNamespace("yaml", quietly = TRUE)) install.packages("yaml")
  if (!file.exists(path)) stop("Missing config file: ", path, call. = FALSE)

  cfg <- yaml::read_yaml(path)

  if (is.null(cfg$paths))    cfg$paths    <- list()
  if (is.null(cfg$analysis)) cfg$analysis <- list()
  if (is.null(cfg$render))   cfg$render   <- list()

  defaults_paths <- list(
    raw_data_dir     = "data/raw",
    derived_data_dir = "data/derived",
    output_dir       = "output",
    figures_dir      = "output/figures",
    tables_dir       = "output/tables",
    checkpoints_dir  = "output/checkpoints"
  )

  for (nm in names(defaults_paths)) {
    if (is.null(cfg$paths[[nm]])) cfg$paths[[nm]] <- defaults_paths[[nm]]
  }

  if (is.null(cfg$analysis$seed))      cfg$analysis$seed      <- 123
  if (is.null(cfg$analysis$fast_mode)) cfg$analysis$fast_mode <- FALSE
  if (is.null(cfg$analysis$scipen))    cfg$analysis$scipen    <- 5
  if (is.null(cfg$analysis$miss_codes)) cfg$analysis$miss_codes <- c(-98, -99)

  if (is.null(cfg$render$enable))      cfg$render$enable      <- TRUE
  if (is.null(cfg$render$input))       cfg$render$input       <- "manuscript/paper.Rmd"
  if (is.null(cfg$render$output_dir))  cfg$render$output_dir  <- cfg$paths$output_dir
  if (is.null(cfg$render$date_prefix)) cfg$render$date_prefix <- TRUE

  cfg
}
