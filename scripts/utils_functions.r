# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_section("LOADING HELPER FUNCTIONS")

# Employment variable conversion
convert_work_var <- function(x) {
  as.numeric(x %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"))
}

# Education years extraction
extract_education_years <- function(ed_var) {
  dplyr::case_when(
    ed_var == "(00) none 0" ~ 0,
    ed_var == "(55) <1 class 55" ~ 0.5,
    ed_var == "(01) 1st class 1" ~ 1,
    ed_var == "(02) 2nd class 2" ~ 2,
    ed_var == "(03) 3rd class 3" ~ 3,
    ed_var == "(04) 4th class 4" ~ 4,
    ed_var == "(05) 5th class 5" ~ 5,
    ed_var == "(06) 6th class 6" ~ 6,
    ed_var == "(07) 7th class 7" ~ 7,
    ed_var == "(08) 8th class 8" ~ 8,
    ed_var == "(09) 9th class 9" ~ 9,
    ed_var == "(10) Secondary 10" ~ 10,
    ed_var == "(11) 11th Class 11" ~ 11,
    ed_var == "(12) High Secondary 12" ~ 12,
    ed_var == "(13) 1 year post-secondary" ~ 13,
    ed_var == "(14) 2 years post-secondary" ~ 14,
    ed_var == "(15) Bachelors 15" ~ 15,
    ed_var == "(16) Above Bachelors 16" ~ 16,
    TRUE ~ NA_real_
  )
}

# Marginal effects calculation
calculate_ame <- function(model, data, variable, is_binary = TRUE) {
  pred_data <- data[complete.cases(data[, all.vars(formula(model))]), ]
  
  if (is_binary) {
    data0 <- pred_data
    data1 <- pred_data
    data0[[variable]] <- 0
    data1[[variable]] <- 1
    
    pred0 <- predict(model, newdata = data0, type = "response")
    pred1 <- predict(model, newdata = data1, type = "response")
    
    ame <- mean(pred1 - pred0, na.rm = TRUE)
    se <- sd(pred1 - pred0, na.rm = TRUE) / sqrt(length(pred1))
  } else {
    h <- sd(pred_data[[variable]], na.rm = TRUE) * 0.01
    data_plus <- pred_data
    data_minus <- pred_data
    data_plus[[variable]] <- pred_data[[variable]] + h
    data_minus[[variable]] <- pred_data[[variable]] - h
    
    pred_plus <- predict(model, newdata = data_plus, type = "response")
    pred_minus <- predict(model, newdata = data_minus, type = "response")
    
    marginal_effects <- (pred_plus - pred_minus) / (2 * h)
    ame <- mean(marginal_effects, na.rm = TRUE)
    se <- sd(marginal_effects, na.rm = TRUE) / sqrt(length(marginal_effects))
  }
  
  return(list(AME = ame, SE = se, z = ame/se, p = 2 * (1 - pnorm(abs(ame/se)))))
}

cat("✓ Helper functions loaded\n")