# ==============================================================================
# GEOGRAPHIC CONCENTRATION ANALYSIS
# ==============================================================================

# Source setup but suppress output
source("scripts/00_setup.r")
print_section("GEOGRAPHIC ANALYSIS INITIALIZED")

# Helper functions
source("scripts/utils_functions.r")

# ============================================
# 1. LOAD PRE-PREPARED DATA
# ============================================
cat("\n[1/4] Loading Full Analysis Data...\n")

analysis_data_full <- readRDS("output/analysis_data_full.rds")

# Variables needed for aggregation
analysis_data <- analysis_data_full %>%
    mutate(
        is_muslim = as.numeric(social_group == "Muslims"),
        state_id = STATEID_ind,
        district_id = DISTID_ind
    ) %>%
    filter(!is.na(employed))

cat("Data loaded. Observations:", nrow(analysis_data), "\n")

# ====================================
# 2. DISTRICT-LEVEL AGGREGATION
# ====================================
cat("\n[2/4] Aggregating to District Level...\n")

district_summary <- analysis_data %>%
    group_by(district_id, state_id) %>%
    summarize(
        n_sample = n(),
        muslim_share = mean(is_muslim, na.rm = TRUE) * 100,
        employment_rate = mean(employed, na.rm = TRUE) * 100,
        .groups = "drop"
    ) %>%
    filter(n_sample >= 50) # Filter out districts with very few samples for reliability

cat("Districts analyzed:", nrow(district_summary), "\n")

# ==============================================================================
# 3. STATISTICAL ANALYSIS
# ==============================================================================
cat("\n[3/4] Analyzing Relationship...\n")

# Correlation
cor_res <- cor.test(district_summary$muslim_share, district_summary$employment_rate)
cat("Correlation (Muslim % vs Employment %):", round(cor_res$estimate, 3), "\n")
cat("P-value:", format.pval(cor_res$p.value), "\n")

# Weighted Regression (giving more weight to larger districts)
lm_geo <- lm(employment_rate ~ muslim_share, data = district_summary, weights = n_sample)
cat("\nRegression Slope (Weighted):", round(coef(lm_geo)["muslim_share"], 3), "\n")
cat(
    "Interpretation: For every 10% increase in Muslim population, district employment changes by",
    round(coef(lm_geo)["muslim_share"] * 10, 2), "pp\n"
)

# ==============================================================================
# 4. IDENTIFYING KEY DISTRICTS
# ==============================================================================
cat("\n[4/4] Identifying High-Concentration Districts...\n")

# Sort by Muslim Share
top_muslim_districts <- district_summary %>%
    arrange(desc(muslim_share)) %>%
    head(20) %>%
    select(district_id, state_id, muslim_share, employment_rate, n_sample)

cat("\nTop 20 Districts by Muslim Share:\n")
print(top_muslim_districts)

# Save results
write.csv(district_summary, "output/tables/district_concentration.csv", row.names = FALSE)
write.csv(top_muslim_districts, "output/tables/top_muslim_districts.csv", row.names = FALSE)

# ==============================================================================
# 5. VISUALIZATION
# ==============================================================================
# Theme (Consistent with employment quality)
theme_premium <- theme_minimal() +
    theme(
        text = element_text(family = "serif"),
        plot.title = element_text(face = "bold", size = 16),
        axis.title = element_text(face = "italic"),
        panel.grid.minor = element_blank(),
        legend.position = "right"
    )

# Scatterplot Visualization
plot_geo <- ggplot(district_summary, aes(x = muslim_share, y = employment_rate)) +
    geom_point(aes(size = n_sample), alpha = 0.4, color = "#2c3e50") +
    geom_smooth(method = "lm", color = "#e74c3c", fill = "#ecf0f1", size = 1.2) +
    labs(
        title = "District-Level: Muslim Share vs. Employment",
        subtitle = paste("Correlation:", round(cor_res$estimate, 3), "| Weighted aggregation of districts"),
        x = "Muslim Population Share (%)",
        y = "Overall District Employment Rate (%)",
        size = "Sample Size"
    ) +
    theme_premium +
    scale_size_continuous(range = c(2, 8))

ggsave("output/plots/muslim_employment_correlation.png", plot_geo, width = 10, height = 7, dpi = 300)
cat("\n✓ Plot saved to output/plots/muslim_employment_correlation.png\n")
cat("✓ Analysis saved to output/tables/district_concentration.csv\n")
