## R/helpers/tables.R
## LaTeX table helpers for kableExtra objects stored in tables_tex.rds.

## Double all backslashes. footnote(escape = FALSE) strips one backslash level
## (tested with kbl escape = TRUE and FALSE), so LaTeX in notes needs esc4().
esc4 <- function(x) gsub("\\\\", "\\\\\\\\", x)

## Standard manuscript table: booktabs, no row spacing, held in place, 10pt,
## optional APA-style note via threeparttable. `note` is written with single
## LaTeX escaping as in kbl() cells ("$\\beta$"); esc4() is applied
## automatically.
tbl_tex <- function(x, caption, label,
                    col.names  = names(x),
                    align      = NULL,
                    escape     = FALSE,
                    note       = NULL,
                    font_size  = 10,
                    scale_down = FALSE,
                    ...) {
  kb <- kableExtra::kbl(x,
    format    = "latex",
    booktabs  = TRUE,
    linesep   = "",
    col.names = col.names,
    align     = align,
    escape    = escape,
    caption   = caption,
    label     = label,
    ...
  )
  opts <- "HOLD_position"
  if (isTRUE(scale_down)) opts <- c(opts, "scale_down")
  kb <- kableExtra::kable_styling(kb, latex_options = opts, font_size = font_size)

  if (!is.null(note)) {
    kb <- kableExtra::footnote(kb,
      general            = esc4(note),
      general_title      = "Note.",                  # italicised by kableExtra
      footnote_as_chunk  = TRUE,
      threeparttable     = TRUE,
      escape             = FALSE
    )
  }
  kb
}
