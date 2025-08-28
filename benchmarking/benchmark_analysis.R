# Benchmark Analysis Script for NaiveR vs QIIME2

library(NaiveR)
library(dplyr)
library(ggplot2)

#' Compare NaiveR and QIIME2 classification results
#' 
#' @param test_fasta Path to test sequences FASTA file
#' @param true_taxonomy Optional data frame with true taxonomic assignments
#' @param output_dir Directory to save results
benchmark_classification <- function(test_fasta, true_taxonomy = NULL, output_dir = "benchmark_results") {
  
  # Create output directory
  dir.create(output_dir, showWarnings = FALSE)
  
  # Load test sequences
  cat("Loading test sequences...\n")
  test_seqs <- read_fasta(test_fasta)
  
  # Run NaiveR classification
  cat("Running NaiveR classification...\n")
  start_time <- Sys.time()
  
  # Load training data (use your preferred training set)
  data(trainset9_rdp)
  
  # Build k-mer database
  kmer_db <- build_kmer_database(
    seqs = trainset9_rdp$sequence,
    genus_labels = trainset9_rdp$taxonomy,
    klen = 8
  )
  
  # Classify sequences
  naiver_results <- data.frame(
    sequence_id = character(nrow(test_seqs)),
    taxonomy = character(nrow(test_seqs)),
    confidence = numeric(nrow(test_seqs)),
    stringsAsFactors = FALSE
  )
  
  for(i in 1:nrow(test_seqs)) {
    if(i %% 10 == 0) cat(sprintf("Processing sequence %d/%d\n", i, nrow(test_seqs)))
    
    result <- classify_sequence(
      unknown_seq = test_seqs$sequence[i],
      db = kmer_db,
      klen = 8,
      n_boot = 100
    )
    
    naiver_results$sequence_id[i] <- test_seqs$id[i]
    naiver_results$taxonomy[i] <- print_taxonomy(result)
    naiver_results$confidence[i] <- min(result$confidence)
  }
  
  naiver_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Save NaiveR results
  write.csv(naiver_results, file.path(output_dir, "naiver_results.csv"), row.names = FALSE)
  
  # Generate comparison report
  cat("Generating benchmark report...\n")
  
  # Basic statistics
  stats <- list(
    naiver_time = naiver_time,
    n_sequences = nrow(test_seqs),
    naiver_mean_confidence = mean(naiver_results$confidence, na.rm = TRUE),
    naiver_median_confidence = median(naiver_results$confidence, na.rm = TRUE)
  )
  
  # Save statistics
  saveRDS(stats, file.path(output_dir, "benchmark_stats.rds"))
  
  # Create plots
  create_benchmark_plots(naiver_results, output_dir)
  
  cat(sprintf("Benchmark completed. Results saved to: %s\n", output_dir))
  cat(sprintf("NaiveR processing time: %.2f seconds\n", naiver_time))
  cat(sprintf("Average sequences per second: %.2f\n", nrow(test_seqs) / naiver_time))
  
  return(naiver_results)
}

#' Create benchmark visualization plots
create_benchmark_plots <- function(naiver_results, output_dir) {
  
  # Confidence distribution plot
  p1 <- ggplot(naiver_results, aes(x = confidence)) +
    geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
    labs(title = "NaiveR Confidence Score Distribution",
         x = "Confidence Score",
         y = "Number of Classifications") +
    theme_minimal()
  
  ggsave(file.path(output_dir, "confidence_distribution.png"), p1, width = 8, height = 6)
  
  # Taxonomic level assignment plot (count classifications at each level)
  tax_levels <- strsplit(naiver_results$taxonomy, ";")
  level_counts <- sapply(tax_levels, length)
  
  level_df <- data.frame(
    taxonomic_levels = factor(level_counts),
    count = as.numeric(table(level_counts))
  )
  
  p2 <- ggplot(level_df, aes(x = taxonomic_levels, y = count)) +
    geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
    labs(title = "Classification Depth Distribution",
         x = "Number of Taxonomic Levels Assigned",
         y = "Number of Sequences") +
    theme_minimal()
  
  ggsave(file.path(output_dir, "classification_depth.png"), p2, width = 8, height = 6)
}

#' Compare results with QIIME2 output (after running QIIME2 separately)
#' 
#' @param naiver_results Results from benchmark_classification()
#' @param qiime2_file Path to QIIME2 taxonomy output file
#' @param output_dir Directory to save comparison results
compare_with_qiime2 <- function(naiver_results, qiime2_file, output_dir = "benchmark_results") {
  
  # Load QIIME2 results
  qiime2_results <- read.table(qiime2_file, sep = "\t", header = TRUE, 
                              stringsAsFactors = FALSE, comment.char = "")
  
  # Standardize sequence IDs for merging
  colnames(qiime2_results)[1] <- "sequence_id"
  
  # Merge results
  comparison <- merge(naiver_results, qiime2_results, by = "sequence_id", all = TRUE)
  
  # Calculate agreement metrics
  # (This will depend on the specific format of your taxonomic assignments)
  
  # Save comparison
  write.csv(comparison, file.path(output_dir, "method_comparison.csv"), row.names = FALSE)
  
  return(comparison)
}

# Example usage:
# results <- benchmark_classification("test_sequences.fasta")
# comparison <- compare_with_qiime2(results, "qiime2-results/taxonomy.tsv")
