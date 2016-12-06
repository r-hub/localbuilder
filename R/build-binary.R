
#' Build a binary from a local package tree
#'
#' @export

build_linux_binary <- function(
  path = ".",
  image = "rhub/ubuntu-gcc-release",
  platform = NULL,
  docker_user = "docker") {

  cleanme <- character()
  on.exit(
    try(docker_rmi(setdiff(unique(cleanme), image))),
    add = TRUE
  )

  ## Make sure that the image is available
  image_id <- docker_ensure_image(image)

  ## Get the R-hub platform id from the image, we need this to query the
  ## system reqirements for the platform
  platform <- platform %||% get_platform(image_id)

  ## Query system requirements
  sysreqs <- get_system_requirements(path, platform)

  ## Install system requirements, create new image
  prov_image_id <- install_system_requirements(image_id, sysreqs)
  cleanme <- c(cleanme, prov_image_id)

  ## Setup R, create package library directory, profile, etc.
  setup_image_id <- setup_for_r(prov_image_id, user = docker_user)
  cleanme <- c(cleanme, setup_image_id)

  ## Install dependent R packages, create new image
  dep_image_id <- install_deps(path, setup_image_id, user = docker_user,
                               dependencies = TRUE)
  cleanme <- c(cleanme, dep_image_id)

  ## System information
  system_information(path, dep_image_id)

  ## Run the check
  finished_image_id <- run_check(path, dep_image_id, user = docker_user)
  cleanme <- c(cleanme, finished_image_id)

  ## Save the built binary to a repository, optionally
  save_binary_to_repo(path, finished_image_id)
}

get_platform <- function(image_id) {
  docker_run(
    image_id,
    rm = TRUE,
    command = c("bash", "-c" , "echo $RHUB_PLATFORM")
  )$stdout
}
