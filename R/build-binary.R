
#' Build a binary from a local package tree
#'
#' @export

build_linux_binary <- function(
  path = ".",
  image = "rhub/ubuntu-gcc-release",
  platform = NULL,
  docker_user = "docker") {

  ## Make sure that the image is available
  image_id <- docker_ensure_image(image)

  ## Get the R-hub platform id from the image, we need this to query the
  ## system reqirements for the platform
  platform <- platform %||% get_platform(image_id)

  ## Query system requirements
  sysreqs <- get_system_requirements(path, platform)

  ## Install system requirements, create new image
  prov_image_id <- install_system_requirements(image_id, sysreqs)
  if (image_id != prov_image_id) {
    on.exit(docker_rmi(prov_image_id), add = TRUE)
  }

  ## Setup R, create package library directory, profile, etc.
  setup_image_id <- setup_for_r(prov_image_id)
  if (setup_image_id != prov_image_id) {
    on.exit(docker_rmi(setup_image_id), add = TRUE)
  }

  ## Install dependent R packages, create new image
  dep_image_id <- install_deps(path, setup_image_id)
  if (dep_image_id != setup_image_id) {
    on.exit(docker_rmi(dep_image_id), add = TRUE)
  }

  ## System information
  system_information(path, dep_image_id)

  ## Run the check
  finished_cont_id <- run_check(path, dep_image_id)

  ## Save the built binary to a repository, optionally
  save_binary_to_repo(path, finished_cont_id)
}

get_platform <- function(image_id) {
  docker_run(
    image_id,
    rm = TRUE,
    command = c("bash", "-c" , "echo $RHUB_PLATFORM")
  )$stdout
}
