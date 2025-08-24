# Instructions for compiling and developing the NaiveR package

1. Install dependencies in R:
   ```r
   install.packages(c("devtools", "Rcpp", "readr", "Rfast", "stringi", "dplyr", "purrr", "testthat", "knitr", "rmarkdown"))
   ```

2. Build and load the package in R:
   ```r
   devtools::load_all(".", recompile = TRUE)
   ```

3. To run tests:
   ```r
   devtools::test()
   ```

4. To build the package tarball:
   ```r
   devtools::build()
   ```

5. To install the package from source:
   ```r
   devtools::install()
   ```

6. For C++ changes, always recompile:
   ```r
   devtools::clean_dll()
   devtools::load_all(".", recompile = TRUE)
   ```

7. Do not commit compiled files (see .gitignore).

8. For more, see the R package development guide: https://r-pkgs.org/
