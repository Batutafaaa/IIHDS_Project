# ==============================================================================
# 13_WITHIN-STATE URBAN-RURAL DYNAMICS
# ==============================================================================
# Addresses the research question: How does the urban-rural divide within states
# shape employment disparity differently across social groups?
#
# Three analyses:
#
#   ANALYSIS 1 — Descriptive cross-tab
#     Employment rate and earnings by social_group × urban_rural × region.
#     Shows whether Dalit disadvantage in rural Rajasthan differs from Dalit
#     disadvantage in urban Rajasthan, etc.
#
#   ANALYSIS 2 — Interaction regression: employment probability
#     Adds social_group × urban_resident interaction to the main logit model.
#     Coefficient on (e.g.) social_groupDalits:urban_resident tells us whether
#     the Dalit employment penalty is significantly larger in urban or rural areas.
#
#   ANALYSIS 3 — Interaction regression: log wages
#     Same interaction in the wage regression — does the earnings penalty differ
#     across the urban-rural divide for each group?
#
# Data: analysis_data.rds (full sample — this script requires both urban + rural)
# ==============================================================================

print_section("WITHIN-STATE URBAN-RURAL DYNAMICS")

source("scripts/00_setup.r")
source("scripts/utils_functions.r")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Data loaded:", nrow(analysis_data), "observations\n")
cat("Urban:", sum(analysis_data$urban_resident == 1, na.rm = TRUE),
    "| Rural:", sum(analysis_data$urban_resident == 0, na.rm = TRUE), "\n\n")

# ── ANALYSIS 1: DESCRIPTIVE CROSS-TAB ─────────────────────────────────────────
print_section("ANALYSIS 1: Employment by Group × Urban-Rural × Region")

urban_rural_descriptive <- analysis_data %>%
  filter(!is.na(social_group), !is.na(urban_resident), !is.na(employed)) %>%
  mutate(urban_rural = factor(urban_resident, labels = c("Rural", "Urban"))) %>%
  group_by(social_group, urban_rural) %>%
  summarise(
    n                   = n(),
    employment_rate     = mean(employed, na.rm = TRUE) * 100,
    mean_education      = mean(education_years, na.rm = TRUE),
    mean_wealth         = mean(wealth_index, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

cat("\nEmployment rates by social group and urban/rural:\n")
print(urban_rural_descriptive %>%
        select(social_group, urban_rural, n, employment_rate, mean_education, org_membership_rate),
      row.names = FALSE, n = Inf)
write.csv(urban_rural_descriptive,
          "output/tables/urban_rural_group_descriptives.csv", row.names = FALSE)

# Urban-rural gap within each group
urban_rural_gap <- urban_rural_descriptive %>%
  select(social_group, urban_rural, employment_rate) %>%
  pivot_wider(names_from = urban_rural, values_from = employment_rate) %>%
  mutate(
    urban_rural_gap = Urban - Rural,
    direction = case_when(
      urban_rural_gap > 2  ~ "Urban advantage",
      urban_rural_gap < -2 ~ "Rural advantage",
      TRUE ~ "Roughly equal"
    )
  )

cat("\nUrban-rural employment gap by social group (positive = urban advantage):\n")
print(urban_rural_gap, row.names = FALSE)
write.csv(urban_rural_gap, "output/tables/urban_rural_employment_gap.csv", row.names = FALSE)

# Regional breakdown (North/South/East/West/Central)
regional_descriptive <- analysis_data %>%
  filter(!is.na(social_group), !is.na(urban_resident), !is.na(employed),
         !is.na(region), region != "Other/NE") %>%
  mutate(urban_rural = factor(urban_resident, labels = c("Rural", "Urban"))) %>%
  group_by(region, social_group, urban_rural) %>%
  summarise(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  filter(n >= 30) %>%
  mutate(employment_rate = round(employment_rate, 1))

write.csv(regional_descriptive,
          "output/tables/regional_urban_rural_employment.csv", row.names = FALSE)

# ── ANALYSIS 2: INTERACTION REGRESSION — EMPLOYMENT ──────────────────────────
print_section("ANALYSIS 2: Social Group × Urban-Rural Interaction (Employment)")

model_vars_ur <- c("employed", "org_membership",  "education_years",
                   "social_group", "female", "age", "age_sq", "wealth_index",
                   "urban_resident", "STATEID_ind", "PSUID_ind", "WT_ind")

model_data_ur <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars_ur))))

cat("Complete cases:", nrow(model_data_ur), "\n")

svy_design_ur <- svydesign(
  ids     = ~PSUID_ind,
  weights = ~WT_ind,
  data    = model_data_ur
)

cat("Fitting social_group × urban_resident interaction model...\n")

