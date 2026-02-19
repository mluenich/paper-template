source("R/99_config.R")
cfg <- read_config()

infile <- file.path(cfg$paths$derived_data_dir, "data_raw.rds")
outfile <- file.path(cfg$paths$derived_data_dir, "data_clean.rds")

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- readRDS(infile)

dat$group <- factor(dat$group)
dat$x <- as.numeric(dat$x)
dat$y <- as.numeric(dat$y)

saveRDS(dat, outfile)

message("Wrote: ", outfile)
