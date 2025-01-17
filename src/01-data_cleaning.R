################################################################################
# Accompanying code for the exercise: 
#   No environmental filtering of wasps and bees during urbanization
#
#
# Corresponding authors for this script:  
#   Garland Xie      
#
# Affiliations: 
#       Department of Biological Sciences, 
#       University of Toronto Scarborough,
#       1265 Military Trail, Toronto, ON, M1C 1A4, Canada
#       email: garland.xie@mail.utoronto.ca, 
#
#
# Purpose of this R script: to quality control checks on three 
# measured variables in the bromeliads dataset: 
# (1) max water
# (2) extended diameter
# (3) total detritus

# libraries --------------------------------------------------------------------
library(here)    # for creating relative file-paths
library(readr)   # for reading comma-delimited files
library(assertr) # for validating data
library(visdat)  # for visualizing missing data
library(dplyr)   # for manipulating data 

# import -----------------------------------------------------------------------

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

# check packaging --------------------------------------------------------------

str(bromeliads)
head(bromeliads, n = 5)
tail(bromeliads, n = 5)

# check names in bromeliads df -------------------------------------------------

names(bromeliads)

# check for missing values -----------------------------------------------------

# check the entire dataset first
visdat::vis_miss(bromeliads)

# check selected columns (easier to read)
bromeliads %>%
  select(
    visit_id, 
    dataset_id, 
    species, 
    max_water,
    total_detritus,
    extended_diameter
    ) %>%
visdat::vis_miss()

# validate data ----------------------------------------------------------------

errors <- bromeliads %>%
  
  # assert that the following columns are within a reasonable range
  # i.e., from zero to infinity (since you can't have negative values here)
  # this pipeline is an analog of the assert function in the Julia language
  assert(within_bounds(0, Inf), extended_diameter) %>%
  assert(within_bounds(0, Inf), total_detritus) %>%
  assert(within_bounds(0, Inf), max_water) %>%
  
  # insist for any possible outliers where 
  # I assume values exceeding four median absolute deviations
  # are considered to be "bad data point 
  # and should be removed from the analysis
  insist(
    within_n_mads(4), 
    c(extended_diameter,max_water, total_detritus),  
    error_fun = error_df_return
    ) 

if(length(errors$index) >1) {
  
  # if any errors are detected, return an object (data frame)
  # where I then create a vector containing indexes with 
  # bad data points (outliers)
  # and filter them out of the bromeliads data set
  # and then calculate summary statistics 
  error.list <- as.vector(errors$index)
  
  brom_tidy <- bromeliads %>%
    slice(-error.list) 
  
  # rerun to very data validation
  brom_checks <- brom_tidy %>%
    assert(within_bounds(0, Inf), extended_diameter) %>%
    assert(within_bounds(0, Inf), total_detritus) %>%
    assert(within_bounds(0, Inf), max_water) %>%
    insist(
      within_n_mads(4), 
      c(extended_diameter,max_water, total_detritus),  
      error_fun = error_df_return
    ) 
  
  brom_tidy <- brom_tidy %>%
    group_by(species) %>%
    summarize(
      
      # total detritus
      n_tot_det    = sum(!is.na(total_detritus)), 
      mean_tot_det = mean(total_detritus, na.rm = TRUE), 
      sd_tot_det   = sd(total_detritus, na.rm = TRUE),
      
      # max water 
      n_max_water    = sum(!is.na(max_water)), 
      mean_max_water = mean(max_water, na.rm = TRUE),
      sd_ext_diam    = mean(extended_diameter, na.rm = TRUE),
      
      # extended diameter
      n_ext_diam     = sum(!is.na(extended_diameter)), 
      mean_ext_diam  = mean(extended_diameter, na.rm = TRUE),
      sd_ext_diam    = sd(extended_diameter, na.rm = TRUE)
    )
} else {
  
  # if there are no violations, then summarize the dataset (brom_tidy) by
  # creating average values per species (with their associated sd's)
  brom_tidy <- errors %>%
    group_by(species) %>%
    summarize(
      
      # total detritus
      n_tot_det    = sum(!is.na(total_detritus)),
      mean_tot_det = mean(total_detritus, na.rm = TRUE), 
      sd_tot_det   = sd(total_detritus, na.rm = TRUE),
      
      # max water 
      n_max_water    = sum(!is.na(max_water)), 
      mean_max_water = mean(max_water, na.rm = TRUE),
      sd_ext_diam  = mean(extended_diameter, na.rm = TRUE),
      
      # extended diameter
      n_ext_diam     = sum(!is.na(extended_diameter)), 
      mean_ext_diam  = mean(extended_diameter, na.rm = TRUE),
      sd_ext_diam    = sd(extended_diameter, na.rm = TRUE)
    )
}

# save to disk -----------------------------------------------------------------

readr::write_csv(
  x = brom_tidy, 
  file = here("data/final", "brom_tidy.csv")
)

