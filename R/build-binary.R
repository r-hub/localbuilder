	
#' Build a binary from a source package
#'
#' @export
#' @importFrom cranlike add_PACKAGES

build_linux_binary <- function(
  package,
  image = "rhub/ubuntu-gcc-release",
  docker_user = "docker",
  repo = ".") {

  cleanme <- character()
  on.exit(
    try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
    add = TRUE
  )

  ## Make sure that the image is available
  message("* Getting docker image ............. ", appendLF = FALSE)
  image_id <- docker_ensure_image(image)
  message(substring(image_id, 1, 40))

  ## Get the R-hub platform id from the image, we need this to query the
  ## system reqirements for the platform
  message("* Querying platform ................ ", appendLF = FALSE)
  platform <- get_platform(image_id)
  message(platform)

  ## Query system requirements
  message("* Querying system requirements ..... ", appendLF = FALSE)
  sysreqs <- get_system_requirements(package, platform)
  message("DONE")

  ## Install system requirements, create new image
  message("* Installing system requirements ... ", appendLF = FALSE)
  prov_image_id <- install_system_requirements(image_id, sysreqs)
  cleanme <- c(cleanme, prov_image_id)
  message(substring(prov_image_id, 1, 40))

  ## Setup R, create package library directory, profile, etc.
  message("* Setting up R environment ......... ", appendLF = FALSE)
  setup_image_id <- setup_for_r(prov_image_id, user = docker_user)
  cleanme <- c(cleanme, setup_image_id)
  message(substring(setup_image_id, 1, 40))

  ## Install dependent R packages, create new image
  message("* Installing dependencies .......... ", appendLF = FALSE)
  dep_image_id <- install_deps(package, setup_image_id, user = docker_user,
                               dependencies = NA, repo = repo)
  cleanme <- c(cleanme, dep_image_id)
  message(substring(dep_image_id, 1, 40))

  ## System information
  message("* Querying system information ...... ", appendLF = FALSE)
  system_information(package, dep_image_id, repo = repo)
  message("DONE")

  ## Run the build
  message("* Running install & build .......... ", appendLF = FALSE)
  finished_image_id <- run_install(package, dep_image_id, user = docker_user,
                                   args = "--build", repo = repo)
  cleanme <- c(cleanme, finished_image_id)
  message(substring(finished_image_id, 1, 40))

  ## Save artifacts
  message("* Saving artifacts ................. ", appendLF = FALSE)
  repo_file_dir <- file.path(repo, "src", "contrib")
  dir.create(repo_file_dir, recursive = TRUE, showWarnings = FALSE)
  files <- save_artifacts(
    finished_image_id,
    repo_file_dir,
    user = docker_user
  )
  add_PACKAGES(files, repo_file_dir)
  message("DONE")
}

get_platform <- function(image_id) {
  docker_run(
    image_id,
    rm = TRUE,
    command = c("bash", "-c" , "echo $RHUB_PLATFORM")
  )$stdout
}
