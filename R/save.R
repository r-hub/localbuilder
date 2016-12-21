
save_artifacts <- function(image_id, path, user) {

  ## List files in the container, and the copy out what we need
  new_id <- random_id()
  files <- docker_run(
    image_id,
    name = new_id,
    user = user,
    workdir = paste0("/home/", user),
    command = c("bash", "-l", "-c", "ls")
  )$stdout

  pkgs <- grep("\\.tar\\.gz$", files)

  for (pkg in pkgs) {
    docker_cp(
      paste0(new_id, ":", "/home/", user, "/", pkg),
      path
    )
  }
  pkgs
}
