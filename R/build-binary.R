
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
    try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
    add = TRUE
  )

  ## Make sure that the image is available
  message("* Getting docker image ............. ", appendLF = FALSE)
  image_id <- docker_ensure_image(image)
  message(substring(image_id, 1, 7))

  ## Get the R-hub platform id from the image, we need this to query the
  ## system reqirements for the platform
  message("* Querying platform ................ ", appendLF = FALSE)
  platform <- platform %||% get_platform(image_id)
  message(platform)

  ## Query system requirements
  message("* Querying system requirements ..... ", appendLF = FALSE)
  sysreqs <- get_system_requirements(path, platform)
  message("DONE")

  ## Install system requirements, create new image
  message("* Installing system requirements ... ", , appendLF = FALSE)
  prov_image_id <- install_system_requirements(image_id, sysreqs)
  cleanme <- c(cleanme, prov_image_id)
  message(substring(prov_image_id, 1, 7))

  ## Setup R, create package library directory, profile, etc.
  message("* Setting up R environment ......... ", appendLF = FALSE)
  setup_image_id <- setup_for_r(prov_image_id, user = docker_user)
  cleanme <- c(cleanme, setup_image_id)
  message(substring(setup_image_id, 1, 7))

  ## Install dependent R packages, create new image
  message("* Installing dependencies .......... ", appendLF = FALSE)
  dep_image_id <- install_deps(path, setup_image_id, user = docker_user,
                               dependencies = TRUE)
  cleanme <- c(cleanme, dep_image_id)
  message(substring(dep_image_id, 1, 7))

  ## System information
  message("* Querying system information ...... ", appendLF = FALSE)
  system_information(path, dep_image_id)
  message("DONE")

  ## Run the check
  message("* Running check .................... ", appendLF = FALSE)
  finished_image_id <- run_check(path, dep_image_id, user = docker_user,
                                 args = "--build")
  cleanme <- c(cleanme, finished_image_id)
  message(substring(finished_image_id, 1, 7))

  ## Save the built binary to a repository, optionally
  message("* Saving binary .................... ", appendLF = FALSE)
  save_binary_to_repo(path, finished_image_id, user = docker_user)
  message("DONE")
}

get_platform <- function(image_id) {
  docker_run(
    image_id,
    rm = TRUE,
    command = c("bash", "-c" , "echo $RHUB_PLATFORM")
  )$stdout
}
