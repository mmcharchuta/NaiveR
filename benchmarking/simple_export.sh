#!/bin/bash

# Simple manual approach - just export Silva data and create subset
# This avoids all the QIIME2 filtering complexity

echo "=== Simple Silva Export and Subset Creation ==="
echo ""

# Check files
if [ ! -f "ref-seqs.qza" ] || [ ! -f "ref-tax.qza" ]; then
    echo "Error: Silva reference files not found!"
    exit 1
fi

echo "✓ Found Silva reference files"

# Clean up
echo "Cleaning workspace..."
rm -f silva-138-nb-classifier-trained.qza
rm -f silva_sequences.fasta silva_taxonomy.tsv
rm -rf qiime2_benchmark/ simple_export/

# Export Silva data directly
echo "Exporting Silva reference data..."
mkdir -p simple_export

qiime tools export \
  --input-path ref-seqs.qza \
  --output-path simple_export/

qiime tools export \
  --input-path ref-tax.qza \
  --output-path simple_export/

# Check what we got
echo "Checking exported files..."
if [ -f "simple_export/dna-sequences.fasta" ]; then
    total_seqs=$(grep -c "^>" simple_export/dna-sequences.fasta)
    echo "✓ Exported $total_seqs sequences"
else
    echo "Error: Failed to export sequences"
    exit 1
fi

if [ -f "simple_export/taxonomy.tsv" ]; then
    total_tax=$(tail -n +2 simple_export/taxonomy.tsv | wc -l)
    echo "✓ Exported $total_tax taxonomy entries"
else
    echo "Error: Failed to export taxonomy"
    exit 1
fi

# Create manageable subset manually
SUBSET_SIZE=2000
echo ""
echo "Creating subset of $SUBSET_SIZE sequences..."

# Take first N sequences (simple and fast)
head -n $((SUBSET_SIZE * 2)) simple_export/dna-sequences.fasta > silva_sequences.fasta
actual_count=$(grep -c "^>" silva_sequences.fasta)
echo "✓ Created subset with $actual_count sequences"

# Get IDs from subset
echo "Extracting sequence IDs..."
grep "^>" silva_sequences.fasta | sed 's/^>//' | sed 's/ .*//' > subset_ids.txt
echo "✓ Extracted $(wc -l < subset_ids.txt) sequence IDs"

# Create matching taxonomy subset
echo "Creating matching taxonomy subset..."
head -1 simple_export/taxonomy.tsv > silva_taxonomy.tsv

# Use awk for faster matching (much faster than while loop)
awk 'FNR==NR{ids[$1]=1; next} ($1 in ids)' subset_ids.txt simple_export/taxonomy.tsv >> silva_taxonomy.tsv

subset_tax_count=$(tail -n +2 silva_taxonomy.tsv | wc -l)
echo "✓ Created taxonomy subset with $subset_tax_count entries"

if [ "$subset_tax_count" -eq 0 ]; then
    echo "Warning: No taxonomy matches found!"
    echo "This might be due to ID format differences"
    echo "Proceeding anyway - NaiveR can handle this"
fi

# Now import subset back to QIIME2 for training
echo ""
echo "Training QIIME2 classifier..."
echo "Converting subset to QIIME2 format..."

qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path silva_sequences.fasta \
  --output-path subset-seqs.qza

if [ "$subset_tax_count" -gt 0 ]; then
    qiime tools import \
      --type 'FeatureData[Taxonomy]' \
      --input-format HeaderlessTSVTaxonomyFormat \
      --input-path silva_taxonomy.tsv \
      --output-path subset-tax.qza
    
    echo "Training classifier with $actual_count sequences and $subset_tax_count taxonomy entries..."
    time qiime feature-classifier fit-classifier-naive-bayes \
      --i-reference-reads subset-seqs.qza \
      --i-reference-taxonomy subset-tax.qza \
      --o-classifier silva-138-nb-classifier-trained.qza \
      --verbose
else
    echo "Skipping QIIME2 training due to taxonomy matching issues"
    echo "You can still train NaiveR classifier"
fi

# Clean up intermediate files
rm -rf simple_export/ subset_ids.txt subset-seqs.qza subset-tax.qza

echo ""
if [ -f "silva-138-nb-classifier-trained.qza" ]; then
    echo "✓ QIIME2 classifier training completed successfully!"
else
    echo "⚠ QIIME2 training failed, but Silva data is ready for NaiveR"
fi

echo ""
echo "Files created:"
echo "- Silva sequences: silva_sequences.fasta ($actual_count sequences)"
echo "- Silva taxonomy: silva_taxonomy.tsv ($subset_tax_count entries)"
if [ -f "silva-138-nb-classifier-trained.qza" ]; then
    echo "- QIIME2 classifier: silva-138-nb-classifier-trained.qza"
fi

echo ""
echo "Next steps:"
echo "1. Train NaiveR classifier:"
echo "   cd /mnt/c/Users/mikcha1/kodzenie/NaiveR"
echo "   R"
echo "   > devtools::load_all()"
echo "   > setwd('benchmarking')"
echo "   > source('train_naiver_classifier.R')"
echo "   > classifier <- train_naiver_classifier()"
echo ""
echo "2. Test NaiveR classification:"
echo "   > source('../R/kmers.R')"
echo "   > test_seqs <- read_fasta('test_sequences_clean.fasta')"
echo "   > result <- classify_sequence(test_seqs[1], classifier\$kmer_database)"
echo "   > print(result)"
