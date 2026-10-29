## R/helpers/figures.R
## Save figures in the pipeline (04) and include them in the manuscript.

## Save a ggplot as PNG (ragg) and optionally as vector PDF (cairo).
## Size/DPI default to config/params.yml -> figures.
save_fig <- function(plot, filename,
                     width  = cfg$figures$width,
                     height = cfg$figures$height,
                     dpi    = cfg$figures$dpi,
                     pdf    = isTRUE(cfg$figures$pdf)) {
  stem     <- tools::file_path_sans_ext(filename)
  png_file <- path_out_fig(paste0(stem, ".png"))
  ggplot2::ggsave(png_file, plot, device = ragg::agg_png,
                  width = width, height = height, units = "in", dpi = dpi)
  out <- png_file
  if (isTRUE(pdf)) {
    pdf_file <- path_out_fig(paste0(stem, ".pdf"))
    ggplot2::ggsave(pdf_file, plot, device = grDevices::cairo_pdf,
                    width = width, height = height, units = "in")
    out <- c(out, pdf_file)
  }
  message("Wrote: ", paste(out, collapse = ", "))
  invisible(out)
}

## Include a pipeline figure in an .Rmd chunk.
## Passes an absolute path so knitr writes a manuscript-relative path
## (../output/figures/...) into the .tex: no spaces from the Windows project
## path, and LaTeX finds the file from the build directory.
## error = FALSE skips knitr's pre-flight check (it runs from root.dir, not from
## the manuscript folder); existence is checked here instead.
fig_include <- function(filename) {
  p <- abs_path(path_out_fig(filename))
  if (!file.exists(p)) stop("Missing figure: ", p, " (run R/00_run_all.R)", call. = FALSE)
  knitr::include_graphics(p, error = FALSE)
}
