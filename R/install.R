
run_install <- function(path, image_id, user, args, repo) {

  args <- paste(args, collapse = " ")

  pkg_vol <- sprintf("%s:/%s", normalizePath(path), basename(path))
  repo_vol <- sprintf("%s:/%s", normalizePath(repo), "local")

  new_id <- random_id()
  on.exit(try(docker_rm(new_id), silent = TRUE), add = TRUE)

  docker_run(
    image_id,
    name = new_id,
    user = user,
    workdir = paste0("/home/", user),
    volumes = c(pkg_vol, repo_vol),
    command = c("bash", "-l", "-c",
      sprintf("$RBINARY CMD INSTALL -l ~/R %s /%s", args, basename(path)))
  )

  new_image_id <- random_id()

  docker_commit(new_id)$stdout
}
