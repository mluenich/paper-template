## R/helpers/fmt.R
## Formatting helpers (shared across analysis + manuscript).

strip_leading_zero <- function(x) gsub("^(-?)0\\.", "\\1.", x)

fmt_num <- function(x, d = 3) {
  strip_leading_zero(ifelse(is.na(x), "\u2014", formatC(x, digits = d, format = "f")))
}

## Table cells: "<.001" / ".012"
fmt_p <- function(p, d = 3, thr = 0.001) {
  strip_leading_zero(ifelse(is.na(p), "\u2014",
    ifelse(p < thr, "<.001", formatC(p, digits = d, format = "f"))))
}

## Running text: "< .001" / "= .012", used as $p$ `r fmt_p_inline(x)`
fmt_p_inline <- function(p, d = 3, thr = 0.001) {
  out <- fmt_p(p, d = d, thr = thr)
  ifelse(grepl("^<", out), sub("^<", "< ", out), paste("=", out))
}

## Percent formatter (input already in percent; % sign carried by text/header)
fmt_pct <- function(p, d = 1) ifelse(is.na(p), "n.a.", formatC(p, digits = d, format = "f"))
