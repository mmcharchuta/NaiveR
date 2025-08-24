#' Export a data frame to FASTA format
#'
#' Converts a data frame with columns for id, sequence, and comment into a string or file in FASTA format.
#' The header will use a tab to separate id and comment, but omits the tab if comment is empty. Sequences are single-line.
#'
#' @param df_sequences
#'   Data frame with columns: id, sequence, and (optionally) comment.
#' @param output_file
#'   File path or connection to write the FASTA output, or NULL to return as string.
#'
#' @return
#'   FASTA-formatted string (if output_file is NULL) or writes to file.
#'
#' @examples
#' example_df <- data.frame(
#'   id = c("seq1", "seq2"),
#'   sequence = c("ATGC", "TACG"),
#'   comment = c("foo", "bar")
#' )
#' write_fasta(example_df)
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
