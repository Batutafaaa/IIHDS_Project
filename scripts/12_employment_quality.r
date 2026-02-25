# ==============================================================================
# EMPLOYMENT QUALITY ANALYSIS
# ==============================================================================

# Source setup
source("scripts/00_setup.r")
print_section("EMPLOYMENT QUALITY ANALYSIS INITIALIZED")

# Helper functions
source("scripts/utils_functions.r")

# ==============================================================================
# 1. LOAD PRE-PREPARED DATA
# ==============================================================================
cat("\n[1/4] Loading Full Analysis Data & Constructing Quality Metrics...\n")

analysis_data_full <- readRDS("output/analysis_data_full.rds")

# Ensure consistency with rural_only flag if it exists
if (exists("rural_only") && rural_only) {
    cat(">>> FILTERING FOR RURAL AREAS ONLY (Consistency with Project Setup) <<<\n")
    if ("URBAN2011_ind" %in% names(analysis_data_full)) {
        analysis_data_full <- analysis_data_full %>%
            filter(URBAN2011_ind != "(1) Urban 1")
    } else if ("urban_resident" %in% names(analysis_data_full)) {
        analysis_data_full <- analysis_data_full %>%
            filter(urban_resident == 0)
    }
}

quality_data <- analysis_data_full %>%
    mutate(
        # Standard Social Group Broadening
        social_group_broad = case_when(
            social_group %in% c("Brahmins", "Forward_castes") ~ "Forward/Upper",
            social_group == "Dalits" ~ "Dalit (SC)",
            social_group == "Adivasis" ~ "Adivasi (ST)",
            social_group == "Muslims" ~ "Muslim",
            social_group == "OBCs" ~ "OBC",
            TRUE ~ "Others"
        ),

        # 1. JOB SECURITY / CONTRACT TYPE (Use robust string matching)
        contract_raw = as.character(WS13),
        contract_type = case_when(
            grepl("Casual", contract_raw, ignore.case = TRUE) ~ "Casual",
            grepl("Temporary|Contract <1yr", contract_raw, ignore.case = TRUE) ~ "Temporary",
            grepl("Permanent|Longer contract", contract_raw, ignore.case = TRUE) ~ "Permanent",
            TRUE ~ NA_character_
        ),

        # 2. EARNINGS
        annual_earnings = as.numeric(as.character(WSEARN)),

        # 3. WORK INTENSITY (WKNONAG already preserved)
        is_full_time = as.numeric(WKNONAG == "(4) ft yr 4"),

        # 4. BENEFITS (Safely handle numeric coercion)
        has_paid_leave = as.numeric(suppressWarnings(as.numeric(as.character(WS15))) > 0),
        has_meal_benefit = as.numeric(suppressWarnings(as.numeric(as.character(WS11MEALS))) > 0),

        # 5. DISTRESS WORK (NREGA)
        has_nrega = as.numeric(!is.na(WS7NREGA) & WS7NREGA > 0)
    )

# Filter to only those with some earnings/employment for Quality Analysis
employed_data <- quality_data %>%
    filter(!is.na(contract_type) | (annual_earnings > 0 & !is.na(annual_earnings))) %>%
    mutate(
        # Formal Job Index (0-3 scale: Permanent, Paid Leave, Meals)
        formal_job_index = (as.numeric(contract_type == "Permanent") +
            coalesce(has_paid_leave, 0) +
            coalesce(has_meal_benefit, 0)),
        is_formal = as.numeric(formal_job_index >= 1) # At least one benefit/permanent
    )

cat("Working Age Population:", nrow(quality_data), "\n")
cat("Employed Population (for Quality Analysis):", nrow(employed_data), "\n")

# ==============================================================================
# 2. JOB SECURITY ANALYSIS (Contract Type)
# ==============================================================================
cat("\n[2/4] Analyzing Job Security (Contract Type)...\n")

contract_table <- employed_data %>%
    filter(!is.na(contract_type), !is.na(social_group_broad)) %>%
    group_by(social_group_broad) %>%
    summarize(
        n = n(),
        pct_Casual = mean(contract_type == "Casual", na.rm = TRUE) * 100,
        pct_Permanent = mean(contract_type == "Permanent", na.rm = TRUE) * 100,
        pct_Temporary = mean(contract_type == "Temporary", na.rm = TRUE) * 100
    ) %>%
    filter(social_group_broad != "Others")

print(contract_table)
write.csv(contract_table, "output/tables/job_security_by_group.csv", row.names = FALSE)

# ==============================================================================
# 2.5 FORMAL JOB BENEFITS ANALYSIS
# ==============================================================================
cat("\n[2.5/4] Analyzing Formal Job Benefits...\n")

formal_summary <- employed_data %>%
    filter(!is.na(social_group_broad)) %>%
    group_by(social_group_broad) %>%
    summarize(
        pct_Paid_Leave = mean(has_paid_leave, na.rm = TRUE) * 100,
        pct_Meals = mean(has_meal_benefit, na.rm = TRUE) * 100,
        pct_Formal_Index_1plus = mean(is_formal, na.rm = TRUE) * 100,
        mean_Formal_Score = mean(formal_job_index, na.rm = TRUE)
    ) %>%
    filter(social_group_broad != "Others")

