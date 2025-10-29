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




    
