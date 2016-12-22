
`%||%` <- function(l, r) if (is.null(l)) r else l

`%&&%` <- function(l, r) if (is.null(l)) NULL else r

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
