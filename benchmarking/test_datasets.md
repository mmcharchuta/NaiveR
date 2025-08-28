# Test Dataset Sources for NaiveR Benchmarking

## Recommended Datasets

### 1. Mock Communities (Best for Accuracy Testing)
These are artificial communities with known composition - perfect for measuring accuracy.

#### ZYMO Research Mock Communities
- **Dataset**: ZymoBIOMICS Microbial Community Standard
- **Source**: Available through NCBI SRA
- **SRA Accession**: SRR5936131, SRR5936132 (and others)
- **Contains**: 10 known bacterial species in defined proportions
- **Why good**: True taxonomy is known, widely used benchmark

```bash
# Download ZYMO mock community data
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR593/001/SRR5936131/SRR5936131_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR593/001/SRR5936131/SRR5936131_2.fastq.gz
```

#### HMP Mock Community
- **Dataset**: Human Microbiome Project Mock Community
- **Source**: NCBI BioProject PRJNA48479
- **Contains**: 22 known bacterial strains
- **Reference sequences**: Available with known taxonomy

### 2. Animal Gut Microbiome Studies

#### Mouse Gut Microbiome (Broad taxonomic diversity)
- **Study**: "The gut microbiome of mammals"
- **BioProject**: PRJNA431817
- **Paper**: https://doi.org/10.1126/science.aat5091
- **Samples**: >1000 mammalian gut samples
- **Why good**: Relevant to Silva animal-distal-gut classifier

#### Human Gut Microbiome Project (HMP2)
- **BioProject**: PRJNA398089
- **Source**: NIH Human Microbiome Project
- **Contains**: Longitudinal gut microbiome data
- **Reference taxonomy**: Well-curated

### 3. Pre-processed Test Datasets

#### SILVA Test Suite
- **Source**: SILVA rRNA database
- **URL**: https://www.arb-silva.de/no_cache/download/arb-files/
- **File**: SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz
- **Contains**: Curated 16S sequences with taxonomic assignments
- **Size**: ~100k sequences (can subsample)

#### Greengenes Test Data
- **Source**: Greengenes database
- **Contains**: Representative sequences with known taxonomy
- **Good for**: Cross-database validation

## Quick Start: Using SILVA Test Sequences

### Option 1: Download pre-curated sequences
```bash
# Download SILVA reference sequences
wget https://www.arb-silva.de/fileadmin/silva_databases/release_138_1/Exports/SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz

# Extract and subsample for testing
gunzip SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz

# Create test subset (1000 random sequences)
seqtk sample SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta 1000 > test_sequences.fasta
```

### Option 2: Use R to create test dataset
```r
# Download and prepare test dataset in R
library(NaiveR)

# If you have internet access from R
download.file(
  "https://www.arb-silva.de/fileadmin/silva_databases/release_138_1/Exports/SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz",
  "silva_sequences.fasta.gz"
)

# Read full dataset
silva_data <- read_fasta("silva_sequences.fasta")

# Create test subset
set.seed(123)  # For reproducibility
test_indices <- sample(nrow(silva_data), 500)
test_data <- silva_data[test_indices, ]

# Save test dataset
write_fasta(test_data, "test_sequences.fasta")

# Extract true taxonomy for accuracy testing
true_taxonomy <- data.frame(
  sequence_id = test_data$id,
  true_taxonomy = test_data$comment,  # or wherever taxonomy is stored
  stringsAsFactors = FALSE
)

write.csv(true_taxonomy, "true_taxonomy.csv", row.names = FALSE)
```

## Dataset Preparation Guidelines

### Sequence Quality Requirements:
1. **Length**: 250-1500 bp (typical 16S V4 region ~250bp)
2. **Quality**: Remove sequences with ambiguous nucleotides (N's)
3. **Chimeras**: Remove chimeric sequences
4. **Duplicates**: Remove exact duplicates

### Taxonomy Format Standardization:
- Ensure consistent delimiter (semicolon `;`)
- Remove confidence scores if present
- Standardize taxonomic ranks (Kingdom;Phylum;Class;Order;Family;Genus;Species)

## Recommended Test Dataset Sizes:

- **Small test** (quick validation): 100-500 sequences
- **Medium test** (standard benchmark): 1,000-5,000 sequences  
- **Large test** (comprehensive): 10,000+ sequences

## Example: Preparing ZYMO Mock Community

```r
# Function to prepare ZYMO mock community data
prepare_zymo_test <- function() {
  
  # Known ZYMO species composition
  zymo_species <- c(
    "Bacillus_subtilis",
    "Enterococcus_faecalis", 
    "Escherichia_coli",
    "Lactobacillus_fermentum",
    "Listeria_monocytogenes",
    "Pseudomonas_aeruginosa",
    "Salmonella_enterica",
    "Staphylococcus_aureus"
  )
  
  # Create expected taxonomy strings
  expected_taxonomy <- data.frame(
    species = zymo_species,
    taxonomy = c(
      "Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_subtilis",
      "Bacteria;Firmicutes;Bacilli;Lactobacillales;Enterococcaceae;Enterococcus;Enterococcus_faecalis",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Escherichia;Escherichia_coli",
      "Bacteria;Firmicutes;Bacilli;Lactobacillales;Lactobacillaceae;Lactobacillus;Lactobacillus_fermentum",
      "Bacteria;Firmicutes;Bacilli;Bacillales;Listeriaceae;Listeria;Listeria_monocytogenes",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Pseudomonadales;Pseudomonadaceae;Pseudomonas;Pseudomonas_aeruginosa",
      "Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacteriales;Enterobacteriaceae;Salmonella;Salmonella_enterica",
      "Bacteria;Firmicutes;Bacilli;Bacillales;Staphylococcaceae;Staphylococcus;Staphylococcus_aureus"
    ),
    stringsAsFactors = FALSE
  )
  
  return(expected_taxonomy)
}
```

## Next Steps:
1. Choose a dataset based on your needs
2. Download and prepare the sequences
3. Run the benchmark using `benchmark_analysis.R`
4. Compare results between NaiveR and QIIME2

**Recommendation**: Start with the SILVA subset (Option 2 above) as it's easiest to obtain and has well-curated taxonomy.
