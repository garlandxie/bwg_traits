# libraries -----
library(here)    # for creating relative file-paths
library(readr)   # for reading comma-delimited files
library(assertr) # for validating data
library(visdat)  # for visualizing missing data
library(dplyr)   # for manipulating data 

# import ----

# what files are in the BWG data folder? 
myfiles <- list.files(
  path = here("data/original"),
  pattern = "*.csv", 
  full.names = TRUE
)

# import all tables as separate data frames
# remove fie path and file extensions (.csv)

list2env(
  lapply(
    setNames(
      myfiles,
      make.names(
        gsub(".*1_", "", tools::file_path_sans_ext(myfiles)
             ),
        )
      ),
    readr::read_csv
  ),
  envir = .GlobalEnv
)

# check packaging ----

str(bromeliads)
head(bromeliads, n = 5)
tail(bromeliads, n = 5)

# check names in bromeliads df ----

names(bromeliads)

# check for missing values ----

# check the entire dataset first
visdat::vis_miss(bromeliads)

# check selected columns (easier to read)
bromeliads %>%
  select(
    visit_id, 
    dataset_id, 
    species, 
    num_leaf,
    longest_leaf, 
    max_water
    ) %>%
visdat::vis_miss()
