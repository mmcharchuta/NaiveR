# Complete benchmark comparison between NaiveR and QIIME2
# Both classifiers trained on identical Silva 138.1 data

library(NaiveR)

# Load our functions
source("train_naiver_classifier.R")

run_complete_benchmark <- function(test_fasta = "test_sequences_clean.fasta") {
  
  cat("=== Complete NaiveR vs QIIME2 Benchmark ===\n\n")
  
  # 1. Check if classifiers exist
  if (!file.exists("naiver_classifier.rds")) {
    cat("Training NaiveR classifier...\n")
    naiver_classifier <- train_naiver_classifier()
  } else {
    cat("Loading existing NaiveR classifier...\n")
    naiver_classifier <- readRDS("naiver_classifier.rds")
  }
  
  if (!file.exists("silva-138-nb-classifier-trained.qza")) {
    stop("QIIME2 classifier not found! Run train_classifiers.sh first.")
  }
  
  # 2. Test NaiveR classification
  cat("\n--- Testing NaiveR Classification ---\n")
  if (!file.exists(test_fasta)) {
    stop("Test sequences not found: ", test_fasta)
  }
  
  test_sequences <- read_fasta(test_fasta)
  cat("Loaded", length(test_sequences), "test sequences\n")
  
  # Run NaiveR classification
  cat("Running NaiveR classification...\n")
  start_time <- Sys.time()
  
  naiver_results <- data.frame(
    sequence_id = names(test_sequences),
    naiver_genus = character(length(test_sequences)),
    naiver_confidence = numeric(length(test_sequences)),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(test_sequences)) {
    result <- classify_sequence(test_sequences[i], naiver_classifier$kmer_database)
    naiver_results$naiver_genus[i] <- result$classification
    naiver_results$naiver_confidence[i] <- result$confidence
    
    if (i %% 10 == 0) cat("Processed", i, "/", length(test_sequences), "sequences\n")
  }
  
  naiver_time <- as.numeric(Sys.time() - start_time)
  cat("NaiveR classification completed in", round(naiver_time, 2), "seconds\n")
  
  # 3. Run QIIME2 classification
  cat("\n--- Running QIIME2 Classification ---\n")
  qiime_output_dir <- "qiime2_benchmark_trained"
  
  # Create QIIME2 classification script with trained classifier
  qiime_script <- '#!/bin/bash
  
INPUT_FASTA="test_sequences_clean.fasta"
OUTPUT_DIR="qiime2_benchmark_trained"
CLASSIFIER_FILE="silva-138-nb-classifier-trained.qza"

mkdir -p $OUTPUT_DIR

echo "Running QIIME2 classification with trained classifier..."

# Convert to QIIME2 format
qiime tools import \\
  --type "FeatureData[Sequence]" \\
  --input-path $INPUT_FASTA \\
  --output-path $OUTPUT_DIR/test-sequences.qza

# Run classification
time qiime feature-classifier classify-sklearn \\
  --i-classifier $CLASSIFIER_FILE \\
  --i-reads $OUTPUT_DIR/test-sequences.qza \\
  --o-classification $OUTPUT_DIR/taxonomy.qza

# Export results
qiime tools export \\
  --input-path $OUTPUT_DIR/taxonomy.qza \\
  --output-path $OUTPUT_DIR/

echo "QIIME2 classification completed!"
'
  
  writeLines(qiime_script, "run_qiime2_trained.sh")
  system("chmod +x run_qiime2_trained.sh")
  
  cat("Running QIIME2 classification (this may take a few minutes)...\n")
  system("./run_qiime2_trained.sh")
  
  # 4. Load QIIME2 results
  qiime_results_file <- file.path(qiime_output_dir, "taxonomy.tsv")
  if (!file.exists(qiime_results_file)) {
    stop("QIIME2 results not found! Classification may have failed.")
  }
  
  qiime_results <- read.table(qiime_results_file, sep = "\t", header = TRUE, 
                             stringsAsFactors = FALSE)
  cat("Loaded QIIME2 results for", nrow(qiime_results), "sequences\n")
  
  # Parse QIIME2 genus classifications
  parse_qiime_genus <- function(taxon_string) {
    parts <- strsplit(as.character(taxon_string), ";")[[1]]
    genus_part <- parts[grepl("g__", parts)]
    if (length(genus_part) > 0) {
      genus <- gsub("^.*g__", "", genus_part[1])
      genus <- gsub("^\\s+|\\s+$", "", genus)  # trim whitespace
      if (genus != "" && genus != "unidentified") {
        return(genus)
      }
    }
    return("Unclassified")
  }
  
  qiime_results$qiime_genus <- sapply(qiime_results$Taxon, parse_qiime_genus)
  
  # 5. Compare results
  cat("\n--- Comparison Analysis ---\n")
  
  # Merge results
  comparison <- merge(naiver_results, qiime_results, 
                     by.x = "sequence_id", by.y = "Feature.ID", all = TRUE)
  
  # Calculate agreement
  agreement <- comparison$naiver_genus == comparison$qiime_genus
  agreement[is.na(agreement)] <- FALSE
  
  accuracy <- sum(agreement) / nrow(comparison)
  
  cat("Results Summary:\n")
  cat("- Total sequences:", nrow(comparison), "\n")
  cat("- Agreement between methods:", sum(agreement), "sequences (", 
      round(accuracy * 100, 1), "%)\n")
  cat("- NaiveR classified:", sum(!is.na(comparison$naiver_genus)), "sequences\n")
  cat("- QIIME2 classified:", sum(!is.na(comparison$qiime_genus)), "sequences\n")
  cat("- NaiveR processing time:", round(naiver_time, 2), "seconds\n")
  
  # Show disagreements
  disagreements <- comparison[!agreement & !is.na(comparison$naiver_genus) & 
                             !is.na(comparison$qiime_genus), ]
  
  if (nrow(disagreements) > 0) {
    cat("\nTop 10 disagreements:\n")
    print(disagreements[1:min(10, nrow(disagreements)), 
                       c("sequence_id", "naiver_genus", "qiime_genus", 
                         "naiver_confidence", "Confidence")])
  }
  
  # Genus distribution comparison
  cat("\nGenus distribution:\n")
  naiver_genera <- table(comparison$naiver_genus)
  qiime_genera <- table(comparison$qiime_genus)
  
  cat("NaiveR top genera:\n")
  print(head(sort(naiver_genera, decreasing = TRUE), 10))
  
  cat("\nQIIME2 top genera:\n")
  print(head(sort(qiime_genera, decreasing = TRUE), 10))
  
  # Save results
  write.csv(comparison, "benchmark_comparison_results.csv", row.names = FALSE)
  cat("\nDetailed results saved to: benchmark_comparison_results.csv\n")
  
  return(list(
    comparison = comparison,
    accuracy = accuracy,
    naiver_time = naiver_time,
    n_sequences = nrow(comparison)
  ))
}

# Run benchmark if called as script
if (!interactive()) {
  results <- run_complete_benchmark()
  cat("\nBenchmark completed successfully!\n")
}
