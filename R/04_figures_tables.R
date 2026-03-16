## R/04_figures_tables.R
source("R/00_setup.R")

data_file  <- path_derived(artifacts$clean_rds)
model_file <- path_ckpt(artifacts$models_rds)

if (!file.exists(data_file))  stop("Missing input file: ", data_file, call. = FALSE)
if (!file.exists(model_file)) stop("Missing input file: ", model_file, call. = FALSE)

dat <- read_derived(artifacts$clean_rds)
fit <- read_checkpoint(artifacts$models_rds)

library(kableExtra)

## ---- Figures ----------------------------------------------------------------
fig_file <- path_out_fig("figure1.png")

png(fig_file, width = 1600, height = 1200, res = 200)
plot(dat$x, dat$y, xlab = "x", ylab = "y", pch = 19)
abline(fit, lwd = 2)
dev.off()

message("Wrote: ", fig_file)

## ---- Tables (LaTeX objects for manuscript) ----------------------------------
## Collect all kableExtra table objects for use in the .Rmd.
## The manuscript loads this single .rds and references tables_tex$t1, $t2, etc.
tables_tex <- list()

coefs <- as.data.frame(summary(fit)$coefficients)
coefs$term <- rownames(coefs)
rownames(coefs) <- NULL
coefs <- coefs[, c("term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]

tables_tex$t1 <- kbl(coefs,
  format    = "latex",
  booktabs  = TRUE,
  linesep   = "",
  col.names = c("Predictor", "$B$", "SE", "$t$", "$p$"),
  align     = c("l", rep("r", 4)),
  escape    = FALSE,
  caption   = "Regression Results",
  label     = "regression"
) |>
  kable_styling(
    latex_options = "HOLD_position",
    font_size     = 10
  )

saveRDS(tables_tex, path_ckpt("tables_tex.rds"))

## Also save CSV for inspection
write.csv(coefs, path_out_tab("table1.csv"), row.names = FALSE)

message("Wrote: ", path_ckpt("tables_tex.rds"))
message("Wrote: ", path_out_tab("table1.csv"))
