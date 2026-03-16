## R/03_analysis.R
source("R/00_setup.R")

infile  <- path_derived(artifacts$clean_rds)
outfile <- path_ckpt(artifacts$models_rds)

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- read_derived(artifacts$clean_rds)

fit <- lm(y ~ x + group, data = dat)

write_checkpoint(fit, artifacts$models_rds)

message("Wrote: ", outfile)
