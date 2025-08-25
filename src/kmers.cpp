#include <Rcpp.h>
using namespace Rcpp;

/**
 * Compute logarithmic probability matrix for k-mer genus associations
 * 
 * This function calculates log-transformed conditional probabilities for each k-mer
 * given specific genus classifications, incorporating prior probability adjustments
 * for Bayesian inference in taxonomic classification tasks.
 * 
 * @param kmer_genus_count Matrix containing k-mer frequency counts per genus
 * @param word_specific_priors Vector of prior probabilities for individual k-mers
 * @param genus_counts Vector containing total sequence counts for each genus
 * @return Matrix of log-transformed conditional probabilities (k-mers x genera)
 */
// [[Rcpp::export]]
NumericMatrix calculate_log_probability(const NumericMatrix& kmer_genus_count,
                                        const NumericVector& word_specific_priors,
                                        const NumericVector& genus_counts){
  // Extract matrix dimensions for iteration bounds
  int n_kmers = kmer_genus_count.rows();
  int n_genera = kmer_genus_count.cols();
  
  // Initialize output matrix for log probability values
  NumericMatrix log_probs(n_kmers, n_genera);
  
  // Iterate through each genus classification
  for(int j = 0; j < n_genera; j++){
    // Apply Laplace smoothing by adding 1 to genus count
    int genus_count_plus1 = genus_counts[j] + 1;
    
    // Calculate log probability for each k-mer given this genus
    for(int i = 0; i < n_kmers; i++){
      // Apply Bayesian formula: log((count + prior) / (total + 1))
      log_probs(i, j) = log((kmer_genus_count(i, j) + word_specific_priors(i)) / (genus_count_plus1));
    }
  }
  return log_probs;
}
