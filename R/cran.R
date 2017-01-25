
#' @export
#' @importFrom cranlike update_PACKAGES package_versions
#' @importFrom crandeps cran_topo_sort
#' @importFrom jsonlite fromJSON

rebuild_cran <- function(
  image = "rhub/ubuntu-gcc-release",
  docker_user = "docker",
  repo = ".",
  packages = NULL,
  compiled_only = TRUE,
  cleanup = TRUE) {

  ensure_repo_directory(repo)

  if (is.null(packages)) {
    packages <- outdated_packages(repo, compiled_only)
  }

  repos <- getOption("repos")
  if (! "CRAN" %in% names(repos) || repos["CRAN"] == "@CRAN@") {
     options(repos = c(CRAN = "https://cran.r-hub.io"))
  }

  do_rebuild_cran(image, docker_user, repo, packages, compiled_only, cleanup)
}

do_rebuild_cran <- function(image, docker_user, repo, packages,
                            compiled_only, cleanup) {

  cleanme <- character()
  if (cleanup) {
    on.exit(
      try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
      add = TRUE
    )
  }

  ## Make sure that the image is available
  message("* Getting docker image ............... ", appendLF = FALSE)
  image_id <- docker_ensure_image(image)
  message(substring(image_id, 1, 40))

  ## Create a container to do all builds, we set up R, and install some packages
  message("* Setting up R environment ........... ", appendLF = FALSE)
  setup_image_id <- setup_for_r(image_id, user = docker_user, repo = repo,
                                sysreqs = TRUE, remotes = TRUE)
  cleanme <- c(cleanme, setup_image_id)
  message(substring(setup_image_id, 1, 40))

  ## System information
  message("* Querying system information ........ ", appendLF = FALSE)
  system_information(package, setup_image_id, repo = repo)
  message("DONE")

  message("* Need to build ", length(packages), " packages")

  for (i in seq_along(packages)) {
    pkg <- packages[i]
    version <- recent[pkg]
    message(" ** Building package [", i, "/", length(pacakges), "]: ", pkg)
    tryCatch({
        build_cran_package(pkg, version, image = setup_image_id,
          docker_user = docker_user, repo = repo)
        message("DONE")
      },
      error = function(e) message("FAILED: ", e$message)
    )
  }

  message("* DONE")
}

build_cran_package <- function(package, version, image, docker_user, repo) {

  cleanme <- character()
  on.exit(
    try(docker_rmi(setdiff(unique(cleanme), image)), silent = TRUE),
    add = TRUE
  )

  message(" ** Downloading package .............. ", appendLF = FALSE)
  package <- download_cran_package(package, version)
  if (is.null(package)) {
    message("FAILED")
    stop("Download ", package, " failed")
  }
  message("DONE")

  message(" ** Querying platform ................ ", appendLF = FALSE)
  platform <- get_platform(image)
  message(platform)

  message(" ** Querying system requirements ..... ", appendLF = FALSE)
  sysreqs <- get_system_requirements(package, platform)
  message("DONE")

  ## Install system requirements, create new image
  message(" ** Installing system requirements ... ", appendLF = FALSE)
  prov_image_id <- install_system_requirements(image, sysreqs)
  cleanme <- c(cleanme, prov_image_id)
  message(substring(prov_image_id, 1, 40))

  ## Install dependent R packages, create new image
  message(" ** Installing dependencies .......... ", appendLF = FALSE)
  dep_image_id <- install_deps(package, prov_image_id, user = docker_user,
                               dependencies = NA, repo = repo)
  cleanme <- c(cleanme, dep_image_id)
  message(substring(dep_image_id, 1, 40))

  ## Run the build
  message(" ** Running install & build .......... ", appendLF = FALSE)
  finished_image_id <- run_install(package, dep_image_id, user = docker_user,
                                   args = "--build", repo = repo)
  cleanme <- c(cleanme, finished_image_id)
  message(substring(finished_image_id, 1, 40))

  ## Save artifacts
  message(" ** Saving artifacts ................. ", appendLF = FALSE)
  repo_file_dir <- file.path(repo, "src", "contrib")
  dir.create(repo_file_dir, recursive = TRUE, showWarnings = FALSE)
  files <- save_artifacts(
    finished_image_id,
    repo_file_dir,
    user = docker_user
  )
  add_PACKAGES(files, repo_file_dir)
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

outdated_packages <- function(repo, compiled_only) {

  ## Calculating topological package order
  message("* Calculating package order .......... ", appendLF = FALSE)
  order <- cran_topo_sort()
  message("DONE")

  ## Querying packages with compiled code
  if (compiled_only) {
    message("* Querying packages with compiled code ", appendLF = FALSE)
    compiled <- fromJSON("https://crandb.r-pkg.org/-/needscompilation")
    message("DONE")
  }

  message("* Querying current package versions .. ", appendLF = FALSE)
  recent <- fromJSON("https://crandb.r-pkg.org/-/desc")
  recent <- vapply(recent, "[[", "", "version")
  if (compiled_only) recent <- recent[compiled]
  message("DONE")

  message("* Querying repo package versions ..... ", appendLF = FALSE)
  local <- package_versions(repo_file_dir)
  message("DONE")

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
  message("* Updating repo directory ........... ", appendLF = FALSE)
  repo_file_dir <- file.path(repo, "src", "contrib")
  dir.create(repo_file_dir, recursive = TRUE, showWarnings = FALSE)
  update_PACKAGES(repo_file_dir)
  message("DONE")
}
