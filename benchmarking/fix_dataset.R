# Quick Fix Script for Test Dataset Preparation
# Run this from the benchmarking directory

# 1. Load NaiveR package (use devtools since not installed)
devtools::load_all("..")  # Load from parent directory

# 2. Extract the downloaded compressed file
if (file.exists("silva_sequences.fasta.gz")) {
  cat("Extracting silva_sequences.fasta.gz...\n")
  
  # Install R.utils if needed for extraction
  if (!require("R.utils", quietly = TRUE)) {
    install.packages("R.utils")
    library(R.utils)
  }
  
  # Extract the file
  R.utils::gunzip("silva_sequences.fasta.gz", "silva_sequences.fasta", remove = FALSE)
  cat("Extraction completed.\n")
} else {
  cat("silva_sequences.fasta.gz not found. Please download it first.\n")
}

# 3. Check if extracted file exists
if (file.exists("silva_sequences.fasta")) {
  cat("Reading SILVA sequences...\n")
  
  # Read the FASTA file
  silva_data <- read_fasta("silva_sequences.fasta")
  cat(sprintf("Total sequences loaded: %d\n", nrow(silva_data)))
  
  # Create test subset
  set.seed(123)  # For reproducibility
  n_test <- min(500, nrow(silva_data))  # Take 500 or all available
  test_indices <- sample(nrow(silva_data), n_test)
  test_data <- silva_data[test_indices, ]
  
  cat(sprintf("Created test dataset with %d sequences.\n", nrow(test_data)))
  
  # Save test dataset
  write_fasta(test_data, "test_sequences.fasta")
  cat("Saved test_sequences.fasta\n")
  
  # Extract true taxonomy for accuracy testing
  true_taxonomy <- data.frame(
    sequence_id = test_data$id,
    true_taxonomy = test_data$comment,  # or wherever taxonomy is stored
    stringsAsFactors = FALSE
  )
  
  write.csv(true_taxonomy, "true_taxonomy.csv", row.names = FALSE)
  cat("Saved true_taxonomy.csv\n")
  
  cat("\nTest dataset preparation completed successfully!\n")
  cat("Files created:\n")
  cat("  - test_sequences.fasta\n")
  cat("  - true_taxonomy.csv\n")
  
} else {
  cat("silva_sequences.fasta not found. Please extract the compressed file first.\n")
}
