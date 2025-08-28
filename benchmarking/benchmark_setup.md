# Benchmarking NaiveR vs QIIME2 Feature-Classifier

## Comparison Setup

### Tools to Compare:
1. **NaiveR** (my package)
2. **QIIME2 feature-classifier** with `classify-sklearn` using Silva 138.1 animal-distal-gut taxonomy classifier

### Dataset Requirements:
- Same input sequences for both tools
- Known taxonomic classifications (for accuracy assessment)
- Representative sequences from animal gut microbiome studies

## Benchmark Protocol

### Step 1: Prepare Test Dataset
```r
# Load your test sequences
test_sequences <- read_fasta("path/to/test_sequences.fasta")

# Ensure sequences are suitable for both tools
# - 16S rRNA sequences
# - Quality filtered
# - Representative sequences (not full ASV table)
```

### Step 2: Run NaiveR Classification
```r
library(NaiveR)

# Build database (if using custom training data)
# Or use provided trainset
data(trainset9_rdp)  # or trainset9_pds

# Build k-mer database
kmer_db <- build_kmer_database(
  seqs = trainset9_rdp$sequence,
  genus_labels = trainset9_rdp$taxonomy,
  klen = 8
)

# Classify test sequences
naiver_results <- data.frame(
  sequence_id = character(),
  taxonomy = character(),
  confidence = numeric(),
  stringsAsFactors = FALSE
)

for(i in 1:nrow(test_sequences)) {
  result <- classify_sequence(
    unknown_seq = test_sequences$sequence[i],
    db = kmer_db,
    klen = 8,
    n_boot = 100
  )
  
  naiver_results[i, ] <- list(
    sequence_id = test_sequences$id[i],
    taxonomy = print_taxonomy(result),
    confidence = min(result$confidence)
  )
}
```

### Step 3: Run QIIME2 Classification
```bash
# Install QIIME2 (if not already installed)
# conda install -c qiime2 qiime2

# Download Silva 138.1 animal-distal-gut classifier
wget https://data.qiime2.org/2023.5/common/silva-138-99-nb-classifier.qza

# Convert your FASTA to QIIME2 format
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path test_sequences.fasta \
  --output-path test-sequences.qza

# Run classification
qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads test-sequences.qza \
  --o-classification qiime2-taxonomy.qza

# Export results
qiime tools export \
  --input-path qiime2-taxonomy.qza \
  --output-path qiime2-results
```

### Step 4: Compare Results

#### Metrics to Evaluate:
1. **Accuracy** (if true taxonomy known)
2. **Precision/Recall** at different taxonomic levels
3. **Confidence scores** distribution
4. **Processing time**
5. **Memory usage**
6. **Agreement between methods**

#### Comparison Script:
```r
# Load QIIME2 results
qiime2_results <- read.table("qiime2-results/taxonomy.tsv", 
                            sep="\t", header=TRUE, stringsAsFactors=FALSE)

# Standardize taxonomy formats for comparison
# Parse taxonomic levels consistently
# Calculate agreement metrics
```

## Expected Outputs

### Performance Metrics Table:
| Metric | NaiveR | QIIME2 | Notes |
|--------|--------|--------|-------|
| Accuracy (%) | | | Overall correct classifications |
| Genus-level accuracy (%) | | | |
| Family-level accuracy (%) | | | |
| Processing time (seconds) | | | |
| Memory usage (MB) | | | |
| Average confidence | | | |

### Visualization Scripts:
- Confusion matrices
- Confidence score distributions
- Agreement plots
- Processing time comparisons

## Notes
- Ensure both tools use comparable confidence thresholds
- Document any preprocessing differences
- Consider multiple test datasets for robustness
- Report method-specific parameters used
