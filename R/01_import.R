infile <- "data/raw/example.csv"
outfile <- "data/derived/data_raw.rds"

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- read.csv(infile, stringsAsFactors = FALSE)
saveRDS(dat, outfile)

message("Wrote: ", outfile)
