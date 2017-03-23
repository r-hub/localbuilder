
`%||%` <- function(l, r) if (is.null(l)) r else l

`%&&%` <- function(l, r) if (is.null(l)) NULL else r

#' @importFrom utils untar

description_from_tarball <- function(path) {
  files <- untar(path, list = TRUE, tar = "internal")
  desc <- grep("^[^/]+/DESCRIPTION$", files, value = TRUE)
  if (length(desc) < 1)
    stop("No 'DESCRIPTION' file in package")
  tmp <- tempfile()
  untar(path, desc, exdir = tmp, tar = "internal")
  file.path(tmp, desc)
}

random_id <- function(length = 16) {
  paste(
    sample(c(0:9, 'a', 'b', 'c', 'd', 'e', 'f'), length, replace = TRUE),
    collapse = ""
  )
}

cat0 <- function(..., sep = "") {
  cat(..., sep = sep)
}

format_iso_8601 <- function (date) {
  format(as.POSIXlt(date, tz = "UTC"), "%Y-%m-%dT%H:%M:%S+00:00")
}

random_string <- function(length = 6) {
  paste(sample(c(letters, 0:9), length, replace = TRUE), collapse = "")
}

valid_package_archive_name <- paste0(
  "^(?<package>[[:alpha:]][[:alnum:].]*[[:alnum:]])",
  "_",
  "(?<version>[0-9]+[-\\.][0-9]+)",
  "(?<arch>[-\\.][0-9]+)*(.*)?",
  "(?<extension>\\.tar\\.gz|\\.tgz|\\.zip)",
  "$"
)

is_valid_package_archive_name <- function(x) {
  grepl(valid_package_archive_name, x, perl = TRUE)
}

try_silently <- function(expr) {
  try(expr, silent = TRUE)
}
