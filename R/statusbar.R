
#' @importFrom statusbar status_bar status_log
#' @importFrom crayon bold blue green red
#' @importFrom clisymbols symbol

with_status <- function(expr, msg, done = "DONE", width = 35) {  

  title <- blue $ bold
  current <- bold

  msg35 <- dotted_line(msg, width = 35)
  level <- if (is_debugged()) "DEBUG" else "LOGFILE"
  status_log(paste0("\n", title(symbol$pointer, msg35)),
             logfile = get_logfile(), level = level)
  status_bar(current(" ", msg35))

  success <- if (is_debugged()) green else paste

  on.exit({
    status_bar(NULL)
    status_log(paste(green(symbol$tick), success(msg35, done)))
  })
  expr
}

dotted_line <- function(msg, width) {
  paste(msg, strrep(".", max(0, width - nchar(msg))))
}

stdout_log_callback <- function(x, proc) {
  level <- if (is_debugged()) "DEBUG" else "LOGFILE"
  grey <- make_style("grey")
  status_log(grey(paste0("  - ", x)), logfile = get_logfile(),
             level = level)
}

stderr_log_callback <- function(x, proc) {
  level <- if (is_debugged()) "DEBUG" else "LOGFILE"
  status_log(paste0("  ", red(symbol$cross), " ", x),
             logfile = get_logfile(), level = level)
}

#' @importFrom crayon make_style

header_style <- function() {
  bold
}

status_header_line <- function() {
  status_header(strrep(symbol$line, 79))
}

status_header <- function(...) {
  header <- header_style()
  status_log(header(paste0(...)), logfile = get_logfile())
}
