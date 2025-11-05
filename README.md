This research project analyzes how social networks, education, and economic resources affect employment outcomes in rural India, with particular focus on understanding disadvantages faced by Muslim communities in labor markets.


Data Sources

    India Human Development Survey (IHDS)
    Individual and household modules merged for comprehensive analysis
    Rural sample: 204,568 observations

Regression Model
     
    glm(employed ~ org_membership + general_trust + education_years + 
      social_group + female + age + age_sq + wealth_index + 
      urban_resident + factor(STATEID_ind),
      family = binomial(link = "logit"), data = model_data)


Through this research project i developed an understanding of:

A) Data Management & Wrangling

    Data merging with multiple complex datasets using keys (IDHH)

    Factor variable handling - converting survey codes to meaningful labels

    Missing data diagnostics and strategic filtering

    Variable recoding - creating analytical variables from raw survey data

    Data validation - checking merge success, unmerged records

B) Statistical Analysis

    Logistic regression for binary outcomes (employment probability)

    Odds ratios interpretation - converting coefficients to meaningful effects

    Model diagnostics - McFadden's R², AIC, deviance

    Multiple comparison handling - understanding statistical significance

    Fixed effects - state-level controls to account for geographic variation

C) R Programming Skills

    # Advanced dplyr and tidyverse
    analysis_data <- merged_data %>%
         mutate() %>%
         filter() %>%
         group_by() %>%
         summarise() %>%
         arrange()

 
    # Function writing for reproducibility
    convert_work_var <- function(x) {
      as.numeric(x %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"))
    }

    # Robust error handling
    safe_coef_summary <- function(model, term) {
      if(term %in% names(coef(model))) {
        # Safe extraction logic
      } else {
       return(list(found = FALSE))
      }
    }

D) Data Visualization

    ggplot2 for publication-quality graphs

    Effective labeling and theming
