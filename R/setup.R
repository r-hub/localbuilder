
#' @importFrom whisker whisker.render

setup_for_r <- function(image_id, user, repos = NULL) {

  if (is.null(repos)) repos <- Sys.getenv("RHUB_CRAN_REPO", NA_character_)
  if (is.na(repos)) repos <- "https://cran.r-hub.io"

  ## Create file to run
  template_data <- list(
    "cran-repo" = repos
  )
  shfile <- do_template("setup.sh", template_data)
  on.exit(unlink(shfile), add = TRUE)
  shfile_vol <- sprintf("%s:/%s", shfile, basename(shfile))

  new_id <- random_id()
  on.exit(try(docker_rm(new_id), silent = TRUE), add = TRUE)
  docker_run(
    image_id,
    name = new_id,
    user = user,
    volumes = shfile_vol,
    command = c("bash", sprintf("/%s", basename(shfile)))
  )

  new_image_id <- random_id()

  docker_commit(new_id)$stdout
}
