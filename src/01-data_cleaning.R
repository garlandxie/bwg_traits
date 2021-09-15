# libraries -----
library(here)   # for creating relative file-paths
library(tidyr)

# import ----

myfiles <- list.files(
  path = here("data/original"),
  pattern = "*.csv", 
  full.names = TRUE
)