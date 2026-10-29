## R/99_config.R
## Reads config/params.yml and returns a list with defaults applied.
## Single source of truth for defaults; 00_setup.R does not repeat them.
## If config/params.local.yml exists (gitignored), it is merged over the
## main config (machine-specific paths, e.g. local vs. Sciebo data).

config_path_default <- function() {
  Sys.getenv("PAPER_CONFIG", unset = "config/params.yml")
}

read_config <- function(path = config_path_default()) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Missing package: yaml", call. = FALSE)
  }
  if (!file.exists(path)) stop("Missing config file: ", path, call. = FALSE)

  cfg <- yaml::read_yaml(path)

  local_path <- sub("\\.ya?ml$", ".local.yml", path)
  if (file.exists(local_path)) {
    cfg <- utils::modifyList(cfg, yaml::read_yaml(local_path))
    if (!isTRUE(getOption("paper.local_cfg_msg"))) {
      message("Config: merged local overrides from ", local_path)
      options(paper.local_cfg_msg = TRUE)
    }
    cfg$local_config <- local_path
  }

  if (is.null(cfg$paths))    cfg$paths    <- list()
  if (is.null(cfg$analysis)) cfg$analysis <- list()
  if (is.null(cfg$figures))  cfg$figures  <- list()
  if (is.null(cfg$render))   cfg$render   <- list()
  if (is.null(cfg$osf))      cfg$osf      <- list()

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

  if (is.null(cfg$template_version))   cfg$template_version   <- NA_character_

  if (is.null(cfg$analysis$seed))      cfg$analysis$seed      <- 123
  if (is.null(cfg$analysis$fast_mode)) cfg$analysis$fast_mode <- FALSE
  if (is.null(cfg$analysis$scipen))    cfg$analysis$scipen    <- 5
  if (is.null(cfg$analysis$miss_codes)) cfg$analysis$miss_codes <- c(-98, -99)
  ## analysis$weight_var stays NULL unless set

  if (is.null(cfg$figures$width))      cfg$figures$width      <- 6.5
  if (is.null(cfg$figures$height))     cfg$figures$height     <- 4.5
  if (is.null(cfg$figures$dpi))        cfg$figures$dpi        <- 300
  if (is.null(cfg$figures$pdf))        cfg$figures$pdf        <- FALSE

  if (is.null(cfg$render$enable))      cfg$render$enable      <- TRUE
  if (is.null(cfg$render$inputs)) {
    cfg$render$inputs <- if (!is.null(cfg$render$input)) cfg$render$input else "manuscript/paper.Rmd"
  }
  cfg$render$inputs <- unlist(cfg$render$inputs)
  if (is.null(cfg$render$output_dir))  cfg$render$output_dir  <- cfg$paths$output_dir
  if (is.null(cfg$render$date_prefix)) cfg$render$date_prefix <- TRUE
  if (is.null(cfg$render$anonymous))   cfg$render$anonymous   <- FALSE
  if (is.null(cfg$render$word_count))  cfg$render$word_count  <- TRUE

  if (is.null(cfg$osf$include)) {
    cfg$osf$include <- c("R", "config/params.yml", "manuscript", "docs",
                         "README.md", "CHANGELOG.md")
  }
  cfg$osf$include <- unlist(cfg$osf$include)
  if (is.null(cfg$osf$include_derived)) cfg$osf$include_derived <- FALSE
  if (is.null(cfg$osf$include_output))  cfg$osf$include_output  <- TRUE

  cfg
}
