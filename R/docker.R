
#' @importFrom processx run

docker <- function(...) {
  run("docker", unlist(list(...)), echo = TRUE, spinner = TRUE)
}

docker_image_available <- function(image) {
  length(docker("images", "-q", image)$stdout) > 0
}

docker_ensure_image <- function(image) {
  if (! docker_image_available(image)) {
    docker("pull", image)
  }
}

docker_run <- function(image, command, options = NULL, rm = FALSE,
                       user = NULL, name = NULL, volumes = character(),
                       workdir = NULL) {
  docker(
    "run",
    c(if (length(options)) options,
      if (rm) "--rm",
      user %&&% c("--user", user),
      name %&&% c("--name", name),
      workdir %&&% c("-w", workdir),
      if (length(volumes)) rbind("-v", volumes),
      image,
      command)
  )
}

docker_commit <- function(container) {
  docker("commit", container)
}

docker_rm <- function(containers) {
  docker("rm", containers)
}

docker_rmi <- function(images) {
  docker("rmi", images)
}
