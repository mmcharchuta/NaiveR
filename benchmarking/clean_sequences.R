# Fix RNA sequences in FASTA file for QIIME2 compatibility
# Convert U (Uracil) to T (Thymine) and filter for valid DNA sequences

#' Clean FASTA sequences for QIIME2 compatibility
#' 
#' @param input_fasta Path to input FASTA file
#' @param output_fasta Path to output cleaned FASTA file
#' @param max_sequences Maximum number of sequences to keep (optional)
clean_fasta_for_qiime2 <- function(input_fasta, output_fasta, max_sequences = NULL) {
  
  # Load NaiveR if not already loaded
  if (!"package:NaiveR" %in% search()) {
    devtools::load_all("..")
  }
  
  cat("Reading FASTA file...\n")
  sequences <- NaiveR::read_fasta(input_fasta)
  
  cat(sprintf("Original sequences: %d\n", nrow(sequences)))
  
  # Convert RNA to DNA (U -> T)
  cat("Converting RNA to DNA (U -> T)...\n")
  sequences$sequence <- gsub("U", "T", sequences$sequence, ignore.case = TRUE)
  
  # Filter for valid DNA sequences (only IUPAC DNA characters)
  cat("Filtering for valid DNA sequences...\n")
  valid_pattern <- "^[ACGTRYKMSWBDHVN]+$"
  valid_sequences <- grepl(valid_pattern, sequences$sequence, ignore.case = TRUE)
  
  cat(sprintf("Sequences with invalid characters: %d\n", sum(!valid_sequences)))
  
  # Keep only valid sequences
  clean_sequences <- sequences[valid_sequences, ]
  
  # Limit number of sequences if specified
  if (!is.null(max_sequences) && nrow(clean_sequences) > max_sequences) {
    cat(sprintf("Sampling %d sequences from %d available\n", max_sequences, nrow(clean_sequences)))
    set.seed(123)
    sample_idx <- sample(nrow(clean_sequences), max_sequences)
    clean_sequences <- clean_sequences[sample_idx, ]
  }
  
  cat(sprintf("Final clean sequences: %d\n", nrow(clean_sequences)))
  
  # Write cleaned sequences
  NaiveR::write_fasta(clean_sequences, output_fasta)
  
  cat(sprintf("Cleaned FASTA written to: %s\n", output_fasta))
  
  return(clean_sequences)
}

#' Additional cleaning for problematic sequences
#' 
#' @param sequences Data frame with FASTA sequences
clean_sequences_strict <- function(sequences) {
  
  # Remove sequences with too many ambiguous characters
  n_chars <- nchar(sequences$sequence)
  ambiguous_chars <- stringr::str_count(sequences$sequence, "[RYKMSWBDHVN]")
  ambiguous_ratio <- ambiguous_chars / n_chars
  
  # Keep sequences with < 5% ambiguous characters
  clean_idx <- ambiguous_ratio < 0.05
  
  cat(sprintf("Removing %d sequences with >5%% ambiguous characters\n", 
              sum(!clean_idx)))
  
  sequences_clean <- sequences[clean_idx, ]
  
  # Remove sequences that are too short or too long
  seq_lengths <- nchar(sequences_clean$sequence)
  length_filter <- seq_lengths >= 200 & seq_lengths <= 2000
  
  cat(sprintf("Removing %d sequences outside length range (200-2000 bp)\n", 
              sum(!length_filter)))
  
  sequences_final <- sequences_clean[length_filter, ]
  
  return(sequences_final)
}

# Example usage:
# Run this in the benchmarking directory

# Clean the test sequences
clean_sequences <- clean_fasta_for_qiime2(
  input_fasta = "test_sequences.fasta",
  output_fasta = "test_sequences_clean.fasta",
  max_sequences = 500
)

# If you need extra strict cleaning:
# extra_clean <- clean_sequences_strict(clean_sequences)
# NaiveR::write_fasta(extra_clean, "test_sequences_extra_clean.fasta")

cat("\nSequence cleaning completed!\n")
cat("Use 'test_sequences_clean.fasta' for QIIME2 import\n")
