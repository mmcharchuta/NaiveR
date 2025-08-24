#' Read a FASTA file into a data frame
#'
#' Reads a standard FASTA file and returns a data frame with id, sequence, and comment columns.
#'
#' @param fasta_file Path or connection to the FASTA file.
#' @param remove_gaps Logical, default TRUE. If TRUE, removes gap characters ('.' or '-') from sequences.
#' @return Data frame with columns: id, sequence, comment.
#' @importFrom readr read_lines
#' @importFrom stringi stri_startswith_fixed stri_replace_first_regex stri_c stri_replace_all_regex
#' @export
read_fasta <- function(fasta_file, remove_gaps = TRUE) {
  lines <- readr::read_lines(fasta_file)
  header_idx <- stringi::stri_startswith_fixed(lines, ">")
  ids <- stringi::stri_replace_first_regex(lines[header_idx], ">\\s*", "")
  comments <- ifelse(grepl("\\s", ids), sub("^([^\\s]+)\\s+", "", ids), "")
  ids <- ifelse(grepl("\\s", ids), sub("\\s.*$", "", ids), ids)
  seqs <- rep(NA, sum(header_idx))
  seq_idx <- which(header_idx)
  for (i in seq_along(seq_idx)) {
    start <- seq_idx[i] + 1
    end <- if (i < length(seq_idx)) seq_idx[i+1] - 1 else length(lines)
    seqs[i] <- paste0(lines[start:end][!header_idx[start:end]], collapse = "")
  }
  if (remove_gaps) seqs <- gsub("[.-]", "", seqs)
  data.frame(id = ids, sequence = seqs, comment = comments, stringsAsFactors = FALSE)
}
