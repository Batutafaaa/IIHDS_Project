# ==============================================================================
# 00_SETUP & CONFIGURATION
# ==============================================================================
# NOTE: The rural_only flag has been removed. The pipeline now works on the
# full (urban + rural) sample. Urban/rural is controlled via the `urban_resident`
# variable at the analysis stage, not at data loading.

# Define print_section FIRST before using it
print_section <- function(title) {
  cat("\n", rep("=", 80), "\n", title, "\n", rep("=", 80), "\n", sep = "")
}

print_section("PROJECT SETUP")

# Load packages
required_packages <- c(
  "haven",         # Read Stata/SPSS data
  "dplyr",         # Data manipulation
  "tidyverse",     # Data wrangling ecosystem
  "survey",        # Survey-weighted analysis (svydesign, svyglm)
  "car",           # Regression diagnostics
  "ggplot2",       # Visualization
  "scales",        # Axis formatting
  "broom",         # Model tidying
  "sandwich",      # Robust/clustered standard errors
  "lmtest",        # Hypothesis tests on regression models
  "sampleSelection" # Heckman selection correction
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

# Set working directory
setwd("C:/Users/ashwin/Desktop/IIHDS_Project")

# Create output directories
output_dirs <- c("analysis_plots", "output/plots", "output/tables", "output/models")
for (dir in output_dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat("Created directory:", dir, "\n")
  }
}

cat("✓ Setup complete — packages loaded and directories created\n")
