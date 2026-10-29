## R/99_export_osf.R
## Builds a reproduction package (zip) for OSF upload. Run manually after
## source("R/00_run_all.R"); not part of the pipeline.
##
## Whitelist approach (config/params.yml -> osf): only listed files/folders
## are packed. Never included: data/raw/, config/params.local.yml.
## Optional: data/derived/ (osf$include_derived), rendered output
## (osf$include_output). Requires package 'zip' (utils::zip needs Rtools on
## Windows).

source("R/00_setup.R")
load_pkgs("zip")

## ---- Collect files ----------------------------------------------------------
list_entry <- function(p) {
  if (dir.exists(p)) {
    list.files(p, recursive = TRUE, full.names = TRUE, all.files = FALSE)
  } else if (file.exists(p)) {
    p
  } else {
    message("Skipped (not found): ", p)
    character(0)
  }
}

files <- unlist(lapply(cfg$osf$include, list_entry))

if (isTRUE(cfg$osf$include_derived)) {
  files <- c(files, list_entry(paths$derived_data_dir))
}

if (isTRUE(cfg$osf$include_output)) {
  out_top <- list.files(paths$output_dir, full.names = TRUE,
                        pattern = "\\.(pdf|txt)$")
  files <- c(files, out_top,
             list_entry(paths$figures_dir),
             list_entry(paths$tables_dir))
}

## ---- Exclusions (always) ----------------------------------------------------
norm <- function(p) gsub("\\\\", "/", normalizePath(p, mustWork = FALSE))
files <- unique(files)
files <- files[!startsWith(norm(files), norm(paths$raw_data_dir))]
files <- files[!grepl("params\\.local\\.ya?ml$", files)]
files <- files[!grepl("(^|/)(\\.Rhistory|\\.RData|\\.Rproj\\.user)", files)]
files <- files[!grepl("_osf_package\\.zip$", files)]
files <- files[!grepl("^manuscript/.*\\.(log|aux|out|tex|knit\\.md|utf8\\.md)$", files)]

if (!file.exists(file.path(paths$output_dir, "session_info.txt"))) {
  warning("No session_info.txt found; run R/00_run_all.R first.", call. = FALSE)
}

## ---- Write zip --------------------------------------------------------------
zip_file <- file.path(paths$output_dir,
                      paste0(format(Sys.Date(), "%y%m%d_"), "osf_package.zip"))
if (file.exists(zip_file)) file.remove(zip_file)

zip::zip(zip_file, files = files, mode = "mirror")

message("Wrote: ", zip_file, " (", length(files), " files)")
message("Check contents before upload: zip::zip_list(\"", zip_file, "\")")
