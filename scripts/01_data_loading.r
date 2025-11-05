# ==============================================================================
# DATA LOADING & MERGING
# ==============================================================================

print_section("DATA LOADING")

# Load data files
load("36151-0001-Data.rda")
load("36151-0002-Data.rda")

individual <- da36151.0001
household <- da36151.0002

# Merge datasets
merged_data <- individual %>%
  left_join(household, by = "IDHH", suffix = c("_ind", "_hh"))

cat("Individual records:", nrow(individual), "\n")
cat("Household records:", nrow(household), "\n")
cat("Merged records:", nrow(merged_data), "\n")
cat("Unmerged individuals:", nrow(anti_join(individual, household, by = "IDHH")), "\n")

# RURAL/URBAN FILTER
if (rural_only) {
  cat("\n>>> FILTERING FOR RURAL AREAS ONLY <<<\n")
  merged_data <- merged_data %>%
    filter(URBAN2011_ind != "(1) Urban 1")
  cat("Rural sample size:", nrow(merged_data), "\n")
  cat("Urban areas excluded for focused rural labor market analysis\n")
}

# Save merged data for other scripts
saveRDS(merged_data, "output/merged_data.rds")
cat("✓ Data loading complete - merged data saved\n")