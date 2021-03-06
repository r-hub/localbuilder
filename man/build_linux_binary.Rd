% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build-binary.R
\name{build_linux_binary}
\alias{build_linux_binary}
\title{Build a binary from a source package}
\usage{
build_linux_binary(package, image = "rhub/ubuntu-gcc-release",
  docker_user = "docker", repo = ".", logfile = new_logfile(package),
  debug = Sys.getenv("DEBUG") == "yes")
}
\arguments{
\item{package}{Path to a package archive to build.}

\item{image}{Docker image to use.}

\item{docker_user}{Username to use within the Docker container.}

\item{repo}{CRAN-like repository that has the binary packages.}

\item{logfile}{The log file of the build. The default will choose
a random name in the user's log directory.}

\item{debug}{Whether to show all build output. The log file always
contains the full output.}
}
\description{
Build a binary from a source package
}
