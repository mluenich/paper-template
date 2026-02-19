infile <- "data/derived/data_raw.rds"
outfile <- "data/derived/data_clean.rds"

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- readRDS(infile)

dat$group <- factor(dat$group)
dat$x <- as.numeric(dat$x)
dat$y <- as.numeric(dat$y)

saveRDS(dat, outfile)

message("Wrote: ", outfile)
