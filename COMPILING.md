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
   # Method 1: Standard installation (restart R session first if package is loaded)
   devtools::install()
   
   # Method 2: Force reinstall (if method 1 fails)
   remove.packages("NaiveR")
   devtools::install()
   
   # Method 3: For development, prefer load_all() instead
   devtools::load_all(".", recompile = TRUE)
   ```

6. For C++ changes, always recompile:
   ```r
   devtools::clean_dll()
   devtools::load_all(".", recompile = TRUE)
   ```

7. Do not commit compiled files (see .gitignore).

8. **Troubleshooting**: If installation fails with "cannot remove earlier installation" or "Permission denied":
   - **Best solution**: Restart your R session completely (Ctrl+Shift+F10 in RStudio)
   - Check if multiple R processes are running and close them
   - On Windows, DLL files cannot be overwritten while loaded in memory
   
   **For Windows permission errors ("Access denied" / "Odmowa dostępu"):**
   1. **Run R as Administrator**: Right-click R/RStudio → "Run as administrator"
   2. **Check antivirus**: Temporarily disable real-time protection during installation
   3. **Use different library path**: 
      ```r
      devtools::install(lib = "C:/temp/R-lib")
      .libPaths("C:/temp/R-lib")
      ```
   4. **Alternative for development**: Use `devtools::load_all()` to avoid installation
   5. **Clean installation**: 
      ```r
      unlink("C:/Users/[username]/AppData/Local/R/win-library/4.5/NaiveR", recursive = TRUE)
      devtools::install()
      ```
   
   **For daily development**: Use `devtools::load_all()` to avoid installation issues entirely

9. For more, see the R package development guide: https://r-pkgs.org/
