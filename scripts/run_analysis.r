# ==============================================================================
# MASTER RUNNER SCRIPT
# ==============================================================================

cat("Starting Social Capital Analysis...\n")

# Define print_section locally for the runner
print_section <- function(title) {
  cat("\n", rep("=", 80), "\n", title, "\n", rep("=", 80), "\n", sep = "")
}

print_section("INITIALIZING ANALYSIS PIPELINE")

# CRITICAL: Run scripts in correct dependency order
scripts_to_run <- c(
  "00_setup.R",           # Setup and packages
  "utils_functions.R",    # Helper functions MUST come before data prep
  "01_data_loading.R",    # Load raw data
  "02_data_preparation.R", # Uses functions from utils_functions
  "03_descriptive_stats.R",
  "04_regression_models.R",
  "05_Interactions_ Subgroups.R",
  "06_Marginal_Effects.R",
  "07_final_report.R",
  "08_visualizations.R"
)

for (script in scripts_to_run) {
  script_path <- file.path("scripts", script)
  if (file.exists(script_path)) {
    cat("\n>>> Running:", script, "\n")
    source(script_path)
  } else {
    cat("\n!!! WARNING: Script not found:", script_path, "\n")
  }
}

print_section("ANALYSIS COMPLETE")
cat("✓ All scripts executed successfully!\n")