# NaiveR

NaiveR is an R package for classifying DNA sequences into taxonomic groupings using a Naïve Bayesian Classifier, inspired by the Ribosomal Database Project. It is designed for 16S rRNA gene sequences but can be used for any gene sequence classification.

## Features
- Read and write FASTA files
- Build k-mer databases
- Classify unknown DNA sequences
- Taxonomy filtering and printing utilities
- Fast computation using Rcpp and Rfast

## Installation

Install dependencies in R:
```r
install.packages(c("devtools", "Rcpp", "readr", "Rfast", "stringi", "dplyr", "purrr", "testthat", "knitr", "rmarkdown"))
```

Clone this repository and install the package:
```r
devtools::load_all(".", recompile = TRUE)
# or
# devtools::install()
```

## Usage Example
```r
library(NaiveR)
# Read a FASTA file
fasta <- read_fasta("path/to/your.fasta")
# Build a k-mer database
db <- build_kmer_database(
  trainset9_pds$sequence,
  trainset9_pds$taxonomy
)
# Classify a new sequence
result <- classify_sequence(unknown_seq = "ACGTACGT...", db = db)
print(result)
```

## Example of Database Structure

A typical input data frame for building a k-mer database should have the following columns (example from files in /data):

| id    | sequence                                                                                                                        | taxonomy                                                        |
|-------|----------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| 6564  | Z97069_S000001309                                                                                                               | Bacteria;Actinobacteria;Actinobacteria;Actinomycetales;Corynebacteriaceae |
|       | ctcaggacg...1410 more bp...acca |
```

## Development
See [COMPILING.md](COMPILING.md) for build and development instructions.

## Contributing
Pull requests and issues are welcome!

## License
GPL-3
