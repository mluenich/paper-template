## R/04_figures_tables.R
source("R/00_setup.R")

data_file  <- path_derived(artifacts$clean_rds)
model_file <- path_ckpt(artifacts$models_rds)

if (!file.exists(data_file))  stop("Missing input file: ", data_file, call. = FALSE)
if (!file.exists(model_file)) stop("Missing input file: ", model_file, call. = FALSE)

dat <- read_derived(artifacts$clean_rds)
fit <- read_checkpoint(artifacts$models_rds)

library(ggplot2)

## ---- Figures ----------------------------------------------------------------
## save_fig() writes PNG (ragg) and, if figures$pdf is TRUE, a vector PDF.
dat$fitted <- fitted(fit)

fig1 <- ggplot(dat, aes(x = x, y = y, colour = group)) +
  geom_point(size = 2) +
  geom_line(aes(y = fitted), linewidth = 0.8) +
  labs(x = "x", y = "y", colour = "Group") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

save_fig(fig1, "figure1.png")

## ---- Tables (LaTeX objects for manuscript) ----------------------------------
## Collect all kableExtra table objects for use in the .Rmd.
## The manuscript loads this single .rds and references tables_tex$t1, $t2, etc.
tables_tex <- list()

coefs <- as.data.frame(summary(fit)$coefficients)
coefs$term <- rownames(coefs)
rownames(coefs) <- NULL
coefs <- coefs[, c("term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]

coefs_fmt <- data.frame(
  term = coefs$term,
  B    = fmt_num(coefs$Estimate, 2),
  SE   = fmt_num(coefs$`Std. Error`, 2),
  t    = fmt_num(coefs$`t value`, 2),
  p    = fmt_p(coefs$`Pr(>|t|)`),
  stringsAsFactors = FALSE
)

tables_tex$t1 <- tbl_tex(coefs_fmt,
  col.names = c("Predictor", "$B$", "SE", "$t$", "$p$"),
  align     = c("l", rep("r", 4)),
  caption   = "Regression Results",
  label     = "regression",
  note      = paste0("OLS regression; $N = ", nrow(dat), "$. ",
                     "Reference category for group: A.")
)

write_checkpoint(tables_tex, artifacts$tables_rds)

## Also save CSV for inspection (unformatted values)
write.csv(coefs, path_out_tab("table1.csv"), row.names = FALSE)

message("Wrote: ", path_ckpt(artifacts$tables_rds))
message("Wrote: ", path_out_tab("table1.csv"))

## ---- Report values (inline numbers for the manuscript) ----------------------
## Named list of pre-formatted strings; paper.Rmd uses `r rpt$...` only.
rpt <- list(
  n      = nrow(dat),
  b_x    = fmt_num(coef(fit)[["x"]], 2),
  t_x    = fmt_num(coefs$`t value`[coefs$term == "x"], 2),
  df_res = fit$df.residual,
  p_x    = fmt_p_inline(coefs$`Pr(>|t|)`[coefs$term == "x"]),
  r2     = fmt_num(summary(fit)$r.squared, 2)
)

write_checkpoint(rpt, artifacts$report_rds)

message("Wrote: ", path_ckpt(artifacts$report_rds))
