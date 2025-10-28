# Initial Setup
# Load required packages
library(haven)       # for reading .dta files
library(dplyr)       # for data manipulation
library(tidyverse)   # for data science workflow
library(survey)      # for survey-weighted analysis
library(car)         # for variable recoding
library(ggplot2)
library(scales)
# Set working directory (adjust path)
setwd("C:/Users/ashwin/Desktop/IIHDS_Project")



# Data Loading and Merging
# Read data files
individual <- load("36151-0001-Data.rda")
household <- load("36151-0002-Data.rda")

# Check key identifiers
glimpse(da36151.0001 %>% select(STATEID, DISTID, PSUID, HHID, HHSPLITID, IDHH, PERSONID))
glimpse(da36151.0002 %>% select(STATEID, DISTID, PSUID, HHID, HHSPLITID, IDHH))

# Merge using IDHH (recommended method)
merged_data <- da36151.0001 %>%
  left_join(da36151.0002, by = "IDHH", suffix = c("_ind", "_hh"))

# Verify merge success
cat("Individual records:", nrow(da36151.0001), "\n")
cat("Merged records:", nrow(merged_data), "\n")
cat("Household records:", nrow(da36151.0002), "\n")

# names(merged_data)

# Check for unmerged records (should be 0)
unmerged_individuals <- anti_join(da36151.0001, da36151.0002, by = "IDHH")
cat("Unmerged individuals:", nrow(unmerged_individuals), "\n")



# Step 1: Check if work variables exist
cat("WKANY5_ind exists:", "WKANY5_ind" %in% names(merged_data), "\n")
cat("WKSALARY_ind exists:", "WKSALARY_ind" %in% names(merged_data), "\n")

work_vars <- names(merged_data)[grepl("WK|WORK|EMPLOY|LABOR|JOB", names(merged_data))]
print(work_vars)
employment_vars <- names(merged_data)[grepl("RO7|OCCUP|EMP", names(merged_data))]
print(employment_vars)

# Check variable types and values
cat("WKANY5 type:", class(merged_data$WKANY5), "\n")
cat("WKANY5 values:\n")
print(table(merged_data$WKANY5, useNA = "always"))

cat("\nED6 type:", class(merged_data$ED6), "\n") 
cat("ED6 values:\n")
print(table(merged_data$ED6, useNA = "always"))

# Check if social capital variables exist
cat("ME1 exists:", "ME1" %in% names(merged_data), "\n")
if("ME1" %in% names(merged_data)) {
  cat("ME1 type:", class(merged_data$ME1), "\n")
  cat("ME1 values:\n")
  print(table(merged_data$ME1, useNA = "always"))
}

