# Download and Prepare Test Dataset for NaiveR Benchmarking

# Load required packages
if (!require("R.utils", quietly = TRUE)) {
  install.packages("R.utils")
  library(R.utils)
}

# Note: Use devtools::load_all() instead of library(NaiveR) for development
# devtools::load_all("..") # Load from parent directory

#' Download and prepare SILVA test dataset
#' 
#' @param n_sequences Number of sequences to sample for testing
#' @param output_dir Directory to save test files
#' @param seed Random seed for reproducibility
download_silva_test <- function(n_sequences = 1000, output_dir = "test_data", seed = 123) {
  
  # Create output directory
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  cat("Downloading SILVA reference sequences...\n")
  
  # Download SILVA sequences (this might take a while)
  silva_url <- "https://www.arb-silva.de/fileadmin/silva_databases/release_138_1/Exports/SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz"
  silva_file <- file.path(output_dir, "silva_sequences.fasta.gz")
  
  if (!file.exists(silva_file)) {
    download.file(silva_url, silva_file, mode = "wb")
    cat("Download completed.\n")
  } else {
    cat("SILVA file already exists, skipping download.\n")
  }
  
  # Extract if needed
  silva_fasta <- file.path(output_dir, "silva_sequences.fasta")
  if (!file.exists(silva_fasta)) {
    cat("Extracting sequences...\n")
    R.utils::gunzip(silva_file, silva_fasta)
  }
  
  # Read sequences
  cat("Reading SILVA sequences...\n")
  silva_data <- read_fasta(silva_fasta)
  
  cat(sprintf("Total sequences available: %d\n", nrow(silva_data)))
  
  # Filter sequences for quality
  cat("Filtering sequences...\n")
  
  # Remove sequences with too many N's or too short/long
  clean_sequences <- silva_data[
    nchar(silva_data$sequence) >= 250 & 
    nchar(silva_data$sequence) <= 2000 &
    stringr::str_count(silva_data$sequence, "N") / nchar(silva_data$sequence) < 0.01,
  ]
  
  cat(sprintf("Sequences after filtering: %d\n", nrow(clean_sequences)))
  
  # Sample test sequences
  set.seed(seed)
  if (n_sequences > nrow(clean_sequences)) {
    n_sequences <- nrow(clean_sequences)
    cat(sprintf("Reducing sample size to available sequences: %d\n", n_sequences))
  }
  
  test_indices <- sample(nrow(clean_sequences), n_sequences)
  test_sequences <- clean_sequences[test_indices, ]
  
  # Extract taxonomy from comments (SILVA format parsing)
  true_taxonomy <- extract_silva_taxonomy(test_sequences)
  
  # Save test files
  test_fasta <- file.path(output_dir, "test_sequences.fasta")
  taxonomy_file <- file.path(output_dir, "true_taxonomy.csv")
  
  write_fasta(test_sequences, test_fasta)
  write.csv(true_taxonomy, taxonomy_file, row.names = FALSE)
  
  cat(sprintf("Test dataset created:\n"))
  cat(sprintf("  Sequences: %s (%d sequences)\n", test_fasta, nrow(test_sequences)))
  cat(sprintf("  Taxonomy: %s\n", taxonomy_file))
  
  return(list(
    sequences = test_sequences,
    taxonomy = true_taxonomy,
    files = list(fasta = test_fasta, taxonomy = taxonomy_file)
  ))
}

#' Extract taxonomy from SILVA sequence headers
#' 
#' @param silva_data Data frame with SILVA sequences
extract_silva_taxonomy <- function(silva_data) {
  
  # SILVA format typically has taxonomy in the comment field
  # Format: "taxonomy_string organism_name"
  
  taxonomy_data <- data.frame(
    sequence_id = silva_data$id,
    true_taxonomy = silva_data$comment,
    stringsAsFactors = FALSE
  )
  
  # Clean up taxonomy strings
  # Remove organism names and extra information
  taxonomy_data$true_taxonomy <- gsub("\\s+[A-Za-z]+\\s*$", "", taxonomy_data$true_taxonomy)
  taxonomy_data$true_taxonomy <- gsub("^\\s+|\\s+$", "", taxonomy_data$true_taxonomy)
  
  return(taxonomy_data)
}

#' Download mock community dataset (alternative)
#' 
#' @param output_dir Directory to save files
download_mock_community <- function(output_dir = "test_data") {
  
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Create ZYMO mock community reference
  zymo_references <- data.frame(
    id = c("zymo_01", "zymo_02", "zymo_03", "zymo_04", "zymo_05", 
           "zymo_06", "zymo_07", "zymo_08"),
    sequence = c(
      # These would need to be actual 16S sequences for the ZYMO species
      # Placeholder sequences here - replace with real sequences
      "AGAGTTTGATCCTGGCTCAG...",  # Bacillus subtilis
      "AGAGTTTGATCCTGGCTCAG...",  # Enterococcus faecalis  
      "AGAGTTTGATCCTGGCTCAG...",  # Escherichia coli
      "AGAGTTTGATCCTGGCTCAG...",  # Lactobacillus fermentum
      "AGAGTTTGATCCTGGCTCAG...",  # Listeria monocytogenes
      "AGAGTTTGATCCTGGCTCAG...",  # Pseudomonas aeruginosa
      "AGAGTTTGATCCTGGCTCAG...",  # Salmonella enterica
      "AGAGTTTGATCCTGGCTCAG..."   # Staphylococcus aureus
    ),
    comment = c(
      "Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_subtilis",
      "Bacteria;Firmicutes;Bacilli;Lactobacillales;Enterococcaceae;Enterococcus;Enterococcus_faecalis",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Escherichia;Escherichia_coli",
      "Bacteria;Firmicutes;Bacilli;Lactobacillales;Lactobacillaceae;Lactobacillus;Lactobacillus_fermentum",
      "Bacteria;Firmicutes;Bacilli;Bacillales;Listeriaceae;Listeria;Listeria_monocytogenes",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Pseudomonadales;Pseudomonadaceae;Pseudomonas;Pseudomonas_aeruginosa",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Salmonella;Salmonella_enterica",
      "Bacteria;Firmicutes;Bacilli;Bacillales;Staphylococcaceae;Staphylococcus;Staphylococcus_aureus"
    ),
    stringsAsFactors = FALSE
  )
  
  # Save mock community files
  mock_fasta <- file.path(output_dir, "mock_community.fasta")
  mock_taxonomy <- file.path(output_dir, "mock_taxonomy.csv")
  
  write_fasta(zymo_references, mock_fasta)
  
  taxonomy_df <- data.frame(
    sequence_id = zymo_references$id,
    true_taxonomy = zymo_references$comment,
    stringsAsFactors = FALSE
  )
  
  write.csv(taxonomy_df, mock_taxonomy, row.names = FALSE)
  
  cat("Mock community dataset created:\n")
  cat(sprintf("  Sequences: %s\n", mock_fasta))
  cat(sprintf("  Taxonomy: %s\n", mock_taxonomy))
  
  return(list(
    sequences = zymo_references,
    taxonomy = taxonomy_df,
    files = list(fasta = mock_fasta, taxonomy = mock_taxonomy)
  ))
}

# Example usage:
# 
# # Download SILVA test dataset (1000 sequences)
# silva_test <- download_silva_test(n_sequences = 1000)
# 
# # Or use mock community for quick testing
# mock_test <- download_mock_community()
#
# # Then run benchmark:
# source("benchmark_analysis.R")
# results <- benchmark_classification(silva_test$files$fasta, silva_test$taxonomy)
