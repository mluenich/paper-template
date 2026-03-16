## R/02_clean.R
source("R/00_setup.R")

infile  <- path_derived(artifacts$import_rds)
outfile <- path_derived(artifacts$clean_rds)

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- read_derived(artifacts$import_rds)

## Example cleaning steps
dat$group <- factor(dat$group)
dat$x <- as.numeric(dat$x)
dat$y <- as.numeric(dat$y)

## Use recode_missing() from 00_setup.R for survey-coded missingness
## dat <- recode_missing(dat, vars = c("x", "y"))

write_derived(dat, artifacts$clean_rds)

message("Wrote: ", outfile)
