
#' @importFrom sysreqs sysreq_commands

get_system_requirements <- function(path, platform) {
  desc <- description_from_tarball(path)
  sysreq_commands(desc, platform, soft = FALSE)
}

#' Create another image, with sysreqs installed
#'
#' @return Id of the new image, or the old image if no sysreqs
#'   are needed.
#'
#' @keywords internal

install_system_requirements <- function(image_id, sysreqs) {

  ## No sysreqs == nothing to do
  if (length(sysreqs) == 0) return(image_id)

  new_id <- random_id()

  cat(sysreqs, "\n", file = tmp <- tempfile(fileext = ".sh"))

  tmp <- normalizePath(tmp)

  on.exit(try(docker_rm(new_id), silent = TRUE), add = TRUE)
  docker_run(
    image_id,
    user = "root",
    name = new_id,
    volumes = sprintf("%s:/root/%s", tmp, basename(tmp)),
    command = c("bash", sprintf("/root/%s", basename(tmp)))
  )

  new_image_id <- random_id()

  docker_commit(new_id)$stdout
}
