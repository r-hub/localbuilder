
is_debugged <- function() {
  Sys.getenv("DEBUG", "") == "yes"
}
