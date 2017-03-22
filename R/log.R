
get_logfile <- function() {
  mydata$logfile
}

set_logfile <- function(path) {
  mydata$logfile <- path
}

#' @importFrom rappdirs user_log_dir
#' @importFrom rematch2 re_match

new_logfile <- function(package) {
  log_dir <- user_log_dir(appname = "r-hub", version = "localbuilder")
  re <- re_match(basename(package), valid_package_archive_name)
  log_file <- paste0(
    re$package, "-",
    re$version, "-",
    random_string(length = 6)
  )

  file.path(log_dir, log_file)
}
