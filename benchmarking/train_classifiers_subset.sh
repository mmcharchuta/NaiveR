#!/bin/bash

# Memory-efficient QIIME2 training with subset of Silva data
# This creates a smaller, faster classifier for benchmarking

# Check required files
echo "Checking for Silva 138.1 reference files..."
if [ ! -f "ref-seqs.qza" ]; then
    echo "Error: ref-seqs.qza not found!"
    exit 1
fi

if [ ! -f "ref-tax.qza" ]; then
    echo "Error: ref-tax.qza not found!"
    exit 1
fi

echo "✓ Found ref-seqs.qza"
echo "✓ Found ref-tax.qza"
echo ""

# Clean up old files
echo "Cleaning workspace..."
rm -f silva-138-nb-classifier-trained.qza
rm -f silva_sequences.fasta
rm -f silva_taxonomy.tsv
rm -rf qiime2_benchmark/
rm -f naiver_classifier.rds
rm -rf silva_subset/

# First, export the full Silva data to examine it
echo "Exporting Silva reference data..."
mkdir -p silva_subset

qiime tools export \
  --input-path ref-seqs.qza \
  --output-path silva_subset/

qiime tools export \
  --input-path ref-tax.qza \
  --output-path silva_subset/

# Check what we have
echo "Checking exported data..."
if [ -f "silva_subset/dna-sequences.fasta" ]; then
    seq_count=$(grep -c "^>" silva_subset/dna-sequences.fasta)
    echo "Total sequences in Silva database: $seq_count"
else
    echo "Error: Failed to export sequences"
    exit 1
fi

if [ -f "silva_subset/taxonomy.tsv" ]; then
    tax_count=$(tail -n +2 silva_subset/taxonomy.tsv | wc -l)
    echo "Total taxonomy entries: $tax_count"
else
    echo "Error: Failed to export taxonomy"
    exit 1
fi

# Create a subset for memory-efficient training
echo "Creating subset for training (to avoid memory issues)..."
SUBSET_SIZE=10000  # Use 10k sequences instead of full database

# Take first N sequences for consistent results
head -n $((SUBSET_SIZE * 2)) silva_subset/dna-sequences.fasta > silva_subset/subset_sequences.fasta

# Count actual sequences in subset
subset_count=$(grep -c "^>" silva_subset/subset_sequences.fasta)
echo "Created subset with $subset_count sequences"

# Extract corresponding taxonomy IDs (handle format with spaces)
echo "Extracting subset taxonomy..."
grep "^>" silva_subset/subset_sequences.fasta | sed 's/^>//' | sed 's/ .*//' > silva_subset/subset_ids.txt

echo "Sample IDs extracted:"
head -3 silva_subset/subset_ids.txt

# Filter taxonomy file
head -1 silva_subset/taxonomy.tsv > silva_subset/subset_taxonomy.tsv

# Check taxonomy file format
echo "Sample taxonomy entries:"
head -3 silva_subset/taxonomy.tsv

# Filter taxonomy entries - need to match first column
while read id; do
    grep "^$id[[:space:]]" silva_subset/taxonomy.tsv >> silva_subset/subset_taxonomy.tsv
done < silva_subset/subset_ids.txt

subset_tax_count=$(tail -n +2 silva_subset/subset_taxonomy.tsv | wc -l)
echo "Subset taxonomy entries: $subset_tax_count"

# Import subset back to QIIME2
echo "Importing subset data to QIIME2..."
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path silva_subset/subset_sequences.fasta \
  --output-path silva_subset/subset-seqs.qza

# Check if we need to adjust the taxonomy import format
echo "Checking taxonomy file format..."
if [ $(head -1 silva_subset/subset_taxonomy.tsv | grep -c "Feature ID") -gt 0 ]; then
    echo "Converting taxonomy file format for QIIME2..."
    # Convert "Feature ID\tTaxon" to headerless format expected by QIIME2
    tail -n +2 silva_subset/subset_taxonomy.tsv > silva_subset/subset_taxonomy_headerless.tsv
    
    qiime tools import \
      --type 'FeatureData[Taxonomy]' \
      --input-format HeaderlessTSVTaxonomyFormat \
      --input-path silva_subset/subset_taxonomy_headerless.tsv \
      --output-path silva_subset/subset-tax.qza
else
    qiime tools import \
      --type 'FeatureData[Taxonomy]' \
      --input-format HeaderlessTSVTaxonomyFormat \
      --input-path silva_subset/subset_taxonomy.tsv \
      --output-path silva_subset/subset-tax.qza
fi

# Train classifier on subset (much faster and less memory)
echo "Training QIIME2 classifier on subset..."
echo "Using $subset_count sequences (much faster than full database)"
echo "This should complete in 2-5 minutes..."

time qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva_subset/subset-seqs.qza \
  --i-reference-taxonomy silva_subset/subset-tax.qza \
  --o-classifier silva-138-nb-classifier-trained.qza \
  --verbose

if [ ! -f "silva-138-nb-classifier-trained.qza" ]; then
    echo "Error: QIIME2 classifier training failed!"
    echo "Try reducing SUBSET_SIZE further or check available memory"
    exit 1
fi

echo "✓ QIIME2 classifier trained successfully: silva-138-nb-classifier-trained.qza"
echo ""

# Prepare data for NaiveR (use same subset for fair comparison)
echo "Preparing Silva subset data for NaiveR..."
cp silva_subset/subset_sequences.fasta silva_sequences.fasta
cp silva_subset/subset_taxonomy.tsv silva_taxonomy.tsv

# Clean up temporary files
rm -rf silva_subset/

echo ""
echo "Training completed successfully!"
echo ""
echo "Files created:"
echo "- Silva sequences: silva_sequences.fasta ($subset_count sequences)"
echo "- Silva taxonomy: silva_taxonomy.tsv"
echo "- QIIME2 classifier: silva-138-nb-classifier-trained.qza"
echo ""
echo "Next steps:"
echo "1. Train NaiveR classifier in R:"
echo "   devtools::load_all('../')"
echo "   source('train_naiver_classifier.R')"
echo "   classifier <- train_naiver_classifier()"
echo ""
echo "2. Run benchmark comparison:"
echo "   source('run_benchmark.R')"
echo "   results <- run_complete_benchmark()"
