# Train NaiveR classifier from Silva 138.1 reference data
# This script trains NaiveR using the same Silva data as QIIME2

library(NaiveR)

# Load our NaiveR functions
if (!exists("build_kmer_database")) {
  source("../R/kmers.R")
  # Load C++ functions
  if (file.exists("../src/RcppExports.cpp")) {
    library(Rcpp)
    sourceCpp("../src/kmers.cpp")
  }
}

train_naiver_classifier <- function(sequences_file = "silva_sequences.fasta", 
                                   taxonomy_file = "silva_taxonomy.tsv",
                                   output_file = "naiver_classifier.rds",
                                   kmer_size = 6) {
  
  cat("Training NaiveR classifier from Silva 138.1 data...\n")
  cat("Sequences file:", sequences_file, "\n")
  cat("Taxonomy file:", taxonomy_file, "\n")
  cat("K-mer size:", kmer_size, "\n\n")
  
  # Check input files
  if (!file.exists(sequences_file)) {
    stop("Error: ", sequences_file, " not found! Run train_classifiers.sh first.")
  }
  
  if (!file.exists(taxonomy_file)) {
    stop("Error: ", taxonomy_file, " not found! Run train_classifiers.sh first.")
  }
  
  # Read Silva sequences
  cat("Reading Silva reference sequences...\n")
  silva_sequences <- read_fasta(sequences_file)
  cat("Loaded", length(silva_sequences), "reference sequences\n")
  
  # Read Silva taxonomy
  cat("Reading Silva taxonomy...\n")
  silva_taxonomy <- read.table(taxonomy_file, sep = "\t", header = TRUE, 
                              stringsAsFactors = FALSE, quote = "")
  
  # The taxonomy file should have columns: Feature.ID, Taxon, Confidence
  if (!"Feature.ID" %in% names(silva_taxonomy)) {
    # Try alternative column names
    if ("id" %in% names(silva_taxonomy)) {
      names(silva_taxonomy)[names(silva_taxonomy) == "id"] <- "Feature.ID"
    } else if (ncol(silva_taxonomy) >= 2) {
      names(silva_taxonomy)[1] <- "Feature.ID"
      names(silva_taxonomy)[2] <- "Taxon"
    }
  }
  
  cat("Loaded taxonomy for", nrow(silva_taxonomy), "sequences\n")
  cat("Sample taxonomy entries:\n")
  print(head(silva_taxonomy, 3))
  
  # Match sequences with taxonomy
  cat("\nMatching sequences with taxonomy...\n")
  seq_ids <- names(silva_sequences)
  tax_ids <- silva_taxonomy$Feature.ID
  
  # Find common IDs
  common_ids <- intersect(seq_ids, tax_ids)
  cat("Found", length(common_ids), "sequences with matching taxonomy\n")
  
  if (length(common_ids) < 100) {
    warning("Very few sequences matched! Check ID formats.")
    cat("Sample sequence IDs:", head(seq_ids, 5), "\n")
    cat("Sample taxonomy IDs:", head(tax_ids, 5), "\n")
  }
  
  # Filter to matched sequences
  matched_sequences <- silva_sequences[common_ids]
  matched_taxonomy <- silva_taxonomy[silva_taxonomy$Feature.ID %in% common_ids, ]
  
  # Extract genus-level classification (for fair comparison with typical usage)
  cat("Extracting genus-level classifications...\n")
  parse_genus <- function(taxon_string) {
    # Silva format: "d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacterales;f__Enterobacteriaceae;g__Escherichia;s__Escherichia_coli"
    parts <- strsplit(as.character(taxon_string), ";")[[1]]
    genus_part <- parts[grepl("^g__", parts)]
    if (length(genus_part) > 0) {
      genus <- gsub("^g__", "", genus_part[1])
      if (genus != "" && genus != "unidentified") {
        return(genus)
      }
    }
    return(NA)
  }
  
  genera <- sapply(matched_taxonomy$Taxon, parse_genus)
  valid_genera <- !is.na(genera) & genera != ""
  
  cat("Found", sum(valid_genera), "sequences with valid genus classifications\n")
  
  # Create training dataset
  training_sequences <- matched_sequences[valid_genera]
  training_genera <- genera[valid_genera]
  
  # Show genus distribution
  genus_counts <- table(training_genera)
  cat("Training on", length(unique(training_genera)), "different genera\n")
  cat("Most common genera:\n")
  print(head(sort(genus_counts, decreasing = TRUE), 10))
  
  # Build k-mer database
  cat("\nBuilding k-mer database (k =", kmer_size, ")...\n")
  cat("This may take several minutes for large reference databases...\n")
  
  start_time <- Sys.time()
  kmer_db <- build_kmer_database(training_sequences, training_genera, kmer_size)
  end_time <- Sys.time()
  
  cat("K-mer database built in", round(as.numeric(end_time - start_time), 2), "seconds\n")
  cat("Database contains", length(kmer_db$kmers), "unique k-mers\n")
  cat("Covers", length(unique(kmer_db$labels)), "genera\n")
  
  # Save classifier
  classifier <- list(
    kmer_database = kmer_db,
    kmer_size = kmer_size,
    training_info = list(
      n_sequences = length(training_sequences),
      n_genera = length(unique(training_genera)),
      silva_version = "138.1",
      trained_date = Sys.Date()
    )
  )
  
  saveRDS(classifier, output_file)
  cat("NaiveR classifier saved to:", output_file, "\n")
  
  return(classifier)
}

# Train the classifier if running as script
if (!interactive()) {
  classifier <- train_naiver_classifier()
  cat("\nNaiveR classifier training completed!\n")
}
