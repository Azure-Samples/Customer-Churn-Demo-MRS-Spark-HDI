# Load or install CRAN R libraries
message("Loading CRAN R packages if they are not installed...")

options("repos" = "https://mran.revolutionanalytics.com") 
(if (!require("AzureML", quietly = TRUE)) install.packages("AzureML"))
options("repos" = "http://cran.r-project.org")
(if (!require("rpart", quietly = TRUE)) install.packages("rpart"))

