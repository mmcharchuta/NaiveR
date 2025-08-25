#' Retrieve paths to bundled example files
#'
#' Provides access to demonstration files included with the NaiveR package installation,
#' either returning specific file paths or listing all available example files.
#'
#' @param file_name Character string specifying target example file, or NULL to enumerate all files
#' @return File system path to requested file, or character vector listing all available examples
#' @export
naiver_example <- function(file_name = NULL) {
  if (is.null(file_name)) {
    dir(system.file("extdata", package = "NaiveR"))
  } else {
    system.file("extdata", file_name, package = "NaiveR", mustWork = TRUE)
  }
}
