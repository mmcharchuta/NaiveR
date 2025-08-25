#' Generate FASTA format output from sequence data frame
#'
#' Transforms structured sequence data into standard FASTA format, either as a string
#' or written directly to file. Headers combine identifier and metadata with tab separation,
#' omitting tabs when metadata is absent. Sequences appear as single lines.
#'
#' @param df_sequences
#'   Data frame containing sequence information with id, sequence, and optional comment columns
#' @param output_file
#'   Target file path for writing FASTA content, or NULL to return formatted string
#'
#' @return
#'   FASTA-formatted character string when output_file is NULL, otherwise writes to specified file
#'
#' @examples
#' sequence_data <- data.frame(
#'   id = c("seq1", "seq2"),
#'   sequence = c("ATGC", "TACG"),
#'   comment = c("description1", "description2")
#' )
#' write_fasta(sequence_data)
#' @export
write_fasta <- function(df_sequences, output_file = NULL) {
  fasta_lines <- paste0(">", df_sequences$id, "\t", df_sequences$comment, "\n", df_sequences$sequence, collapse = "\n")
  fasta_lines <- gsub(pattern = "\t\n", replacement = "\n", fasta_lines)
  if (!is.null(output_file)) {
    writeLines(fasta_lines, output_file)
  } else {
    fasta_lines
  }
}
