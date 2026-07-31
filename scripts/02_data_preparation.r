# ==============================================================================
# 02_DATA PREPARATION — Variable Construction
# ==============================================================================
# Constructs all analytic variables from merged_data.rds and saves:
#   analysis_data.rds       — canonical full sample (urban + rural)
#   analysis_data_rural.rds — rural subset (urban_resident == 0)
#   analysis_data_urban.rds — urban subset (urban_resident == 1)
#
# Key changes from previous version:
#   • No premature rural filter — urban_resident is always populated
#   •  is included in the select() output
#   • Two-phase education mapping uses utils_functions.r helper
# ==============================================================================

print_section("VARIABLE CONSTRUCTION")

# Load helper functions (must be sourced before this script runs)
source("scripts/utils_functions.r")

# Load full merged data
merged_data <- readRDS("output/merged_data.rds")
cat("Merged data loaded:", nrow(merged_data), "rows\n")

# ------------------------------------------------------------------------------
# CORE VARIABLE CONSTRUCTION
# ------------------------------------------------------------------------------
analysis_data <- merged_data %>%
  mutate(

    # ── EMPLOYMENT OUTCOMES ─────────────────────────────────────────────────
    # WKANY5 captures work participation across 5 categories.
    # Categories 2–4 map to "employed"; 0 = none, 1 = missing hours = not employed.
    employed = case_when(
      WKANY5 %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ 1,
      WKANY5 %in% c("(0) none 0", "(1) missing hours 1")              ~ 0,
      TRUE ~ NA_real_
    ),

    # Employment type hierarchy: salaried > business > farm > wage labour
    # Priority is given to higher-quality employment if multiple are reported.
    employment_type = case_when(
      convert_work_var(WKSALARY)  == 1 ~ "Salaried",
      convert_work_var(WKBUSINESS) == 1 ~ "Business",
      convert_work_var(WKFARM)    == 1 ~ "Farm",
      convert_work_var(WKAGLAB)   == 1 |
        convert_work_var(WKNONAG) == 1 ~ "Wage_Labor",
      employed == 0 ~ "Not_Working",
      TRUE ~ "Other"
    ) %>% factor(levels = c(
      "Not_Working", "Salaried", "Business", "Farm", "Wage_Labor", "Other"
    )),

    # ── SOCIAL CAPITAL ──────────────────────────────────────────────────────
    # org_membership: any participation in formal/informal organisation (ME1)
    org_membership = as.numeric(ME1 == "(1) Yes 1"),

    # : "most people can be trusted" (TR1)
    # This is the second social capital dimension that was previously dropped.
    

    # ── DEMOGRAPHICS ────────────────────────────────────────────────────────
    female = as.numeric(RO3 == "(2) Female 2"),
    age    = as.numeric(as.character(RO5)),
    age_sq = age^2,

    # ── HUMAN CAPITAL ────────────────────────────────────────────────────────
    education_years = extract_education_years(ED6),
    education_cat = case_when(
      education_years == 0  ~ "No_education",
      education_years <= 5  ~ "Primary",
      education_years <= 10 ~ "Secondary",
      education_years > 10  ~ "Higher",
      TRUE ~ "Unknown"
    ) %>% factor(levels = c("No_education", "Primary", "Secondary", "Higher", "Unknown")),

    # ── SOCIAL GROUP ────────────────────────────────────────────────────────
    # Reference group: Brahmins (level 1). All group effects are relative to Brahmins.
    social_group = factor(
      GROUPS_ind,
      levels = c(
        "(1) Brahmin 1", "(2) Forward caste 2", "(3) OBC 3",
        "(4) Dalit 4",   "(5) Adivasi 5",        "(6) Muslim 6",
        "(7) Christian, Sikh, Jain 7"
      ),
      labels = c(
        "Brahmins", "Forward_castes", "OBCs", "Dalits",
        "Adivasis", "Muslims", "Other_Religions"
      )
    ),

    # ── ECONOMIC CONTROLS ───────────────────────────────────────────────────
    wealth_index   = as.numeric(as.character(ASSETS_hh)),
    consumption    = as.numeric(as.character(COTOTAL_hh)),
    ln_consumption = log(consumption + 1),

    # ── GEOGRAPHY ───────────────────────────────────────────────────────────
    # urban_resident already constructed in 01_data_loading.r and preserved
    # in merged_data. Re-derive here to be safe.
    urban_resident = as.numeric(URBAN2011_ind == "(1) urban 1"),

    # Broad region for visualisations (North/South/East/West/Central/Northeast)
    # Based on state ID groupings standard in Indian survey literature
    region = case_when(
      STATEID_ind %in% c("(02) Himachal Pradesh 2", "(03) Punjab 3",
                          "(06) Haryana 6", "(07) Delhi 7",
                          "(08) Rajasthan 8", "(09) Uttar Pradesh 9",
                          "(55) Uttarakhand 55") ~ "North",
      STATEID_ind %in% c("(14) Gujarat 14", "(27) Maharashtra 27",
                          "(30) Goa 30") ~ "West",
      STATEID_ind %in% c("(19) West Bengal 19", "(20) Jharkhand 20",
                          "(21) Odisha 21", "(10) Bihar 10") ~ "East",
      STATEID_ind %in% c("(28) Andhra Pradesh 28", "(29) Karnataka 29",
                          "(32) Kerala 32", "(33) Tamil Nadu 33") ~ "South",
      STATEID_ind %in% c("(22) Chhattisgarh 22", "(23) Madhya Pradesh 23") ~ "Central",
      TRUE ~ "Other/NE"
    )

  ) %>%
  dplyr::select(
    # IDs
    IDHH, PERSONID, STATEID_ind, DISTID_ind, DISTRICT_ind, PSUID_ind,
    # Outcome
    employed, employment_type,
    # Raw work variables (needed by script 12)
    WKSALARY, WKBUSINESS, WKFARM, WKAGLAB, WKNONAG,
    # Social capital (BOTH dimensions now included)
    org_membership,
    # Human capital
    education_years, education_cat,
    # Identity
    social_group,
    # Demographics
    female, age, age_sq,
    # Economic
    wealth_index, consumption, ln_consumption,
    # Geography
    urban_resident, region,
    # Survey weights (critical for svyglm)
    WT_ind, FWT_ind
  )

