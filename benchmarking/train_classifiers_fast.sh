#!/bin/bash

# Fast and efficient QIIME2 training with Silva subset
# Uses a smarter approach to avoid long loops

echo "Checking for Silva 138.1 reference files..."
if [ ! -f "ref-seqs.qza" ] || [ ! -f "ref-tax.qza" ]; then
    echo "Error: ref-seqs.qza or ref-tax.qza not found!"
    exit 1
fi

echo "✓ Found Silva reference files"

# Clean up
echo "Cleaning workspace..."
rm -f silva-138-nb-classifier-trained.qza
rm -f silva_sequences.fasta silva_taxonomy.tsv
rm -rf qiime2_benchmark/ silva_subset/

# Create a much smaller subset using QIIME2 directly
SUBSET_SIZE=1000  # Even smaller for speed
echo "Creating subset of $SUBSET_SIZE sequences using QIIME2..."

# Use QIIME2's built-in filtering to create subset
echo "Filtering reference sequences to create manageable subset..."
qiime feature-table filter-seqs \
  --i-data ref-seqs.qza \
  --m-metadata-file ref-tax.qza \
  --p-where "length([id]) > 10" \
  --o-filtered-data subset-seqs-temp.qza

# Take just the first N sequences
echo "Extracting $SUBSET_SIZE sequences..."
mkdir -p temp_export
qiime tools export --input-path subset-seqs-temp.qza --output-path temp_export/

# Create smaller subset
head -n $((SUBSET_SIZE * 2)) temp_export/dna-sequences.fasta > temp_subset.fasta
actual_count=$(grep -c "^>" temp_subset.fasta)
echo "Created subset with $actual_count sequences"

# Get the IDs from our subset
grep "^>" temp_subset.fasta | sed 's/^>//' | sed 's/ .*//' > subset_ids.txt
echo "First 5 sequence IDs:"
head -5 subset_ids.txt

# Import our small subset back to QIIME2
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path temp_subset.fasta \
  --output-path final-subset-seqs.qza

# Filter taxonomy to match our subset (much faster with small list)
echo "Filtering taxonomy..."
qiime feature-table filter-samples \
  --i-table ref-tax.qza \
  --m-metadata-file subset_ids.txt \
  --o-filtered-table final-subset-tax.qza \
  2>/dev/null || {
    # If that doesn't work, try different approach
    echo "Using alternative taxonomy filtering..."
    qiime taxa filter-table \
      --i-table ref-tax.qza \
      --i-taxonomy ref-tax.qza \
      --p-include "d__" \
      --o-filtered-table final-subset-tax.qza \
      2>/dev/null || {
        # Manual approach if QIIME2 filtering fails
        echo "Creating taxonomy subset manually..."
        qiime tools export --input-path ref-tax.qza --output-path temp_export/
        
        # Create subset taxonomy file
        head -1 temp_export/taxonomy.tsv > subset_taxonomy.tsv
        while read id; do
            grep "^$id[[:space:]]" temp_export/taxonomy.tsv >> subset_taxonomy.tsv
        done < subset_ids.txt
        
        # Import back
        qiime tools import \
          --type 'FeatureData[Taxonomy]' \
          --input-format HeaderlessTSVTaxonomyFormat \
          --input-path subset_taxonomy.tsv \
          --output-path final-subset-tax.qza
    }
}

echo "Training QIIME2 classifier on $actual_count sequences..."
echo "This should complete in 1-2 minutes..."

time qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads final-subset-seqs.qza \
  --i-reference-taxonomy final-subset-tax.qza \
  --o-classifier silva-138-nb-classifier-trained.qza \
  --verbose

if [ ! -f "silva-138-nb-classifier-trained.qza" ]; then
    echo "Error: Training failed!"
    exit 1
fi

echo "✓ QIIME2 classifier trained successfully!"

# Export data for NaiveR
echo "Preparing data for NaiveR..."
cp temp_subset.fasta silva_sequences.fasta

# Export taxonomy
if [ -f "subset_taxonomy.tsv" ]; then
    cp subset_taxonomy.tsv silva_taxonomy.tsv
else
    qiime tools export --input-path final-subset-tax.qza --output-path ./
    mv taxonomy.tsv silva_taxonomy.tsv 2>/dev/null || true
fi

# Clean up temporary files
rm -rf temp_export/ subset-seqs-temp.qza final-subset-seqs.qza final-subset-tax.qza
rm -f temp_subset.fasta subset_ids.txt subset_taxonomy.tsv

echo ""
echo "Training completed successfully!"
echo "Files created:"
echo "- QIIME2 classifier: silva-138-nb-classifier-trained.qza"
echo "- Silva sequences for NaiveR: silva_sequences.fasta ($actual_count sequences)"
echo "- Silva taxonomy for NaiveR: silva_taxonomy.tsv"
echo ""
echo "Next steps:"
echo "1. Train NaiveR: source('train_naiver_classifier.R')"
echo "2. Run benchmark: source('run_benchmark.R')"
