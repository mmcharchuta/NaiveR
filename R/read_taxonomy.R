#' Import taxonomy data from file
#'
#' Reads a taxonomy file (mothur-style) into a data frame with id and taxonomy columns.
#'
#' @param file_path Path or connection to the taxonomy file.
#' @return Data frame with columns: id and taxonomy (semicolon-separated, no trailing semicolon).
#' @importFrom stringi stri_replace_last_regex stri_replace_all_regex
#' @importFrom readr read_tsv cols col_character
#' @export
read_taxonomy <- function(file_path) {
  tax_df <- readr::read_tsv(file_path,
    col_names = c("id", "taxonomy"),
    col_types = readr::cols(.default = readr::col_character())
  )
  tax_df$taxonomy <- stringi::stri_replace_last_regex(tax_df$taxonomy, ";$", "")
  tax_df$taxonomy <- stringi::stri_replace_all_regex(tax_df$taxonomy, "; ", ";")
  tax_df
}
