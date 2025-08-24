#' Display taxonomy with confidence values
#'
#' Prints consensus taxonomy for a sequence, appending confidence for each level.
#'
#' @param consensus_tax List with 'taxonomy' and 'confidence' vectors.
#' @param total_levels Integer, number of taxonomic levels to display (default 6).
#' @return Character string of taxonomy with confidence values.
#' @export
print_taxonomy <- function(consensus_tax, total_levels = 6) {
  orig_levels <- length(consensus_tax$taxonomy)
  current_levels <- orig_levels
  while (current_levels < total_levels) {
    consensus_tax$taxonomy[current_levels + 1] <-
      paste(consensus_tax$taxonomy[orig_levels], "unclassified", sep = "_")
    consensus_tax$confidence[current_levels + 1] <-
      consensus_tax$confidence[orig_levels]
    current_levels <- current_levels + 1
  }
  conf_str <- paste0("(", consensus_tax$confidence, ")")
  paste(consensus_tax$taxonomy, conf_str, sep = "", collapse = ";")
}
