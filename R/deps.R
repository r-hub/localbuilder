
#' Install dependencies, create a new Docker image
#'
#' We share the tarball, and use the new remotes::install_deps()
#' function.
#'
#' @param path Path to a tarball.
#' @param image_id Docker image id.
#'
#' @keywords internal

install_deps <- function(path, image_id, user, dependencies) {

  ## Create R script to run
  rfile <- tempfile(fileext = ".R")
  on.exit(unlink(rfile), add = TRUE)
  cat(
    sep = "\n", file = rfile,
    'source("https://install-github.me/r-pkgs/remotes")',
    sprintf('remotes::install_deps("/%s", dependencies = %s)',
            basename(path), as.character(dependencies))
  )
  rfile <- normalizePath(rfile)

  ## We need these files in the container
  pkg_vol <- sprintf("%s:/%s", normalizePath(path), basename(path))
  rfile_vol <- sprintf("%s:/%s", rfile, basename(rfile))

  new_id <- random_id()
  on.exit(try(docker_rm(new_id), silent = TRUE), add = TRUE)
  docker_run(
    image_id,
    name = new_id,
    user = user,
    volumes = c(pkg_vol, rfile_vol),
    command = c("bash", "-l", "-c",
      sprintf("$RBINARY -f /%s", basename(rfile)))
  )

  new_image_id <- random_id()

  docker_commit(new_id)$stdout
}