print(formal_summary)
write.csv(formal_summary, "output/tables/formal_job_benefits.csv", row.names = FALSE)

# ==============================================================================
# 3. EARNINGS ANALYSIS
# ==============================================================================
cat("\n[3/4] Analyzing Earnings Gaps...\n")

# Summary of Mean/Median Earnings
earnings_summary <- employed_data %>%
    filter(annual_earnings > 0, !is.na(social_group_broad)) %>%
    group_by(social_group_broad) %>%
    summarize(
        mean_earnings = mean(annual_earnings, na.rm = TRUE),
        median_earnings = median(annual_earnings, na.rm = TRUE),
        n_earners = n()
    ) %>%
    mutate(
        gap_vs_forward = (mean_earnings - mean_earnings[social_group_broad == "Forward/Upper"]) /
            mean_earnings[social_group_broad == "Forward/Upper"] * 100
    ) %>%
    filter(social_group_broad != "Others")

print(earnings_summary)
write.csv(earnings_summary, "output/tables/earnings_summary.csv", row.names = FALSE)

# Wage Regression (Adjusted Earnings Gap)
cat("\nRunning Wage Regression (Adjusting for Education, Age, Location)...\n")
reg_data <- employed_data %>%
    filter(annual_earnings > 0, !is.na(education_years)) %>%
    mutate(log_earnings = log(annual_earnings))

# Check for urban_resident variation (might be NA in rural-only analysis)
if (all(is.na(reg_data$urban_resident)) | length(unique(reg_data$urban_resident)) < 2) {
    cat("Note: urban_resident has no variation, dropping from regression.\n")
    wage_model <- lm(log_earnings ~ social_group + education_years + age + female + factor(STATEID_ind),
        data = reg_data
    )
} else {
    wage_model <- lm(log_earnings ~ social_group + education_years + age + female + urban_resident + factor(STATEID_ind),
        data = reg_data
    )
}

wage_results <- summary(wage_model)$coefficients
group_coefs <- wage_results[grep("social_group", rownames(wage_results)), ]
print(group_coefs)

# ==============================================================================
# 4. DISTRESS EMPLOYMENT (NREGA)
# ==============================================================================
cat("\n[4/4] Analyzing Distress Employment (NREGA)...\n")

nrega_summary <- quality_data %>%
    filter(!is.na(social_group_broad)) %>%
    group_by(social_group_broad) %>%
    summarize(
        pct_NREGA = mean(has_nrega, na.rm = TRUE) * 100
    ) %>%
    filter(social_group_broad != "Others")

print(nrega_summary)
write.csv(nrega_summary, "output/tables/nrega_participation.csv", row.names = FALSE)


# ==============================================================================
# 5. VISUALIZATION
# ==============================================================================
# Themes
theme_premium <- theme_minimal() +
    theme(
        text = element_text(family = "serif"),
        plot.title = element_text(face = "bold", size = 16),
        axis.title = element_text(face = "italic"),
        panel.grid.minor = element_blank(),
        legend.position = "bottom"
    )

# Stacked Bar for Contract Type
plot_contract <- ggplot(
    employed_data %>%
        filter(!is.na(contract_type), !is.na(social_group_broad), social_group_broad != "Others") %>%
        group_by(social_group_broad, contract_type) %>%
        summarize(count = n(), .groups = "drop") %>%
        group_by(social_group_broad) %>%
        mutate(pct = count / sum(count)),
    aes(x = social_group_broad, y = pct, fill = contract_type)
) +
    geom_bar(stat = "identity", width = 0.7) +
    geom_text(aes(label = sprintf("%.1f%%", pct * 100)),
        position = position_stack(vjust = 0.5), size = 3, color = "white", fontface = "bold"
    ) +
    labs(
        title = "Job Security Gaps: Contract Type by Social Group",
        subtitle = "Casual labor is significantly higher among SC/ST and Muslim groups",
        y = "Percentage of Workers", x = "",
        fill = "Contract Type"
    ) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) +
    theme_premium

ggsave("output/plots/contract_type_distribution.png", plot_contract, width = 9, height = 7)

# Boxplot for Earnings
plot_earnings <- ggplot(
    reg_data %>% filter(social_group_broad != "Others"),
    aes(x = social_group_broad, y = annual_earnings, fill = social_group_broad)
) +
    geom_boxplot(outlier.shape = 21, outlier.alpha = 0.2, width = 0.6) +
    scale_y_log10(labels = scales::comma) +
    labs(
        title = "Annual Earnings Inequality",
        subtitle = "(Log Scale, Employed Workers Only)",
        y = "Annual Earnings (INR)", x = ""
    ) +
    scale_fill_brewer(palette = "Set2") +
    theme_premium +
    theme(legend.position = "none")

ggsave("output/plots/earnings_distribution.png", plot_earnings, width = 9, height = 7)

cat("\n✓ Analysis Complete. Outputs saved to output/tables/ and output/plots/\n")

cat("\n✓ Analysis Complete. Outputs saved to output/tables/ and output/plots/\n")