# Variable Creation and Data Cleaning
# Create analysis dataset with proper factor coding
analysis_data <- merged_data %>%
  # Employment outcomes - properly coded for factors
  mutate(
    employed = case_when(
      WKANY5 == "(2) <240hrs 2" ~ 1,
      WKANY5 == "(3) parttime 3" ~ 1, 
      WKANY5 == "(4) ft yr 4" ~ 1,
      WKANY5 == "(0) none 0" ~ 0,
      WKANY5 == "(1) missing hours 1" ~ 0,
      TRUE ~ NA_real_
    ),
    employment_type = case_when(
      WKSALARY %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ "Salaried",
      WKBUSINESS %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ "Business",
      WKFARM %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ "Farm",
      WKAGLAB %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") | 
        WKNONAG %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ "Wage_Labor",
      employed == 0 ~ "Not_Working",
      TRUE ~ "Other"
    ),
    employment_type = factor(employment_type, 
                           levels = c("Not_Working", "Salaried", "Business", 
                                    "Farm", "Wage_Labor", "Other"))
  ) %>%
  
  # Social capital indices
  mutate(
    org_membership = ifelse(ME1 == "(1) Yes 1", 1, 0),  # Simple version for now
    social_support = ifelse("SN1" %in% names(.), {
      # Convert SN variables to numeric properly
      sn_data <- select(., matches("^SN[0-9]+[A-Z]*$"))
      if(ncol(sn_data) > 0) {
        rowSums(sapply(sn_data, function(x) as.numeric(x == "(1) Yes 1")), na.rm = TRUE)
      } else {
        NA
      }
    }, NA),
    
    institutional_trust = ifelse("CI1" %in% names(.), {
      ci_data <- select(., matches("^CI[0-9]+$"))
      if(ncol(ci_data) > 0) {
        rowSums(sapply(ci_data, function(x) as.numeric(x == "(1) A lot 1")), na.rm = TRUE)
      } else {
        NA
      }
    }, NA),
    
    general_trust = ifelse(TR1 == "(1) Most people can be trusted 1", 1, 0)
  ) %>%
  
  # Cultural capital and demographics
  mutate(
    female = ifelse(RO3 == "(2) Female 2", 1, 0),
    age = as.numeric(as.character(RO5)),
    age_sq = age^2,
    
    # Education - convert factor levels to years
    education_years = case_when(
      ED6 == "(00) none 0" ~ 0,
      ED6 == "(55) <1 class 55" ~ 0.5,
      ED6 == "(01) 1st class 1" ~ 1,
      ED6 == "(02) 2nd class 2" ~ 2,
      ED6 == "(03) 3rd class 3" ~ 3,
      ED6 == "(04) 4th class 4" ~ 4,
      ED6 == "(05) 5th class 5" ~ 5,
      ED6 == "(06) 6th class 6" ~ 6,
      ED6 == "(07) 7th class 7" ~ 7,
      ED6 == "(08) 8th class 8" ~ 8,
      ED6 == "(09) 9th class 9" ~ 9,
      ED6 == "(10) Secondary 10" ~ 10,
      ED6 == "(11) 11th Class 11" ~ 11,
      ED6 == "(12) High Secondary 12" ~ 12,
      ED6 == "(13) 1 year post-secondary" ~ 13,
      ED6 == "(14) 2 years post-secondary" ~ 14,
      ED6 == "(15) Bachelors 15" ~ 15,
      ED6 == "(16) Above Bachelors 16" ~ 16,
      TRUE ~ NA_real_
    ),
    
    education_cat = case_when(
      education_years == 0 ~ "No_education",
      education_years > 0 & education_years <= 5 ~ "Primary",
      education_years > 5 & education_years <= 10 ~ "Secondary",
      education_years > 10 ~ "Higher",
      TRUE ~ "Unknown"
    ),
    
    social_group = factor(GROUPS_ind,
                         levels = c("(1) Brahmin 1", "(2) Forward caste 2", "(3) OBC 3", 
                                  "(4) Dalit 4", "(5) Adivasi 5", "(6) Muslim 6", 
                                  "(7) Christian, Sikh, Jain 7"),
                         labels = c("Brahmins", "Forward_castes", "OBCs", 
                                  "Dalits", "Adivasis", "Muslims", 
                                  "Other_Religions"))
  ) %>%
  
  # Household economic controls
  mutate(
    wealth_index = as.numeric(as.character(ASSETS_hh)),
    consumption = as.numeric(as.character(COTOTAL_hh)),
    ln_consumption = log(consumption + 1),
    urban_resident = ifelse(URBAN2011_ind == "(1) Urban 1", 1, 0)
  ) %>%
  
  # Select final variables
  select(
    # Identifiers
    IDHH, PERSONID, STATEID_ind, DISTID_ind, PSUID_ind,
    
    # Employment outcomes
    employed, employment_type, 
    WKANY5, WKSALARY, WKBUSINESS, WKFARM, WKAGLAB, WKNONAG,
    
    # Social capital
    org_membership, social_support, institutional_trust, general_trust,
    
    # Cultural capital & demographics
    education_years, education_cat, social_group, female, age, age_sq,
    
    # Household controls
    wealth_index, consumption, ln_consumption, urban_resident,
    
    # Survey weights
    WT_ind, FWT_ind
  )

# Check the final dataset
glimpse(analysis_data)
summary(analysis_data %>% select(employed, org_membership, education_years, wealth_index))

# Check employment types distribution
cat("Employment type distribution:\n")
table(analysis_data$employment_type, useNA = "always")

# Check social group distribution 
cat("Social group distribution:\n")
table(analysis_data$social_group, useNA = "always")

# Check education categories
cat("Education category distribution:\n")
table(analysis_data$education_cat, useNA = "always")


# Model 1: Employment Probability (Logit/Probit)
# Basic logit model with CORRECT state variable
model1 <- glm(employed ~ org_membership + social_support + institutional_trust +
               education_years + social_group + female + age + age_sq +
               wealth_index + urban_resident + factor(STATEID_ind),
             family = binomial(link = "logit"),
             data = analysis_data)

