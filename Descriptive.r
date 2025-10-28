
# Basic descriptive statistics by social group
social_group_summary <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(percent = n / sum(n) * 100)

print(social_group_summary)


# 1. Employment vs Education by Social Group
ggplot(social_group_summary, aes(x = mean_education, y = employment_rate, 
                                color = social_group, size = n)) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = social_group), vjust = -0.5, size = 3) +
  labs(title = "Employment Rate vs Education by Social Group",
       x = "Mean Education Years",
       y = "Employment Rate") +
  theme_minimal()

# 2. Employment vs Wealth by Social Group
ggplot(social_group_summary, aes(x = mean_wealth, y = employment_rate,
                                color = social_group, size = n)) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = social_group), vjust = -0.5, size = 3) +
  labs(title = "Employment Rate vs Wealth by Social Group",
       x = "Mean Wealth Index",
       y = "Employment Rate") +
  theme_minimal()

# Employment by gender and education
gender_education_employment <- analysis_data %>%
  group_by(female, education_cat) %>%
  summarise(
    employment_rate = mean(employed, na.rm = TRUE),
    n = n(),
    .groups = 'drop'
  )

print(gender_education_employment)

ggplot(analysis_data, aes(x = education_cat, y = employed, color = factor(female))) +
  stat_summary(aes(size = ..count..), fun = mean, geom = "point", alpha = 0.7, 
               position = position_dodge(width = 0.5)) +
  scale_color_manual(values = c("#1f77b4", "#ff7f0e"),
                    labels = c("Male", "Female"),
                    name = "Gender") +
  scale_size_continuous(name = "Sample Size", range = c(3, 10)) +
  scale_y_continuous(labels = percent) +
  labs(title = "Employment Rate vs Education Level by Gender",
       x = "Education Level",
       y = "Employment Rate") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))