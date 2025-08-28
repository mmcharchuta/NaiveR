#!/bin/bash

# QIIME2 Classification Script for Benchmarking
# Run this script after setting up NaiveR benchmark

# Usage: ./run_qiime2_classification.sh <input_fasta> <output_dir>

INPUT_FASTA=${1:-"test_sequences_clean.fasta"}
OUTPUT_DIR=${2:-"qiime2_benchmark"}
CLASSIFIER_FILE="silva-138-99-nb-classifier.qza"

echo "Starting QIIME2 classification benchmark..."
echo "Input FASTA: $INPUT_FASTA"
echo "Output directory: $OUTPUT_DIR"

# Check if cleaned input file exists
if [ ! -f "$INPUT_FASTA" ]; then
    echo "Error: $INPUT_FASTA not found!"
    echo "Please run clean_sequences.R first to create cleaned FASTA file"
    exit 1
fi

# Create output directory
mkdir -p $OUTPUT_DIR

# Use existing Silva classifier
if [ ! -f "$CLASSIFIER_FILE" ]; then
    echo "Error: $CLASSIFIER_FILE not found!"
    echo "Please ensure the Silva classifier file is in the current directory"
    exit 1
fi

echo "Using existing Silva classifier: $CLASSIFIER_FILE"
echo "Current QIIME2 version: $(qiime --version)"

# Convert FASTA to QIIME2 format
echo "Converting sequences to QIIME2 format..."
echo "Using cleaned sequences (DNA format, no invalid characters)..."
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

# Run classification
echo "Running QIIME2 classification..."
echo "Note: This may fail due to scikit-learn version mismatch"
time qiime feature-classifier classify-sklearn \
  --i-classifier $CLASSIFIER_FILE \
  --i-reads $OUTPUT_DIR/test-sequences.qza \
  --o-classification $OUTPUT_DIR/taxonomy.qza \
  --verbose

# Check if classification succeeded
if [ ! -f "$OUTPUT_DIR/taxonomy.qza" ]; then
    echo ""
    echo "ERROR: Classification failed!"
    echo "This is likely due to scikit-learn version mismatch."
    echo ""
    echo "Solutions:"
    echo "1. Download a compatible classifier for QIIME2 2024.10:"
    echo "   wget https://data.qiime2.org/2024.10/common/silva-138-99-nb-classifier.qza"
    echo ""
    echo "2. Or train your own classifier with current versions:"
    echo "   Use qiime feature-classifier fit-classifier-naive-bayes"
    echo ""
    echo "3. Or use a different QIIME2 environment with older scikit-learn"
    echo ""
    echo "Skipping export and summary steps..."
    exit 1
fi

# Export results
echo "Exporting results..."
qiime tools export \
  --input-path $OUTPUT_DIR/taxonomy.qza \
  --output-path $OUTPUT_DIR/

# Create summary
echo "Creating classification summary..."
qiime metadata tabulate \
  --m-input-file $OUTPUT_DIR/taxonomy.qza \
  --o-visualization $OUTPUT_DIR/taxonomy-summary.qzv

echo "QIIME2 classification completed!"
echo "Results saved to: $OUTPUT_DIR/"
echo "Taxonomy file: $OUTPUT_DIR/taxonomy.tsv"
echo "Summary visualization: $OUTPUT_DIR/taxonomy-summary.qzv"
echo ""
echo "Next steps:"
echo "1. View results: cat $OUTPUT_DIR/taxonomy.tsv"
echo "2. Run comparison: R -e \"source('benchmark_analysis.R'); compare_with_qiime2(naiver_results, '$OUTPUT_DIR/taxonomy.tsv')\""
echo "3. To clean sequences for future runs: R -e \"source('clean_sequences.R')\""
