
#' Build binary packages for all or part of CRAN
#'
#' @param image The image to use.
#' @param docker_user The user to use in the Docker container.
#' @param repo The CRAN-like repository that contains the binary packages.
#' @param packages The CRAN packages to build. If it is `NULL`, then
#'   all out of date packages that require compilation, will be built.
#'   See also the `compiled_only` argument to force building packages that
#'   do not require compilation.
#' @param compiled_only Whether to build only CRAN packages that require
#'   compilation.
#' @param cleanup Whether to clean up the Docker containers and images
#'   after the builds.
#' @param logfile The log file of the build. The default will choose
#'   a random name in the user's log directory.
#'
#' @export
#' @importFrom cranlike update_PACKAGES package_versions
#' @importFrom crandeps cran_topo_sort
#' @importFrom jsonlite fromJSON
#' @importFrom statusbar set_logfile status_sub

rebuild_cran <- function(
  image = "rhub/ubuntu-gcc-release",
  docker_user = "docker",
  repo = ".",
  packages = NULL,
  compiled_only = TRUE,
  cleanup = TRUE,
  logfile = new_cran_logfile()) {

  start_time <- proc.time()

  set_logfile(logfile)

  status_header_line()
  status_header(symbol$pointer, " Building CRAN packages")
  status_header("  Log: ", sQuote(logfile))
  status_header_line()

  ensure_repo_directory(repo)

  recent <- with_status({
    x <- fromJSON("https://crandb.r-pkg.org/-/desc")
    vapply(x, "[[", "", "version")
  }, "Querying current package versions")

  if (is.null(packages)) {
    status_log(paste(symbol$info, "Work out packages and their order"))
    packages <- status_sub(
      outdated_packages(repo, compiled_only, recent)
    )
  }

  repos <- getOption("repos")
  if (! "CRAN" %in% names(repos) || repos["CRAN"] == "@CRAN@") {
     options(repos = c(CRAN = "https://cran.r-hub.io"))
  }

  do_rebuild_cran(image, docker_user, repo, packages, compiled_only,
                  cleanup, recent)

  end_time <- proc.time()
  secs <- as.difftime((end_time - start_time)[["elapsed"]], units = "secs")

  status_header_line()
  status_header("  Finished in ", pretty_dt(secs))
  status_header("  Log: ", sQuote(logfile))

  invisible()
}

do_rebuild_cran <- function(image, docker_user, repo, packages,
                            compiled_only, cleanup, recent) {

  cleanme <- character()
  if (cleanup) {
    on.exit(
      try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
      add = TRUE
    )
  }

  ## Make sure that the image is available
  image_id <- with_status(
    x <- docker_ensure_image(image),
    "Getting docker image",
    substring(x, 1, 40)
  )

  ## Create a container to do all builds, we set up R, and install some packages
  setup_image_id <- with_status(
    x <- setup_for_r(image_id, user = docker_user, repo = repo,
                     sysreqs = TRUE, remotes = TRUE),
    "Setting up R environment",
    substring(x, 1, 40)
  )
  cleanme <- c(cleanme, setup_image_id)

  ## System information
  with_status(
    system_information(packages, setup_image_id, repo = repo),
    "Querying system information"
  )

  status_log("")
  status_log(paste0(
    symbol$info, " Need to build ", length(packages), " packages"
  ))

  for (i in seq_along(packages)) {
    pkg <- packages[i]
    version <- recent[pkg]
    msg <- paste0(" Building package [", i, "/",
                  length(packages), "]: ", pkg)
    status_log("")
    status_log(paste(symbol$menu, msg))
    ok <- TRUE
    tryCatch({
      status_sub(
        build_cran_package(pkg, version, image = setup_image_id,
                           docker_user = docker_user, repo = repo)
      )
    }, error = function(e) ok <<- FALSE)
    status_log(paste(if (ok) symbol$tick else symbol$cross, msg, "DONE"))
  }
}

build_cran_package <- function(package, version, image, docker_user, repo) {

  start_time <- proc.time()

  cleanme <- character()
  on.exit(
    try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
    add = TRUE
  )

  package <- try_silently(with_status(
    download_cran_package(package, version) %||% stop("Download failed"),
    "Downloading package",
  ))

  platform <- with_status(get_platform(image), "Querying platform")

  sysreqs <- with_status(
    get_system_requirements(package, platform),
    "Querying system requirements"
  )

  prov_image_id <- with_status(
    x <- install_system_requirements(image, sysreqs),
    "Installing system requirements",
    done = substring(x, 1, 40)
  )
  cleanme <- c(cleanme, prov_image_id)

  ## Install dependent R packages, create new image
  dep_image_id <- with_status(
    x <- install_deps(package, prov_image_id, user = docker_user,
                      dependencies = NA, repo = repo),
    "Installing dependencies",
    done = substring(x, 1, 40)
  )
  cleanme <- c(cleanme, dep_image_id)

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
    done = basename(files)
  )

  end_time <- proc.time()
  secs <- as.difftime((end_time - start_time)[["elapsed"]], units = "secs")
  status_header("  Package finished in ", pretty_dt(secs))

  invisible()
}

#' @importFrom curl curl_download

download_cran_package <- function(package, version) {
  filename <- paste0(package, "_", version, ".tar.gz")
  destfile <- file.path(tempdir(), filename)
  cran <- getOption("repos")["CRAN"]
  url <- paste0(cran, "/src/contrib/", filename)
  url2 <- paste0(cran, "/src/contrib/Archive/", package, "/", filename)

  path <- tryCatch(
    curl_download(url, destfile = destfile),
    error = function(e) NULL
  )

  if (is.null(path)) {
    path <- tryCatch(
      curl_download(url2, destfile = destfile),
      error = function(e) NULL
    )
  }

  path
}

outdated_packages <- function(repo, compiled_only, recent) {

  ## Calculating topological package order
  order <- with_status(
    cran_topo_sort(),
    "Calculating package order"
  )

  ## Querying packages with compiled code
  if (compiled_only) {
    recent <- with_status(
      recent[fromJSON("https://crandb.r-pkg.org/-/needscompilation")],
      "Querying packages with compiled code"
    )
  }

  with_status({
    repo_file_dir <- file.path(repo, "src", "contrib")
    local <- package_versions(repo_file_dir)
  }, "Querying repo package versions")

  toinstall <- setdiff(names(recent), local$Package)
  common <- intersect(names(recent), local$Package)
  outofdate <- common[package_version(local$Version[match(common, local$Package)]) <
                      package_version(recent[common])]
  toinstall <- c(toinstall, outofdate)

  ## Need them in the right order. We also make sure that we build the ones
  ## that are were added since we calculated the order
  toinstall2 <- order[order %in% toinstall]
  toinstall2 <- c(toinstall2, setdiff(toinstall, toinstall2))

  toinstall2
}

ensure_repo_directory <- function(repo) {
  ## Make sure repo is up to date
  with_status({
    repo_file_dir <- file.path(repo, "src", "contrib")
    dir.create(repo_file_dir, recursive = TRUE, showWarnings = FALSE)
    update_PACKAGES(repo_file_dir)
  }, "Updating repo directory")
}
