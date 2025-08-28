# Complete Training and Benchmarking Workflow
# This script orchestrates the entire process

cat("=== NaiveR vs QIIME2 Training & Benchmark Workflow ===\n\n")

# Step 1: Check prerequisites
cat("Step 1: Checking prerequisites...\n")

required_files <- c("ref-seqs.qza", "ref-tax.qza", "test_sequences_clean.fasta")
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  cat("Missing required files:\n")
  for (file in missing_files) {
    cat("  -", file, "\n")
  }
  cat("\nPlease ensure:\n")
  cat("- ref-seqs.qza and ref-tax.qza from https://zenodo.org/records/6395539\n")
  cat("- test_sequences_clean.fasta from clean_sequences.R\n")
  stop("Cannot proceed without required files")
}

cat("✓ All required files found\n\n")

# Step 2: Train classifiers
cat("Step 2: Training classifiers...\n")
cat("Run in terminal: chmod +x train_classifiers.sh && ./train_classifiers.sh\n")
cat("This will:\n")
cat("  - Train QIIME2 classifier (10-30 minutes)\n")
cat("  - Export Silva data for NaiveR\n")
cat("  - Clean up old files\n\n")

# Step 3: Train NaiveR
cat("Step 3: After QIIME2 training completes, train NaiveR:\n")
cat("Run in R: source('train_naiver_classifier.R')\n\n")

# Step 4: Run benchmark
cat("Step 4: Run complete benchmark:\n")
cat("Run in R: source('run_benchmark.R')\n\n")

cat("=== Manual Execution Steps ===\n")
cat("1. In terminal (WSL):\n")
cat("   chmod +x train_classifiers.sh\n")
cat("   ./train_classifiers.sh\n\n")

cat("2. In R:\n")
cat("   devtools::load_all('../')  # Load NaiveR package\n")
cat("   source('train_naiver_classifier.R')\n")
cat("   classifier <- train_naiver_classifier()\n\n")

cat("3. In R (after both classifiers trained):\n")
cat("   source('run_benchmark.R')\n")
cat("   results <- run_complete_benchmark()\n\n")

cat("Expected outputs:\n")
cat("- silva-138-nb-classifier-trained.qza (QIIME2 classifier)\n")
cat("- naiver_classifier.rds (NaiveR classifier)\n")
cat("- benchmark_comparison_results.csv (final comparison)\n")
