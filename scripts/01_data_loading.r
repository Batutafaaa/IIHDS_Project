# ==============================================================================
# 01_DATA LOADING & MERGING
# ==============================================================================
# Loads raw IHDS-II rda files, merges individual and household datasets on IDHH,
# and saves a single full-sample merged_data.rds.
# NO urban/rural filter is applied here — that is handled downstream by
# the `urban_resident` variable.

print_section("DATA LOADING")

# Load raw data files
load("data/36151-0001-Data.rda")
load("data/36151-0002-Data.rda")

individual <- da36151.0001
household  <- da36151.0002

cat("Individual records:", nrow(individual), "\n")
cat("Household records:", nrow(household), "\n")

# Merge on household ID
merged_data <- individual %>%
  left_join(household, by = "IDHH", suffix = c("_ind", "_hh"))

cat("Merged records:", nrow(merged_data), "\n")

unmatched <- nrow(anti_join(individual, household, by = "IDHH"))
cat("Unmatched individuals (no HH record):", unmatched, "\n")

# Derive urban/rural flag immediately so it is always available
# This allows any downstream script to filter as needed without sourcing back here
merged_data <- merged_data %>%
  mutate(
    urban_resident = as.numeric(URBAN2011_ind == "(1) urban 1")
  )

urban_n  <- sum(merged_data$urban_resident == 1, na.rm = TRUE)
rural_n  <- sum(merged_data$urban_resident == 0, na.rm = TRUE)
cat("\nUrban individuals:", urban_n, "\n")
cat("Rural individuals:", rural_n, "\n")
cat("Urban share: ", round(100 * urban_n / nrow(merged_data), 1), "%\n", sep = "")

# Save full merged dataset
saveRDS(merged_data, "output/merged_data.rds")
cat("\n✓ Data loading complete — full merged data saved (no urban/rural filter applied)\n")
