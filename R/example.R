#' Access example files for NaiveR
#'
#' Returns the path to example files bundled with NaiveR, or lists available files if no path is given.
#'
#' @param file_name Name of the example file, or NULL to list all.
#' @return Path to the file, or vector of file names if NULL.
#' @export
naiver_example <- function(file_name = NULL) {
  if (is.null(file_name)) {
    dir(system.file("extdata", package = "NaiveR"))
  } else {
    system.file("extdata", file_name, package = "NaiveR", mustWork = TRUE)
  }
}
