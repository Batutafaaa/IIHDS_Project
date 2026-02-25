# ==============================================================================
# SC/ST GEOGRAPHIC CONCENTRATION ANALYSIS
# ==============================================================================

# Source setup
source("scripts/00_setup.r")
print_section("SC/ST GEOGRAPHIC ANALYSIS INITIALIZED")

# Helper functions
source("scripts/utils_functions.r")

# ==============================================================================
# 1. LOAD PRE-PREPARED DATA
# ==============================================================================
cat("\n[1/4] Loading Full Analysis Data...\n")

analysis_data_full <- readRDS("output/analysis_data_full.rds")

# Construct variables needed for aggregation
analysis_data <- analysis_data_full %>%
    mutate(
        is_sc = as.numeric(social_group == "Dalits"),
        is_st = as.numeric(social_group == "Adivasis"),
        state_id = STATEID_ind,
        district_id = DISTID_ind
    ) %>%
    filter(!is.na(employed))

cat("Data loaded. Observations:", nrow(analysis_data), "\n")
cat("Total Dalits (SC):", sum(analysis_data$is_sc, na.rm = TRUE), "\n")
cat("Total Adivasis (ST):", sum(analysis_data$is_st, na.rm = TRUE), "\n")

# ==============================================================================
# 2. DISTRICT-LEVEL AGGREGATION
# ==============================================================================
cat("\n[2/4] Aggregating to District Level...\n")

district_summary <- analysis_data %>%
    group_by(district_id, state_id) %>%
    summarize(
        n_sample = n(),
        sc_share = mean(is_sc, na.rm = TRUE) * 100,
        st_share = mean(is_st, na.rm = TRUE) * 100,
        employment_rate = mean(employed, na.rm = TRUE) * 100,
        .groups = "drop"
    ) %>%
    filter(n_sample >= 50)

cat("Districts analyzed:", nrow(district_summary), "\n")

# ==============================================================================
# 3. STATISTICAL ANALYSIS
# ==============================================================================
cat("\n[3/4] Analyzing Relationships...\n")

# --- SC (Dalit) Analysis ---
cat("\n>>> SC (Dalit) Concentration Analysis <<<\n")
cor_sc <- cor.test(district_summary$sc_share, district_summary$employment_rate)
cat("Correlation (SC % vs Employment %):", round(cor_sc$estimate, 3), "\n")
cat("P-value:", format.pval(cor_sc$p.value), "\n")

lm_sc <- lm(employment_rate ~ sc_share, data = district_summary, weights = n_sample)
cat("Regression Slope:", round(coef(lm_sc)["sc_share"], 3), "\n")

# --- ST (Adivasi) Analysis ---
cat("\n>>> ST (Adivasi) Concentration Analysis <<<\n")
cor_st <- cor.test(district_summary$st_share, district_summary$employment_rate)
cat("Correlation (ST % vs Employment %):", round(cor_st$estimate, 3), "\n")
cat("P-value:", format.pval(cor_st$p.value), "\n")

lm_st <- lm(employment_rate ~ st_share, data = district_summary, weights = n_sample)
cat("Regression Slope:", round(coef(lm_st)["st_share"], 3), "\n")

# ==============================================================================
# 4. IDENTIFYING KEY DISTRICTS & VISUALIZATION
# ==============================================================================
cat("\n[4/4] Generating Outputs...\n")

# Top SC Districts
top_sc <- district_summary %>%
    arrange(desc(sc_share)) %>%
    head(15) %>%
    select(district_id, state_id, sc_share, employment_rate, n_sample)

# Top ST Districts
top_st <- district_summary %>%
    arrange(desc(st_share)) %>%
    head(15) %>%
    select(district_id, state_id, st_share, employment_rate, n_sample)

cat("\nTop 15 Districts by SC Share:\n")
print(top_sc)

cat("\nTop 15 Districts by ST Share:\n")
print(top_st)

write.csv(district_summary, "output/tables/district_concentration_sc_st.csv", row.names = FALSE)
write.csv(top_sc, "output/tables/top_sc_districts.csv", row.names = FALSE)
write.csv(top_st, "output/tables/top_st_districts.csv", row.names = FALSE)

# ==============================================================================
# 5. VISUALIZATION
# ==============================================================================
# Theme
theme_premium <- theme_minimal() +
    theme(
        text = element_text(family = "serif"),
        plot.title = element_text(face = "bold", size = 16),
        axis.title = element_text(face = "italic"),
        panel.grid.minor = element_blank(),
        legend.position = "right"
    )

# Visualization - SC
plot_sc <- ggplot(district_summary, aes(x = sc_share, y = employment_rate)) +
    geom_point(aes(size = n_sample), alpha = 0.4, color = "#8e44ad") +
    geom_smooth(method = "lm", color = "#2980b9", fill = "#F4ECF7", size = 1.2) +
    labs(
        title = "Dalit (SC) Concentration vs. District Employment",
        subtitle = paste("Correlation:", round(cor_sc$estimate, 3)),
        x = "Dalit Population Share (%)",
        y = "Overall District Employment Rate (%)",
        size = "Sample Size"
    ) +
    theme_premium +
    scale_size_continuous(range = c(2, 8))

ggsave("output/plots/sc_employment_correlation.png", plot_sc, width = 10, height = 7, dpi = 300)

# Visualization - ST
plot_st <- ggplot(district_summary, aes(x = st_share, y = employment_rate)) +
    geom_point(aes(size = n_sample), alpha = 0.4, color = "#27ae60") +
    geom_smooth(method = "lm", color = "#c0392b", fill = "#E9F7EF", size = 1.2) +
    labs(
        title = "Adivasi (ST) Concentration vs. District Employment",
        subtitle = paste("Correlation:", round(cor_st$estimate, 3)),
        x = "Adivasi Population Share (%)",
        y = "Overall District Employment Rate (%)",
        size = "Sample Size"
    ) +
    theme_premium +
    scale_size_continuous(range = c(2, 8))

ggsave("output/plots/st_employment_correlation.png", plot_st, width = 10, height = 7, dpi = 300)

cat("\n✓ Plots saved to output/plots/\n")
cat("✓ Analysis saved to output/tables/\n")
