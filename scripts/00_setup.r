# ==============================================================================
# SETUP & CONFIGURATION
# ==============================================================================

# Define print_section FIRST before using it
print_section <- function(title) {
  cat("\n", rep("=", 80), "\n", title, "\n", rep("=", 80), "\n", sep = "")
}

print_section("PROJECT SETUP")

# Load packages 
required_packages <- c(
  "haven",      # Read Stata/SPSS data
  "dplyr",      # Data manipulation
  "tidyverse",  # Data wrangling ecosystem
  "survey",     # Survey data analysis
  "car",        # Regression diagnostics
  "ggplot2",    # Visualization
  "scales",     # Axis formatting
  "broom"       # Model tidying
)

# Install and load packages
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Try loading margins package with error handling
if (!require(margins, quietly = TRUE)) {
  cat("Installing margins package...\n")
  install.packages("margins")
  library(margins)
}

# Set working directory
setwd("C:/Users/ashwin/Desktop/IIHDS_Project")

# ANALYSIS CONFIGURATION
rural_only <- TRUE  # Set to FALSE for full sample analysis

# Create output directories
output_dirs <- c("analysis_plots", "output/plots", "output/tables", "output/models")
for (dir in output_dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat("Created directory:", dir, "\n")
  }
}

cat("✓ Setup complete - packages loaded and directories created\n")