
save_binary_to_repo <- function(path, image_id, user) {

  ## List files in the container, and the copy out what we need
  new_id <- random_id()
  files <- docker_run(
    image_id,
    name = new_id,
    user = user,
    workdir = paste0("/home/", user),
    command = c("bash", "-l", "-c", "ls")
  )$stdout

  files
}
