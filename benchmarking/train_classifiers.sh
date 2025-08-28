#!/bin/bash

# Train both QIIME2 and NaiveR classifiers from Silva 138.1 reference data
# This ensures fair comparison with identical training data

# Check required files
echo "Checking for Silva 138.1 reference files..."
if [ ! -f "ref-seqs.qza" ]; then
    echo "Error: ref-seqs.qza not found!"
    echo "Please download from: https://zenodo.org/records/6395539"
    exit 1
fi

if [ ! -f "ref-tax.qza" ]; then
    echo "Error: ref-tax.qza not found!"
    echo "Please download from: https://zenodo.org/records/6395539"
    exit 1
fi

echo "✓ Found ref-seqs.qza"
echo "✓ Found ref-tax.qza"
echo ""

# Clean up old files
echo "Cleaning workspace..."
rm -f silva-138-99-nb-classifier.qza
rm -f silva_sequences.fasta
rm -f silva_taxonomy.tsv
rm -rf qiime2_benchmark/
rm -f naiver_classifier.rds

# Train QIIME2 classifier
echo "Training QIIME2 Naive Bayes classifier..."
echo "This may take 10-30 minutes depending on your system..."
time qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs.qza \
  --i-reference-taxonomy ref-tax.qza \
  --o-classifier silva-138-nb-classifier-trained.qza \
  --verbose

if [ ! -f "silva-138-nb-classifier-trained.qza" ]; then
    echo "Error: QIIME2 classifier training failed!"
    exit 1
fi

echo "✓ QIIME2 classifier trained successfully: silva-138-nb-classifier-trained.qza"
echo ""

# Export reference data for NaiveR training
echo "Exporting Silva reference data for NaiveR..."
qiime tools export \
  --input-path ref-seqs.qza \
  --output-path silva_export/

qiime tools export \
  --input-path ref-tax.qza \
  --output-path silva_export/

# Check exported files
if [ -f "silva_export/dna-sequences.fasta" ]; then
    mv silva_export/dna-sequences.fasta silva_sequences.fasta
    echo "✓ Reference sequences exported: silva_sequences.fasta"
else
    echo "Error: Failed to export reference sequences"
    exit 1
fi

if [ -f "silva_export/taxonomy.tsv" ]; then
    mv silva_export/taxonomy.tsv silva_taxonomy.tsv
    echo "✓ Reference taxonomy exported: silva_taxonomy.tsv"
else
    echo "Error: Failed to export reference taxonomy"
    exit 1
fi

# Clean up
rm -rf silva_export/

echo ""
echo "Reference data prepared for NaiveR training:"
echo "- Silva sequences: silva_sequences.fasta"
echo "- Silva taxonomy: silva_taxonomy.tsv"
echo "- QIIME2 classifier: silva-138-nb-classifier-trained.qza"
echo ""
echo "Next steps:"
echo "1. Train NaiveR classifier in R:"
echo "   source('train_naiver_classifier.R')"
echo "2. Run benchmark comparison:"
echo "   source('run_benchmark.R')"
