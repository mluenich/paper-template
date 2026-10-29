## R/helpers/survey.R
## Weighted survey designs and descriptives (package 'survey').
## Active when config analysis$weight_var is set (00_setup.R then requires
## 'survey'). Unweighted mode uses constant weights, so descriptive and
## inferential results share one code path.

make_design <- function(df, weighted = TRUE, weight_var = cfg$analysis$weight_var) {
  df$.w <- if (weighted && !is.null(weight_var)) df[[weight_var]] else rep(1, nrow(df))
  df <- df[!is.na(df$.w) & df$.w > 0, , drop = FALSE]
  survey::svydesign(ids = ~1, weights = ~.w, data = df)
}

## Weighted M and SD with unweighted valid n, one row per variable.
w_desc <- function(df, vars, weighted = TRUE) {
  des <- make_design(df, weighted)
  rows <- lapply(vars, function(v) {
    f <- stats::as.formula(paste0("~", v))
    m <- survey::svymean(f, des, na.rm = TRUE)
    s <- survey::svyvar(f, des, na.rm = TRUE)
    data.frame(variable = v,
               n  = sum(!is.na(des$variables[[v]])),
               M  = unname(stats::coef(m)),
               SD = sqrt(unname(stats::coef(s))),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

## Unweighted n and weighted percent per level of a categorical variable.
w_props <- function(df, var, weighted = TRUE) {
  des <- make_design(df, weighted)
  x   <- factor(des$variables[[var]])
  des <- stats::update(des, .lvl = x)
  n   <- as.data.frame(table(level = x, useNA = "no"), stringsAsFactors = FALSE)
  p   <- survey::svymean(~.lvl, des, na.rm = TRUE)
  data.frame(variable = var,
             level    = n$level,
             n        = n$Freq,
             pct      = unname(stats::coef(p)) * 100,
             stringsAsFactors = FALSE)
}

## Weighted means with SE/CI and unweighted valid n, by grouping variables.
gm_table <- function(df, y, by, weighted = TRUE) {
  des <- make_design(df, weighted)
  fy  <- stats::as.formula(paste0("~", y))
  fb  <- stats::as.formula(paste0("~", paste(by, collapse = "+")))
  m <- survey::svyby(fy, fb, des, survey::svymean, na.rm = TRUE,
                     vartype = c("se", "ci"), drop.empty.groups = TRUE)
  n <- survey::svyby(fy, fb, des, survey::unwtd.count,
                     drop.empty.groups = TRUE)
  m <- as.data.frame(m)
  n <- as.data.frame(n)
  out <- m
  names(out)[names(out) == y] <- "mean"
  out$n <- n$counts
  rownames(out) <- NULL
  out[out$n > 0, , drop = FALSE]
}
