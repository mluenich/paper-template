source("R/99_config.R")
cfg <- read_config()

infile <- file.path(cfg$paths$raw_data_dir, "example.csv")
outfile <- file.path(cfg$paths$derived_data_dir, "data_raw.rds")

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- read.csv(infile, stringsAsFactors = FALSE)
saveRDS(dat, outfile)

message("Wrote: ", outfile)
