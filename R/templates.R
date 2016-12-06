
#' @importFrom tools file_ext

do_template <- function(template, data) {

  tfile <- system.file(package = .packageName, "templates", template)
  ext <- file_ext(tfile)
  outfile <- tempfile(fileext = paste0(".", ext))
  cat(
    whisker.render(paste(readLines(tfile), collapse = "\n"), data = data),
    "\n",
    file = outfile
  )
  normalizePath(outfile)
}
