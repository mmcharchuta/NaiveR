#!/bin/bash

# Fixed QIIME2 Classification Script with proper version compatibility
# Run this script after setting up NaiveR benchmark

# Usage: ./run_qiime2_classification_fixed.sh <input_fasta> <output_dir>

INPUT_FASTA=${1:-"test_sequences_clean.fasta"}
OUTPUT_DIR=${2:-"qiime2_benchmark"}

# Use classifier compatible with QIIME2 2024.10
CLASSIFIER_URL="https://data.qiime2.org/2024.10/common/silva-138-99-nb-classifier.qza"
CLASSIFIER_FILE="silva-138-99-nb-classifier-2024.10.qza"

echo "Starting QIIME2 classification benchmark (version compatible)..."
echo "Input FASTA: $INPUT_FASTA"
echo "Output directory: $OUTPUT_DIR"
echo "Using QIIME2 2024.10 compatible classifier"

# Check if cleaned input file exists
if [ ! -f "$INPUT_FASTA" ]; then
    echo "Error: $INPUT_FASTA not found!"
    echo "Please run clean_sequences.R first to create cleaned FASTA file"
    exit 1
fi

# Create output directory
mkdir -p $OUTPUT_DIR

# Download compatible Silva classifier
if [ ! -f "$CLASSIFIER_FILE" ]; then
    echo "Downloading Silva 138.1 classifier (2024.10 compatible)..."
    wget $CLASSIFIER_URL -O $CLASSIFIER_FILE
    
    if [ $? -ne 0 ]; then
        echo "Download failed. Trying alternative sources..."
        
        # Try alternative URLs for 2024.10
        ALT_URL="https://data.qiime2.org/classifiers/silva-138-99-nb-classifier.qza"
        wget $ALT_URL -O $CLASSIFIER_FILE
        
        if [ $? -ne 0 ]; then
            echo "Could not download compatible classifier."
            echo "Please download manually from: https://docs.qiime2.org/2024.10/data-resources/"
            exit 1
        fi
    fi
fi

# Check file size (should be > 100MB)
file_size=$(stat -c%s "$CLASSIFIER_FILE" 2>/dev/null || stat -f%z "$CLASSIFIER_FILE" 2>/dev/null || echo 0)
if [ "$file_size" -lt 100000000 ]; then
    echo "Warning: Classifier file seems too small ($file_size bytes)"
    echo "This might indicate a download error or wrong file format"
fi

# Convert FASTA to QIIME2 format
echo "Converting sequences to QIIME2 format..."
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path $INPUT_FASTA \
  --output-path $OUTPUT_DIR/test-sequences.qza

# Verify import was successful
if [ ! -f "$OUTPUT_DIR/test-sequences.qza" ]; then
    echo "Error: Failed to import sequences to QIIME2 format"
    exit 1
fi
echo "Successfully imported sequences to QIIME2 format"

# Run classification with error handling
echo "Running QIIME2 classification..."
echo "Classifier: $CLASSIFIER_FILE"

time qiime feature-classifier classify-sklearn \
  --i-classifier $CLASSIFIER_FILE \
  --i-reads $OUTPUT_DIR/test-sequences.qza \
  --o-classification $OUTPUT_DIR/taxonomy.qza \
  --verbose

# Check if classification succeeded
if [ ! -f "$OUTPUT_DIR/taxonomy.qza" ]; then
    echo ""
    echo "ERROR: Classification failed!"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check QIIME2 version: qiime --version"
    echo "2. Check available classifiers at: https://docs.qiime2.org/2024.10/data-resources/"
    echo "3. Try training your own classifier:"
    echo "   qiime feature-classifier fit-classifier-naive-bayes \\"
    echo "     --i-reference-reads silva-ref-seqs.qza \\"
    echo "     --i-reference-taxonomy silva-ref-taxonomy.qza \\"
    echo "     --o-classifier custom-classifier.qza"
    echo ""
    exit 1
fi

echo "Classification completed successfully!"

# Export results
echo "Exporting results..."
qiime tools export \
  --input-path $OUTPUT_DIR/taxonomy.qza \
  --output-path $OUTPUT_DIR/

# Verify export
if [ ! -f "$OUTPUT_DIR/taxonomy.tsv" ]; then
    echo "Warning: Export may have failed - taxonomy.tsv not found"
else
    echo "Results exported successfully"
    echo "Number of classified sequences: $(tail -n +2 $OUTPUT_DIR/taxonomy.tsv | wc -l)"
fi

# Create summary (optional, may fail if taxonomy.qza has issues)
echo "Creating classification summary..."
qiime metadata tabulate \
  --m-input-file $OUTPUT_DIR/taxonomy.qza \
  --o-visualization $OUTPUT_DIR/taxonomy-summary.qzv 2>/dev/null

echo ""
echo "QIIME2 classification completed!"
echo "Results saved to: $OUTPUT_DIR/"
echo "Taxonomy file: $OUTPUT_DIR/taxonomy.tsv"

if [ -f "$OUTPUT_DIR/taxonomy.tsv" ]; then
    echo ""
    echo "Preview of results:"
    head -5 "$OUTPUT_DIR/taxonomy.tsv"
    echo ""
    echo "Next steps:"
    echo "1. View full results: cat $OUTPUT_DIR/taxonomy.tsv"
    echo "2. Run comparison in R:"
    echo "   source('benchmark_analysis.R')"
    echo "   naiver_results <- benchmark_classification('$INPUT_FASTA')"
    echo "   comparison <- compare_with_qiime2(naiver_results, '$OUTPUT_DIR/taxonomy.tsv')"
fi
