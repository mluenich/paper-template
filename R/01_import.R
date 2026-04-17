## R/01_import.R
source("R/00_setup.R")

infile  <- path_raw("example.csv")
outfile <- path_derived(artifacts$import_rds)

if (!file.exists(infile)) stop("Missing input file: ", infile, call. = FALSE)

dat <- readr::read_csv(infile, show_col_types = FALSE,
                       locale = readr::locale(encoding = "UTF-8"))
write_derived(dat, artifacts$import_rds)

message("Wrote: ", outfile)
