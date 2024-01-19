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

filtered_data_list <- map(coral_to_filter, ~filter(run16_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230619/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#subsequent data files need ppm to umol conversion for channels 3,4, & 5 

#run 11
run11<- read.csv("Respirometry/Data/Runs/20230603/20230603_run_11.csv" , header = TRUE, skip = 1)
view(run11)

run11_clean<- run11%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run11_clean)
nrow(run11_clean)
tail(run11_clean)

channel <- c(1:10)
coral_id<- c(46, 48, 54, 43, 0, 47, 44, 52, 58, 51) #0 is blank
run11_corals<- data.frame(channel, coral_id)
view(run11_corals)

run11_corals<- run11_corals%>%mutate(channel = as.character(channel))

run11_merged<- left_join(run11_clean, run11_corals, by= 'channel')
view(run11_merged)
run11_merged<- run11_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(46, 48, 47, 44, 52, 58, 51)

filtered_data_list <- map(coral_to_filter, ~filter(run11_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230603/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 12
run12<- read.csv("Respirometry/Data/Runs/20230603/20230603_run_12.csv" , header = TRUE, skip = 1)
view(run12)

run12_clean<- run12%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run12_clean)
nrow(run12_clean)
tail(run12_clean)

channel <- c(1:10)
coral_id<- c(41, 55, 42, 57, 1, 50, 56, 49, 53, 45) #1 is blank
run12_corals<- data.frame(channel, coral_id)
view(run12_corals)

run12_corals<- run12_corals%>%mutate(channel = as.character(channel))

run12_merged<- left_join(run12_clean, run12_corals, by= 'channel')
view(run12_merged)
run12_merged<- run12_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(41, 55, 50, 56, 49, 53, 45)

filtered_data_list <- map(coral_to_filter, ~filter(run12_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230603/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 7
run7<- read.csv("Respirometry/Data/Runs/20230528/20230528_run_7.csv" , header = TRUE, skip = 1)
view(run7)

run7_clean<- run7%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run7_clean)
nrow(run7_clean)
tail(run7_clean)

channel <- c(1:10)
coral_id<- c(43, 48, 58, 54, 0, 51, 52, 47, 44, 46) #0 is blank
run7_corals<- data.frame(channel, coral_id)
view(run7_corals)

run7_corals<- run7_corals%>%mutate(channel = as.character(channel))

run7_merged<- left_join(run7_clean, run7_corals, by= 'channel')
view(run7_merged)
run7_merged<- run7_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(43, 48, 51, 52, 47, 44, 46)

filtered_data_list <- map(coral_to_filter, ~filter(run7_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230528/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 8
run8<- read.csv("Respirometry/Data/Runs/20230528/20230528_run_8.csv" , header = TRUE, skip = 1)
view(run8)

run8_clean<- run8%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run8_clean)
nrow(run8_clean)
tail(run8_clean)

channel <- c(1:10)
coral_id<- c(45, 42, 41, 53, 1, 57, 49, 55, 56, 50) #1 is blank
run8_corals<- data.frame(channel, coral_id)
view(run8_corals)

run8_corals<- run8_corals%>%mutate(channel = as.character(channel))

run8_merged<- left_join(run8_clean, run8_corals, by= 'channel')
view(run8_merged)
run8_merged<- run8_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(45, 42, 57, 49, 55, 56, 50)

filtered_data_list <- map(coral_to_filter, ~filter(run8_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230528/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 3
run3<- read.csv("Respirometry/Data/Runs/20230526/20230526_run_3.csv" , header = TRUE, skip = 1)
view(run3)

run3_clean<- run3%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run3_clean)
nrow(run3_clean)
tail(run3_clean)

channel <- c(1:10)
coral_id<- c(58, 52, 41, 46, 0, 44, 47, 43, 42, 49) #0 is blank
run3_corals<- data.frame(channel, coral_id)
view(run3_corals)

run3_corals<- run3_corals%>%mutate(channel = as.character(channel))

run3_merged<- left_join(run3_clean, run3_corals, by= 'channel')
view(run3_merged)
run3_merged<- run3_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(58, 52, 44, 47, 43, 42, 49)

filtered_data_list <- map(coral_to_filter, ~filter(run3_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230526/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 4
run4<- read.csv("Respirometry/Data/Runs/20230526/20230526_run_4.csv" , header = TRUE, skip = 1)
view(run4)

run4_clean<- run4%>%select(Channel, delta_t, Value, Temp)%>%clean_names%>%filter(row_number() <= n()-1)
view(run4_clean)
nrow(run4_clean)
tail(run4_clean)

channel <- c(1:10)
coral_id<- c(48, 55, 45, 50, 1, 57, 56, 51, 53, 54) #1 is blank
run4_corals<- data.frame(channel, coral_id)
view(run4_corals)

run4_corals<- run4_corals%>%mutate(channel = as.character(channel))

run4_merged<- left_join(run4_clean, run4_corals, by= 'channel')
view(run4_merged)
run4_merged<- run4_merged%>%mutate(coral_id = as.character(coral_id))

coral_to_filter <- c(48, 55, 57, 56, 51, 53, 54)

filtered_data_list <- map(coral_to_filter, ~filter(run4_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230526/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})
############################ PPM to umol ################################# #####