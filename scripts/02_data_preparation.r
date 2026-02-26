# ==============================================================================
# VARIABLE CONSTRUCTION
# ==============================================================================

print_section("VARIABLE CONSTRUCTION")

# Load merged data
merged_data <- readRDS("output/merged_data.rds")

analysis_data <- merged_data %>%
  mutate(
    # Employment outcomes
    employed = case_when(
      WKANY5 %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ 1,
      WKANY5 %in% c("(0) none 0", "(1) missing hours 1") ~ 0,
      TRUE ~ NA_real_
    ),
    employment_type = case_when(
      convert_work_var(WKSALARY) == 1 ~ "Salaried",
      convert_work_var(WKBUSINESS) == 1 ~ "Business",
      convert_work_var(WKFARM) == 1 ~ "Farm",
      convert_work_var(WKAGLAB) == 1 | convert_work_var(WKNONAG) == 1 ~ "Wage_Labor",
      employed == 0 ~ "Not_Working",
      TRUE ~ "Other"
    ) %>% factor(levels = c(
      "Not_Working", "Salaried", "Business",
      "Farm", "Wage_Labor", "Other"
    )),

    # Social capital
    org_membership = as.numeric(ME1 == "(1) Yes 1"),
    general_trust = as.numeric(TR1 == "(1) Most people can be trusted 1"),

    # Demographics & cultural capital
    female = as.numeric(RO3 == "(2) Female 2"),
    age = as.numeric(as.character(RO5)),
    age_sq = age^2,
    education_years = extract_education_years(ED6),
    education_cat = case_when(
      education_years == 0 ~ "No_education",
      education_years <= 5 ~ "Primary",
      education_years <= 10 ~ "Secondary",
      education_years > 10 ~ "Higher",
      TRUE ~ "Unknown"
    ) %>% factor(levels = c(
      "No_education", "Primary", "Secondary",
      "Higher", "Unknown"
    )),
    social_group = factor(
      GROUPS_ind,
      levels = c(
        "(1) Brahmin 1", "(2) Forward caste 2", "(3) OBC 3",
        "(4) Dalit 4", "(5) Adivasi 5", "(6) Muslim 6",
        "(7) Christian, Sikh, Jain 7"
      ),
      labels = c(
        "Brahmins", "Forward_castes", "OBCs", "Dalits",
        "Adivasis", "Muslims", "Other_Religions"
      )
    ),

    # Economic controls
    wealth_index = as.numeric(as.character(ASSETS_hh)),
    consumption = as.numeric(as.character(COTOTAL_hh)),
    ln_consumption = log(consumption + 1),

    # FIX: Remove urban_resident variable when analyzing rural only
    urban_resident = if (rural_only) NA_real_ else as.numeric(URBAN2011_ind == "(1) Urban 1")
  ) %>%
  dplyr::select(
    IDHH, PERSONID, STATEID_ind, DISTID_ind, DISTRICT_ind, PSUID_ind,
    employed, employment_type, WKSALARY, WKBUSINESS, WKFARM,
    WKAGLAB, WKNONAG, org_membership, general_trust,
    education_years, education_cat, social_group,
    female, age, age_sq, wealth_index, consumption,
    ln_consumption, urban_resident, WT_ind, FWT_ind
  )

cat("Final dataset dimensions:", dim(analysis_data), "\n\n")

# Save analysis data
saveRDS(analysis_data, "output/analysis_data.rds")
cat("✓ Variable construction complete - analysis data saved\n")
