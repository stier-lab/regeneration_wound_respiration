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

run15<- read.csv("Respirometry/Data/Runs/20230619/20230619_run_15.csv" , header = TRUE, skip = 1)
view(run15)

run15_clean<- run15%>%select(Channel, delta_t, Value, Temp)%>%clean_names
view(run15_clean)

#create data frame with coral id's and channel assignments for this run (from trial datasheets)

channel <- c(1:10)
coral_id<- c(51, 52, 54, 44, 0, 47, 43, 46, 58, 48) #0 is blank

run15_corals<- data.frame(channel, coral_id)
view(run15_corals)

run15_corals<- run15_corals%>%mutate(channel = as.character(channel))

run15_merged<- left_join(run15_clean, run15_corals, by= 'channel')
view(run15_merged)
