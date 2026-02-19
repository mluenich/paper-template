source("R/99_config.R")
cfg <- read_config()

set.seed(cfg$analysis$seed)

infile <- file.path(cfg$paths$derived_data_dir, "data_clean.rds")
outfile <- file.path(cfg$paths$checkpoints_dir, "model.rds")

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- readRDS(infile)

fit <- lm(y ~ x + group, data = dat)
saveRDS(fit, outfile)

message("Wrote: ", outfile)