cat("Final dataset dimensions:", dim(analysis_data), "\n")
cat("Rows:", nrow(analysis_data), " | Columns:", ncol(analysis_data), "\n\n")

# ------------------------------------------------------------------------------
# MISSING VALUE REPORT
# ------------------------------------------------------------------------------
key_vars <- c("employed", "org_membership",  "education_years",
              "social_group", "female", "age", "wealth_index", "urban_resident")
missing_summary <- sapply(analysis_data[key_vars], function(x) sum(is.na(x)))
missing_df <- data.frame(
  Variable = names(missing_summary),
  Missing  = missing_summary,
  Percent  = round(100 * missing_summary / nrow(analysis_data), 2)
)
cat("Missing values in key variables:\n")
print(missing_df)
write.csv(missing_df, "output/tables/missing_data_summary.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# SAVE CANONICAL AND CONVENIENCE SUBSETS
# ------------------------------------------------------------------------------

# 1. Full canonical dataset — used by all main analysis scripts
saveRDS(analysis_data, "output/analysis_data.rds")
cat("\n✓ Saved: output/analysis_data.rds (full sample, N =", nrow(analysis_data), ")\n")

# 2. Rural subset — for analyses where rural focus is appropriate (e.g., NREGA)
analysis_data_rural <- analysis_data %>% filter(urban_resident == 0)
saveRDS(analysis_data_rural, "output/analysis_data_rural.rds")
cat("✓ Saved: output/analysis_data_rural.rds (rural only, N =", nrow(analysis_data_rural), ")\n")

# 3. Urban subset — for within-state comparisons
analysis_data_urban <- analysis_data %>% filter(urban_resident == 1)
saveRDS(analysis_data_urban, "output/analysis_data_urban.rds")
cat("✓ Saved: output/analysis_data_urban.rds (urban only, N =", nrow(analysis_data_urban), ")\n")

cat("\n✓ Variable construction complete\n")
