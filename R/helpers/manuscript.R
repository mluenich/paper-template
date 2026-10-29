## R/helpers/manuscript.R
## Word count of an .Rmd source (approximation of the rendered prose).
## Counted: running text and headings. Excluded: YAML header, code chunks,
## HTML comments, lines starting with a LaTeX command (\newpage, keywords
## line, ...), tables/figures (built in chunks), and everything from the
## "References" heading on. Inline R counts as one word, each citation key as
## one word, each \ref{} as one word. Abstract is reported separately.

word_count_rmd <- function(file) {
  x <- readLines(file, encoding = "UTF-8", warn = FALSE)

  ## YAML header
  if (length(x) > 0 && grepl("^---\\s*$", x[1])) {
    end <- which(grepl("^(---|\\.\\.\\.)\\s*$", x))[2]
    if (!is.na(end)) x <- x[-seq_len(end)]
  }

  ## code chunks (fence lines included)
  fence  <- grepl("^\\s*```", x)
  inside <- (cumsum(fence) %% 2 == 1) | fence
  x <- x[!inside]

  ## HTML comments, possibly multi-line
  x <- strsplit(gsub("(?s)<!--.*?-->", " ", paste(x, collapse = "\n"), perl = TRUE),
                "\n", fixed = TRUE)[[1]]

  ## section of each line = most recent level-1 heading
  h1      <- grepl("^#\\s", x)
  h1_name <- tolower(trimws(gsub("\\{.*\\}", "", sub("^#\\s+", "", x[h1]))))
  sec     <- c("preamble", h1_name)[cumsum(h1) + 1]

  stop_at <- which(h1 & sec %in% c("references", "literatur", "bibliography"))
  if (length(stop_at) > 0) {
    keep <- seq_len(stop_at[1] - 1)
    x <- x[keep]; sec <- sec[keep]; h1 <- h1[keep]
  }

  ## drop LaTeX-only lines; clean remaining markup
  x[grepl("^\\s*\\\\", x)] <- ""
  x <- gsub("`r [^`]*`", " X ", x)
  x <- gsub("\\\\ref\\{[^}]*\\}", " 1 ", x)
  x <- gsub("@[A-Za-z0-9_:.-]+", " Cite ", x)
  x <- gsub("\\{[-#.][^}]*\\}", " ", x)
  x <- gsub("\\\\[A-Za-z]+", " ", x)

  count <- function(s) {
    if (length(s) == 0) return(0L)
    m <- gregexpr("[\\p{L}\\p{N}]+(?:['\u2019.-][\\p{L}\\p{N}]+)*",
                  paste(s, collapse = " "), perl = TRUE)[[1]]
    if (m[1] == -1) 0L else length(m)
  }

  is_abs <- sec == "abstract"
  data.frame(
    file      = basename(file),
    abstract  = count(x[is_abs & !h1]),
    main_text = count(x[!is_abs & sec != "preamble"]),
    stringsAsFactors = FALSE
  )
}
