# ==============================================================================
# MASTER RUNNER SCRIPT
# ==============================================================================
# Executes the entire IIHDS analysis pipeline in the correct dependency order.

cat("Starting Social Capital and Marginalization Analysis...\n")

print_section <- function(title) {
  cat("\n", rep("=", 80), "\n", title, "\n", rep("=", 80), "\n", sep = "")
}

print_section("INITIALIZING ANALYSIS PIPELINE")

scripts_to_run <- c(
  "00_setup.r",                    # Setup, packages, dirs
  "utils_functions.r",             # Helper functions (must load early)
  "01_data_loading.r",             # Merging individual + HH
  "02_data_preparation.r",         # Construct canonical analysis_data.rds
  "03_descriptive_stats.r",        # Basic group stats, wealth paradox
  "04_regression_models.r",        # Survey-weighted baseline logit
  "05_Interactions_ Subgroups.r",  # Group x social capital interactions
  "06_Marginal_Effects.r",         # Full sample AMEs
  "08_visualizations.r",           # Miscellaneous plot rendering
  "09_robustness_checks.r",        # State FE vs District FE (Geographic trap test)
  "10_geographic_analysis.r",      # Muslim geographic concentration
  "11_sc_st_geographic_analysis.r",# SC/ST geographic concentration
  "12_employment_quality.r",       # Heckman wages, NREGA, contract type
  "13_urban_rural_dynamics.r",     # Within-state urban vs rural disparities
  "07_final_report.r"              # Generate final comprehensive summary
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
cat("✓ All scripts executed. Outputs saved to output/ tables and plots.\n")
