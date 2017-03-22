
#' Build a binary from a source package
#'
#' @export
#' @importFrom cranlike add_PACKAGES
#' @importFrom statusbar status_log
#' @importFrom prettyunits pretty_dt

build_linux_binary <- function(
  package,
  image = "rhub/ubuntu-gcc-release",
  docker_user = "docker",
  repo = ".",
  logfile = new_logfile(package),
  debug = Sys.getenv("DEBUG") == "yes") {

  start_time <- proc.time()

  if (!is_valid_package_archive_name(basename(package))) {
    warning(sQuote(basename(package)),
            "is not a valid package archive name")
  }

  mydata$debug <- debug

  set_logfile(logfile)

  status_header_line()
  status_header(symbol$pointer, " Building ", sQuote(blue(basename(package))))
  status_header("  Log: ", sQuote(logfile))
  status_header_line()

  cleanme <- character()
  on.exit(
    try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
    add = TRUE
  )


  ## Make sure that the image is available
  image_id <- with_status(
    x <- docker_ensure_image(image),
    "Getting docker image",
    done = substring(x, 1, 40)
  )

  ## Get the R-hub platform id from the image, we need this to query the
  ##
  platform <- with_status(
    x <- get_platform(image_id),
    "Querying platform",
    done = x
  )

  ## Query system requirements
  sysreqs <- with_status(
    x <- get_system_requirements(package, platform),
    "Querying system requirements",
    substring(x, 1, 40)
  )

  ## Install system requirements, create new image
  prov_image_id <- with_status(
    x <- install_system_requirements(image_id, sysreqs),
    "Installing system requirements",
    done = substring(x, 1, 40)
  )
  cleanme <- c(cleanme, prov_image_id)

  ## Setup R, create package library directory, profile, etc.
  setup_image_id <- with_status(
    x <- setup_for_r(prov_image_id, user = docker_user, repo = repo),
    "Setting up R environment",
    done = substring(x, 1, 40)
  )
  cleanme <- c(cleanme, setup_image_id)

  ## Install dependent R packages, create new image
  dep_image_id <- with_status(
    x <- install_deps(package, setup_image_id, user = docker_user,
                      dependencies = NA, repo = repo),
    "Installing dependencies",
    substring(x, 1, 40)
  )
  cleanme <- c(cleanme, dep_image_id)

  ## System information
  with_status(
    system_information(package, dep_image_id, repo = repo),
    "Querying system information"
  )

  ## Run the build
  finished_image_id <- with_status(
    x <- run_install(package, dep_image_id, user = docker_user,
                     args = "--build", repo = repo),
    "Running install & build",
    done = substring(x, 1, 40)
  )
  cleanme <- c(cleanme, finished_image_id)

  ## Save artifacts
  with_status(
    {
      repo_file_dir <- file.path(repo, "src", "contrib")
      dir.create(repo_file_dir, recursive = TRUE, showWarnings = FALSE)
      files <- save_artifacts(
        finished_image_id,
        repo_file_dir,
        user = docker_user
      )
      add_PACKAGES(files, repo_file_dir)
    },
    "Saving artifacts",
    substring(basename(files), 1, 40)
  )

  ## Otherwise it comes after the final messages
  on.exit()
  try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE)

  end_time <- proc.time()
  secs <- as.difftime((end_time - start_time)[["elapsed"]], units = "secs")

  status_header_line()
  status_header("  Finished in ", pretty_dt(secs))
  status_header("  Log: ", sQuote(logfile))

  invisible()
}

get_platform <- function(image_id) {
  docker_run(
    image_id,
    rm = TRUE,
    command = c("bash", "-c" , "echo $RHUB_PLATFORM")
  )$stdout
}
