#' Load taxonomic classification data from external file
#'
#' Processes a tab-separated taxonomy file (following mothur format conventions) and 
#' converts it into a structured data frame with standardized taxonomy formatting.
#'
#' @param file_path File path or connection object pointing to taxonomy data file
#' @return Data frame with id and taxonomy columns (semicolon-delimited, trailing semicolons removed)
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