model_ur_interaction <- tryCatch({
  svyglm(
    employed ~ social_group * urban_resident + org_membership  +
      education_years + female + age + age_sq + wealth_index +
      factor(STATEID_ind),
    design = svy_design_ur,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed, using glm:", e$message, "\n")
  glm(
    employed ~ social_group * urban_resident + org_membership  +
      education_years + female + age + age_sq + wealth_index +
      factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data_ur
  )
})

cat("✓ Model fitted\n")

# Extract interaction terms
ur_coefs <- summary(model_ur_interaction)$coefficients
interaction_rows <- grep("social_group.*:urban_resident", rownames(ur_coefs))

if (length(interaction_rows) > 0) {
  ur_interaction_summary <- data.frame(
    term      = rownames(ur_coefs)[interaction_rows],
    estimate  = ur_coefs[interaction_rows, 1],
    std.error = ur_coefs[interaction_rows, 2],
    p.value   = ur_coefs[interaction_rows, ncol(ur_coefs)],
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      group = gsub("social_group(.*):urban_resident", "\\1", term),
      odds_ratio = exp(estimate),
      sig = case_when(
        p.value < 0.001 ~ "***", p.value < 0.01 ~ "**",
        p.value < 0.05  ~ "*",  p.value < 0.1  ~ ".",
        TRUE ~ ""
      ),
      interpretation = case_when(
        estimate > 0 & p.value < 0.05 ~ "Urban INCREASES penalty relative to Brahmins' urban gain",
        estimate < 0 & p.value < 0.05 ~ "Urban REDUCES penalty relative to Brahmins' urban gain",
        TRUE ~ "Not significant"
      )
    )

  cat("\nGroup × Urban Interaction (relative to Brahmins' urban effect):\n")
  cat("Positive coefficient → group gains MORE from urban setting than Brahmins\n")
  cat("Negative coefficient → group gains LESS from urban setting than Brahmins\n\n")
  print(ur_interaction_summary %>%
          select(group, estimate, std.error, p.value, sig, interpretation),
        row.names = FALSE)
  write.csv(ur_interaction_summary,
            "output/tables/urban_rural_group_interaction.csv", row.names = FALSE)
} else {
  cat("No significant interaction terms found.\n")
}

# Also compute group-specific employment rates rural vs urban from this model
# (predicted probabilities holding other vars at mean)
cat("\nComputing predicted employment probabilities: rural vs urban by group...\n")

social_groups <- levels(model_data_ur$social_group)
pred_grid <- expand.grid(
  social_group    = social_groups,
  urban_resident  = c(0, 1),
  org_membership  = mean(model_data_ur$org_membership, na.rm = TRUE),
  education_years = mean(model_data_ur$education_years, na.rm = TRUE),
  female          = 0,  # Male reference
  age             = mean(model_data_ur$age, na.rm = TRUE),
  age_sq          = mean(model_data_ur$age_sq, na.rm = TRUE),
  wealth_index    = mean(model_data_ur$wealth_index, na.rm = TRUE),
  STATEID_ind     = names(sort(table(model_data_ur$STATEID_ind), decreasing = TRUE))[1],
  stringsAsFactors = FALSE
)
pred_grid$social_group <- factor(pred_grid$social_group, levels = levels(model_data_ur$social_group))

pred_probs <- tryCatch(
  predict(model_ur_interaction, newdata = pred_grid, type = "response"),
  error = function(e) {
    cat("Prediction failed:", e$message, "\n")
    return(rep(NA, nrow(pred_grid)))
  }
)

pred_results <- pred_grid %>%
  select(social_group, urban_resident) %>%
  mutate(
    urban_rural    = factor(urban_resident, labels = c("Rural", "Urban")),
    predicted_prob = round(pred_probs * 100, 2)
  ) %>%
  pivot_wider(id_cols = social_group, names_from = urban_rural,
              values_from = predicted_prob) %>%
  mutate(urban_advantage_pp = Urban - Rural)

cat("\nPredicted employment probability (%) — at mean covariate values:\n")
print(pred_results, row.names = FALSE)
write.csv(pred_results, "output/tables/predicted_probs_urban_rural.csv", row.names = FALSE)

saveRDS(model_ur_interaction, "output/models/model_urban_rural_interaction.rds")

# ── ANALYSIS 3: WAGE REGRESSION WITH GROUP × URBAN INTERACTION ────────────────
print_section("ANALYSIS 3: Wage Penalty — Group × Urban-Rural Interaction")

# Load wage data from employment quality (analysis_data has all needed vars)
# We pull wages from the individual file — using WSEARN (salary earnings)
# Construct log_earnings from merged_data if available; else use consumption proxy
wage_data <- tryCatch({
  merged_data <- readRDS("output/merged_data.rds")
  merged_data %>%
    select(IDHH, PERSONID, WSEARN) %>%
    inner_join(analysis_data %>% select(-any_of("WSEARN")),
               by = c("IDHH", "PERSONID")) %>%
    mutate(annual_earnings = suppressWarnings(as.numeric(as.character(WSEARN)))) %>%
    filter(annual_earnings > 0, !is.na(annual_earnings),
           !is.na(education_years), !is.na(social_group)) %>%
    mutate(log_earnings = log(annual_earnings))
}, error = function(e) {
  cat("Could not load WSEARN from merged_data. Skipping wage analysis:", e$message, "\n")
  NULL
})

if (!is.null(wage_data) && nrow(wage_data) > 1000) {
  cat("Wage data available:", nrow(wage_data), "earners\n")

  wage_model_ur <- lm(
    log_earnings ~ social_group * urban_resident + education_years +
      age + female + factor(STATEID_ind),
    data = wage_data
  )

  wage_coefs    <- summary(wage_model_ur)$coefficients
  wage_int_rows <- grep("social_group.*:urban_resident", rownames(wage_coefs))

  if (length(wage_int_rows) > 0) {
    wage_int_summary <- data.frame(
      term      = rownames(wage_coefs)[wage_int_rows],
      estimate  = wage_coefs[wage_int_rows, 1],
      std.error = wage_coefs[wage_int_rows, 2],
      p.value   = wage_coefs[wage_int_rows, 4],
      stringsAsFactors = FALSE
    ) %>%
      mutate(
        pct_effect = round(100 * (exp(estimate) - 1), 1),
        sig = case_when(
          p.value < 0.001 ~ "***", p.value < 0.01 ~ "**",
          p.value < 0.05 ~ "*", TRUE ~ ""
        ),
        interpretation = paste0(
          ifelse(pct_effect > 0, "+", ""), pct_effect,
          "% wage change from urban vs rural (relative to Brahmin urban gain)"
        )
      )
    cat("\nWage penalty — Group × Urban interaction:\n")
    print(wage_int_summary %>% select(term, estimate, pct_effect, p.value, sig, interpretation),
          row.names = FALSE)
    write.csv(wage_int_summary,
              "output/tables/wage_urban_rural_interaction.csv", row.names = FALSE)
    saveRDS(wage_model_ur, "output/models/model_wage_urban_rural.rds")
  } else {
    cat("No significant wage interactions found.\n")
  }
} else {
  cat("Insufficient wage data for interaction analysis.\n")
}

# ── VISUALIZATION ─────────────────────────────────────────────────────────────
print_section("VISUALIZATION: Urban-Rural Employment by Group")

theme_premium <- theme_minimal() +
  theme(
    text             = element_text(family = "serif"),
    plot.title       = element_text(face = "bold", size = 15),
    axis.title       = element_text(face = "italic"),
    panel.grid.minor = element_blank(),
    legend.position  = "top"
  )

# Grouped bar chart: employment rate by group × urban/rural
plot_data <- urban_rural_descriptive %>%
  filter(!is.na(social_group)) %>%
  mutate(
    social_group = factor(social_group,
      levels = c("Brahmins","Forward_castes","OBCs","Dalits","Adivasis","Muslims","Other_Religions"))
  )

plot_ur <- ggplot(plot_data,
    aes(x = social_group, y = employment_rate, fill = urban_rural)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
  geom_text(aes(label = paste0(round(employment_rate, 1), "%")),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 2.8, fontface = "bold") +
  scale_fill_manual(values = c("Rural" = "#2c3e50", "Urban" = "#e67e22"),
                    name = "Setting") +
  labs(
    title    = "Employment Rates by Social Group and Urban-Rural Setting",
    subtitle = "Compares how the urban-rural divide shapes employment differently across groups",
    x        = "Social Group",
    y        = "Employment Rate (%)"
  ) +
  theme_premium +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("output/plots/urban_rural_employment_by_group.png", plot_ur,
       width = 12, height = 7, dpi = 300)

# Faceted regional heatmap (where data is sufficient)
plot_regional <- ggplot(
    regional_descriptive %>% filter(n >= 100),
    aes(x = urban_rural, y = social_group, fill = employment_rate)
  ) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = paste0(round(employment_rate, 0), "%")),
            color = "white", fontface = "bold", size = 2.8) +
  scale_fill_gradient2(
    low     = "#c0392b", mid = "#f39c12", high = "#27ae60",
    midpoint = 40, name = "Employment\nRate (%)"
  ) +
  facet_wrap(~region, nrow = 2) +
  labs(
    title    = "Employment Rate by Group, Urban-Rural, and Region",
    subtitle = "Reveals how geography within states shapes group-specific labour market access",
    x        = "", y        = ""
  ) +
  theme_premium +
  theme(
    strip.text = element_text(face = "bold"),
    axis.text.y = element_text(size = 8)
  )

ggsave("output/plots/regional_urban_rural_heatmap.png", plot_regional,
       width = 14, height = 9, dpi = 300)

cat("\n✓ Within-state urban-rural dynamics analysis complete\n")
cat("  Outputs:\n")
cat("  • output/tables/urban_rural_group_descriptives.csv\n")
cat("  • output/tables/urban_rural_employment_gap.csv\n")
cat("  • output/tables/urban_rural_group_interaction.csv\n")
cat("  • output/tables/predicted_probs_urban_rural.csv\n")
cat("  • output/tables/regional_urban_rural_employment.csv\n")
cat("  • output/plots/urban_rural_employment_by_group.png\n")
cat("  • output/plots/regional_urban_rural_heatmap.png\n")
