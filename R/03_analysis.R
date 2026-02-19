infile <- "data/derived/data_clean.rds"
outfile <- "output/checkpoints/model.rds"

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- readRDS(infile)

fit <- lm(y ~ x + group, data = dat)
saveRDS(fit, outfile)

message("Wrote: ", outfile)
