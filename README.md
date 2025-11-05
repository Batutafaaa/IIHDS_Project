# Social Capital & Employment in Rural India

Analysis of how social and cultural capital affect employment outcomes across social groups, with focus on Muslim communities.

## 📊 Project Details
- **Data**: India Human Development Survey (IHDS-II, 2011-12)
- **Methods**: Logistic regression with state fixed effects  
- **Focus**: Rural labor markets, social group disparities

## 📚 Documentation
- [Detailed Project Documentation](docs/READ.md)
- [Full Analysis Report](docs/main_analysis.Rmd)
- [HTML Report](main_analysis.html)

## 🚀 Quick Start
```r
# Run complete analysis
source("scripts/run_analysis.R")

# Generate report
rmarkdown::render("docs/main_analysis.Rmd")
