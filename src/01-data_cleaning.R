# libraries -----
library(here)   # for creating relative file-paths
library(readr)

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
