#' Apply confidence-based filtering to taxonomic assignments
#'
#' Eliminates taxonomic classifications that fall below a specified confidence threshold,
#' retaining only high-confidence assignments for downstream analysis.
#'
#' @param consensus_tax Named list containing 'taxonomy' and 'confidence' vectors from classification
#' @param min_conf Numeric threshold value for minimum acceptable confidence (default: 80)
#' @return Filtered list structure containing only taxonomy and confidence values above threshold
#' @export
filter_taxonomy <- function(consensus_tax, min_conf = 80) {
  keep <- which(consensus_tax$confidence >= min_conf)
  list(
    taxonomy = consensus_tax$taxonomy[keep],
    confidence = consensus_tax$confidence[keep]
  )
}
