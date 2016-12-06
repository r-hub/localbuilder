
run_check <- function(path, image_id, user = "docker") {

  pkg_vol <- sprintf("%s:/%s", normalizePath(path), basename(path))

  new_id <- random_id()
  on.exit(try(docker_rm(new_id), silent = TRUE), add = TRUE)

  docker_run(
    image_id,
    name = new_id,
    user = user,
    workdir = paste0("/home/", user),
    volumes = pkg_vol,
    command = c("bash", "-l", "-c",
      sprintf("$RBINARY CMD check -l ~/R /%s", basename(path)))
  )

  new_image_id <- random_id()

  docker_commit(new_id)$stdout
}