# Check the model summary
summary(model1)

# Check the final dataset
cat("Final dataset dimensions:", dim(analysis_data), "\n\n")

# Check employment types distribution
cat("Employment type distribution:\n")
print(table(analysis_data$employment_type, useNA = "always"))

# Check social group distribution
cat("\nSocial group distribution:\n")
print(table(analysis_data$social_group, useNA = "always"))

# Check education categories
cat("\nEducation category distribution:\n")
print(table(analysis_data$education_cat, useNA = "always"))

# Check for missing values in key variables
cat("\nMissing values in key variables:\n")
missing_vars <- c("employed", "org_membership", "social_support", "institutional_trust", 
                  "general_trust", "education_years", "social_group", "female", 
                  "age", "wealth_index", "urban_resident")
missing_summary <- sapply(analysis_data[missing_vars], function(x) sum(is.na(x)))
print(missing_summary)


# Check wealth by social group
wealth_by_group <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    employment_rate = mean(employed, na.rm = TRUE),
    n = n()
  ) %>%
  arrange(desc(mean_wealth))

cat("Wealth and Employment by Social Group:\n")
print(wealth_by_group)

# Visualize the wealth-employment paradox
ggplot(wealth_by_group, aes(x = mean_wealth, y = employment_rate, 
                           color = social_group, size = n)) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = social_group), vjust = -0.8, size = 3) +
  labs(title = "Wealth-Employment Paradox by Social Group",
       subtitle = "Your hypothesis: Wealthier groups may have lower employment",
       x = "Mean Wealth Index",
       y = "Employment Rate") +
  theme_minimal()


# This model answers ALL your original questions
final_model <- glm(employed ~ org_membership + general_trust +  # SOCIAL CAPITAL
                    education_years + social_group +           # CULTURAL CAPITAL  
                    female + age + age_sq + wealth_index +     # CONTROLS
                    urban_resident + factor(STATEID_ind),      # GEO CONTROLS
                  family = binomial(link = "logit"),
                  data = analysis_data)

summary(final_model)
# Then we can interpret:
# - Social capital effects (org_membership, general_trust) = Being a member of organizations increases employment probability. The Odds Ratio: exp(0.078) = 1.081 → 8.1% higher odds of employment
# - Cultural capital effects (education, social_group) =Each additional year of education increases employment probability
# - Your wealth paradox finding! =Negative and significant (-0.104, p < 0.001)

# I noticed that the muslim group has low employment and low wealth is it an outlier?
# Detailed analysis of Muslim employment patterns
muslim_analysis <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    female_rate = mean(female, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE),
    .groups = 'drop'
  )

cat("Muslim Group Characteristics:\n")
print(muslim_analysis)

# Compare Muslims with other groups
comparison <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(employment_rate)

cat("\nAll Groups Comparison (sorted by employment):\n")
print(comparison, n = 10)

# Check employment types for Muslims
muslim_employment_types <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  count(employment_type) %>%
  mutate(percent = n / sum(n) * 100)

cat("\nMuslim Employment Types:\n")
print(muslim_employment_types)


# Explore possible mechanisms
muslim_mechanisms <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    # Occupational segregation
    business_rate = mean(WKBUSINESS %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"), na.rm = TRUE),
    salaried_rate = mean(WKSALARY %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"), na.rm = TRUE),
    farm_rate = mean(WKFARM %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"), na.rm = TRUE),
    # Education barriers
    higher_education_rate = mean(education_cat == "Higher", na.rm = TRUE),
    no_education_rate = mean(education_cat == "No_education", na.rm = TRUE),
    .groups = 'drop'
  )

cat("Potential Mechanisms for Muslim Employment Patterns:\n")
print(muslim_mechanisms)

# Compare with other groups
mechanisms_comparison <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    business_rate = mean(WKBUSINESS %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"), na.rm = TRUE),
    salaried_rate = mean(WKSALARY %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"), na.rm = TRUE),
    higher_education_rate = mean(education_cat == "Higher", na.rm = TRUE),
    .groups = 'drop'
  )

cat("\nEmployment Mechanisms by Social Group:\n")
print(mechanisms_comparison, n = 10)

# Muslims have the LOWEST salaried employment rate (1.9%) of any group!


