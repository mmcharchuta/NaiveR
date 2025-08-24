#' Filter taxonomy by confidence threshold
#'
#' Removes taxonomic levels with confidence below a minimum threshold.
#'
#' @param consensus_tax List with 'taxonomy' and 'confidence' vectors.
#' @param min_conf Numeric, minimum confidence (default 80).
#' @return Filtered list with taxonomy and confidence above threshold.
#' @export
filter_taxonomy <- function(consensus_tax, min_conf = 80) {
  keep <- which(consensus_tax$confidence >= min_conf)
  list(
    taxonomy = consensus_tax$taxonomy[keep],
    confidence = consensus_tax$confidence[keep]
  )
}
