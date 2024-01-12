#Respirometry experiments for wounded Porites May/June 2023
library("ggplot2")
library("segmented")
library("plotrix")
library("gridExtra")
library("LoLinR")
library("lubridate")
library("chron")
library('plyr')
library('dplyr')
library('tidyverse')
library('stringr')
library('Rmisc')
library('janitor')
library('readxl')
install.packages('purrr')
library('purrr')


#####################DATA WRANGLING PORITES RESPO TRIALS######################## #####
#set working directory
setwd("/Volumes/Stier_Lab/regeneration_wound_respiration")

#upload respo data file and skip first row 
run15<- read.csv("Respirometry/Data/Runs/20230619/20230619_run_15.csv" , header = TRUE, skip = 1)
view(run15)

#select the columns with data we need (channel, delta_t (time), Value (O2 concentration), Temp) & remove the last row
run15_clean<- run15%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run15_clean)
nrow(run15_clean)
tail(run15_clean)

#create data frame associating channels with coral ID's for this run (coral ids recorded on trial datasheets)
channel <- c(1:10)
coral_id<- c(51, 52, 54, 44, 0, 47, 43, 46, 58, 48) #0 is blank
run15_corals<- data.frame(channel, coral_id)
view(run15_corals)

#change channel to character values in data frame 
run15_corals<- run15_corals%>%mutate(channel = as.character(channel))

#assign a coral ID to each channel by merging data frames
run15_merged<- left_join(run15_clean, run15_corals, by= 'channel')
view(run15_merged)
run15_merged<- run15_merged%>%mutate(coral_id = as.character(coral_id))

#coral IDs to filter into separate data frames
coral_to_filter <- c(51, 52, 54, 44, 0, 47, 43, 46, 58, 48)

# Use purrr::map to filter the data frame for each coral ID
filtered_data_list <- map(coral_to_filter, ~filter(run15_merged, coral_id == .))

# Save each filtered data frame to separate CSV files
output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230619/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#repeat for run 16
run16<- read.csv("Respirometry/Data/Runs/20230619/20230619_run_16.csv" , header = TRUE, skip = 1)
view(run16)
run16_clean<- run16%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run16_clean)
nrow(run16_clean)
tail(run16_clean)

channel <- c(1:10)
coral_id<- c(42, 45, 56, 49, 1, 50, 57, 55, 53, 41) # 1 is the blank for the second trial of Porites that day
run16_corals<- data.frame(channel, coral_id)
view(run16_corals)

run16_corals<- run16_corals%>%mutate(channel = as.character(channel))

run16_merged<- left_join(run16_clean, run16_corals, by= 'channel')
view(run16_merged)
run16_merged<- run16_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(42, 45, 56, 49, 1, 50, 57, 55, 53, 41)
# Use purrr::map to filter the data frame for each coral ID
filtered_data_list <- map(coral_to_filter, ~filter(run16_merged, coral_id == .))

# Save each filtered data frame to separate CSV files
output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230619/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#subsequent data files need ppm to umol conversion for channels 3,4, & 5 

#run 11
run11<- read.csv("Respirometry/Data/Runs/20230603/20230603_run_11.csv" , header = TRUE, skip = 1)
view(run11)

#select the columns with data we need (channel, delta_t (time), Value (O2 concentration), Temp) & remove the last row
run11_clean<- run11%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run11_clean)
nrow(run11_clean)
tail(run11_clean)

#create data frame associating channels with coral ID's for this run (coral ids recorded on trial datasheets)
channel <- c(1:10)
coral_id<- c(46, 48, 54, 43, 0, 47, 44, 52, 58, 51) #0 is blank
run11_corals<- data.frame(channel, coral_id)
view(run11_corals)
#LEFT OFF HERE
#change channel to character values in data frame 
run15_corals<- run15_corals%>%mutate(channel = as.character(channel))

#assign a coral ID to each channel by merging data frames
run15_merged<- left_join(run15_clean, run15_corals, by= 'channel')
view(run15_merged)
run15_merged<- run15_merged%>%mutate(coral_id = as.character(coral_id))

#coral IDs to filter into separate data frames
coral_to_filter <- c(51, 52, 54, 44, 0, 47, 43, 46, 58, 48)

# Use purrr::map to filter the data frame for each coral ID
filtered_data_list <- map(coral_to_filter, ~filter(run15_merged, coral_id == .))

# Save each filtered data frame to separate CSV files
output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230619/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

