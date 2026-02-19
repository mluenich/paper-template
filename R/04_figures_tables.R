data_file <- "data/derived/data_clean.rds"
model_file <- "output/checkpoints/model.rds"

fig_file <- "output/figures/figure1.png"
tab_file <- "output/tables/table1.csv"

if (!file.exists(data_file)) stop("Missing input file: ", data_file, call. = FALSE)
if (!file.exists(model_file)) stop("Missing input file: ", model_file, call. = FALSE)

dat <- readRDS(data_file)
fit <- readRDS(model_file)

png(fig_file, width = 1600, height = 1200, res = 200)
plot(dat$x, dat$y, xlab = "x", ylab = "y", pch = 19)
abline(fit, lwd = 2)
dev.off()

coefs <- as.data.frame(summary(fit)$coefficients)
coefs$term <- rownames(coefs)
rownames(coefs) <- NULL
coefs <- coefs[, c("term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]

write.csv(coefs, tab_file, row.names = FALSE)

message("Wrote: ", fig_file)
message("Wrote: ", tab_file)
