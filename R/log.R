
#' @importFrom rappdirs user_log_dir

get_log_dir <- function() {
  user_log_dir(appname = "r-hub", version = "localbuilder")
}

#' @importFrom rematch2 re_match

new_logfile <- function(package) {
  log_dir <- get_log_dir()
  re <- re_match(basename(package), valid_package_archive_name)
  log_file <- paste0(
    re$package, "-",
    re$version, "-",
    random_string(length = 6)
  )

  file.path(log_dir, log_file)
}

new_cran_logfile <- function() {
  log_dir <- get_log_dir()
  log_file <- paste0("CRAN-", random_string(length = 6))
  file.path(log_dir, log_file)
}
