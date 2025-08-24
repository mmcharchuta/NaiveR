#' Build k-mer database for NaiveR
#'
#' @param seqs Vector of reference sequences.
#' @param genus_labels Vector of genus-level taxonomy for each sequence.
#' @param klen Integer, k-mer size (default 8).
#' @return List with conditional probabilities and genus names.
#' @export
build_kmer_database <- function(seqs, genus_labels, klen = 8) {
  genus_idx <- genus_to_index(genus_labels)
  found_kmers <- find_kmers_across_seqs(seqs, klen)
  priors <- calc_word_priors(found_kmers, klen)
  cond_probs <- calc_conditional_probs(found_kmers, genus_idx, priors)
  genus_names <- unique_genera(genus_labels)
  list(conditional_prob = cond_probs, genera = genus_names)
}

#' Classify a sequence using NaiveR
#'
#' @param unknown_seq DNA sequence to classify.
#' @param db K-mer database from build_kmer_database.
#' @param klen Integer, k-mer size (default 8).
#' @param n_boot Integer, number of bootstraps (default 100).
#' @return List with taxonomy and confidence.
#' @export
classify_sequence <- function(unknown_seq, db, klen = 8, n_boot = 100) {
  kmers <- find_kmers(unknown_seq, klen)
  bs_class <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    bs_kmers <- bootstrap_kmers(kmers, klen)
    bs_class[[i]] <- classify_bs(bs_kmers, db$conditional_prob)
  }
  consensus_bs_class(bs_class, db$genera)
}

#' @noRd
find_kmers <- function(seq, klen = 8) {
  seq_to_base4(seq) |>
    get_kmers(klen) |>
    base4_to_idx() |>
    unique()
}

#' @noRd
find_kmers_across_seqs <- function(seqs, klen = 8) {
  lapply(seqs, find_kmers, klen = klen)
}

#' @noRd
get_kmers <- function(x, klen = 8) {
  n <- stringi::stri_length(x)
  n_kmers <- n - klen + 1
  stringi::stri_sub(x, 1:n_kmers, klen:n)
}

#' @noRd
seq_to_base4 <- function(seq) {
  stringi::stri_trans_toupper(seq) |>
    stringi::stri_replace_all_charclass(str = _, pattern = "[^ACGT]", replacement = "N") |>
    stringi::stri_trans_char(str = _, pattern = "ACGT", replacement = "0123")
}

#' @noRd
base4_to_idx <- function(base4_str) {
  stats::na.omit(strtoi(base4_str, base = 4) + 1) |> as.numeric()
}

#' @noRd
calc_word_priors <- function(kmer_list, klen) {
  priors <- unlist(kmer_list) |> tabulate(bin = _, nbins = 4^klen)
  (priors + 0.5) / (length(kmer_list) + 1)
}

#' @noRd
genus_to_index <- function(genus) {
  factor(genus) |> as.numeric()
}

#' @noRd
unique_genera <- function(genus) {
  factor(genus) |> levels()
}

#' @noRd
bootstrap_kmers <- function(kmers, klen = 8) {
  n <- as.integer(length(kmers) / klen)
  sample(kmers, n, replace = TRUE)
}

#' @noRd
#' @importFrom Rfast rowsums
classify_bs <- function(unknown_kmers, cond_probs) {
  probs <- Rfast::rowsums(cond_probs[, unknown_kmers])
  which.max(probs)
}

#' @noRd
consensus_bs_class <- function(bs_class, genera) {
  taxonomy <- genera[bs_class]
  taxonomy_split <- stringi::stri_split_fixed(taxonomy, pattern = ";")
  n_levels <- length(taxonomy_split[[1]])
  consensus_list <- lapply(seq_len(n_levels), function(i) {
    sapply(taxonomy_split, function(p) paste(p[1:i], collapse = ";")) |> get_consensus()
  })
  list(
    taxonomy = stringi::stri_split_fixed(consensus_list[[n_levels]][["id"]], pattern = ";") |> unlist(),
    confidence = sapply(consensus_list, `[[`, "frac")
  )
}

#' @noRd
get_consensus <- function(taxonomy) {
  n_bs <- length(taxonomy)
  taxonomy_table <- table(taxonomy)
  max_idx <- which.max(taxonomy_table)
  list(
    frac = 100 * taxonomy_table[[max_idx]] / n_bs,
    id = names(max_idx)
  )
}

#' @noRd
calc_conditional_probs <- function(kmer_list, genus_idx, word_priors) {
  genus_counts <- tabulate(genus_idx)
  n_genera <- length(genus_counts)
  n_kmers <- length(word_priors)
  kmer_genus_count <- matrix(0, nrow = n_kmers, ncol = n_genera)
  for (i in seq_along(genus_idx)) {
    kmer_genus_count[kmer_list[[i]], genus_idx[i]] <-
      kmer_genus_count[kmer_list[[i]], genus_idx[i]] + 1
  }
  calculate_log_probability(kmer_genus_count, word_priors, genus_counts) |> t()
}
