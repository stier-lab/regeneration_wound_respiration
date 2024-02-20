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
#library('tidyverse')
library('stringr')
library('Rmisc')
library('janitor')
library('readxl')
library('purrr')
# Detach dplyr and tidyverse
# detach("package:dplyr", unload = TRUE)
# detach("package:tidyverse", unload = TRUE)


##################### DATA WRANGLING PORITES RESPO TRIALS####################### #####
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
run11<- read.csv("Respirometry/Data/Runs/rawdata_ppm/20230603_run_11.csv" , header = TRUE, skip = 1)
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

coral_to_filter <- c( 54, 43, 0)

filtered_data_list <- map(coral_to_filter, ~filter(run11_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230603/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 12
run12<- read.csv("Respirometry/Data/Runs/rawdata_ppm/20230603_run_12.csv" , header = TRUE, skip = 1)
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

coral_to_filter <- c(42, 57, 1)

filtered_data_list <- map(coral_to_filter, ~filter(run12_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230603/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 7
run7<- read.csv("Respirometry/Data/Runs/rawdata_ppm/20230528_run_7.csv" , header = TRUE, skip = 1)
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

coral_to_filter <- c(58, 54, 0)

filtered_data_list <- map(coral_to_filter, ~filter(run7_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230528/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})

#run 8
run8<- read.csv("Respirometry/Data/Runs/rawdata_ppm/20230528_run_8.csv" , header = TRUE, skip = 1)
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

coral_to_filter <- c(41, 53, 1)

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

coral_to_filter <- c(41, 46, 0)

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

coral_to_filter <- c(45, 50, 1)

filtered_data_list <- map(coral_to_filter, ~filter(run4_merged, coral_id == .))

output_directory <- "/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230526/Porites"
walk2(coral_to_filter, filtered_data_list, ~{
  filename <- file.path(output_directory, paste(.x, ".csv", sep = ""))
  write.csv(.y, filename, row.names = FALSE)
})
##################### RESPIRATION ############################################## #####
path.p<-"/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230603/Porites"

#make a list of the respo file names inside intial timepoint folder, n=120
file.names <- list.files(path = path.p, pattern = "csv$")
file.names.full <- tools::file_path_sans_ext(file.names) #removes .csv 
print(file.names.full)

#create respiration data frame, 4 columns and # rows corresponding to respo files (n=120)
Respiration<- data.frame(matrix(NA, nrow=length(file.names.full), ncol=4))
colnames(Respiration) <- c("coral_id","Intercept", "umol.L.sec","Temp.C")
Respiration$coral_id <- file.names.full # Insert file names into "coral_id" column 
View(Respiration)

#create photosynthesis data frame
Photosynthesis<- data.frame(matrix(NA, nrow=length(file.names.full), ncol=4))
colnames(Photosynthesis) <- c("coral_id","Intercept", "umol.L.sec","Temp.C")
Photosynthesis$coral_id <- file.names.full
View(Photosynthesis)


# for every file in list calculate O2 uptake or release rate and add the data to the Respiration dataframe
for(i in 1:length(file.names)) { # for every file in list calculate O2 uptake or release rate and add the data to the Photo.R dataframe
  
  # read in the O2 data one by one
  Photo.Data1 <-read.csv(file.path(path.p,file.names[i]), header=T) 
  Photo.Data1  <- Photo.Data1[,c("delta_t","value","temp")] #subset columns of interest
  #Photo.Data1$Time <- as.POSIXct(Photo.Data1$Time,format="%H:%M:%S", tz = "") #convert time from character to time
  Photo.Data1 <- na.omit(Photo.Data1) #omit NA from data frame
  
  # clean up some of the data
  n<-dim(Photo.Data1)[1] # length of full data
  Photo.Data1 <- Photo.Data1 %>% mutate(delta_t=as.numeric(delta_t))%>%filter(delta_t > 10 & delta_t < 25) #start at beginning of dark phase data point (25 minutes in) 
  n<-dim(Photo.Data1)[1] #list length of trimmed data
  Photo.Data1$sec <- seq(1, by = 3, length.out = n) #set seconds by three from start to finish of run in a new column
  
  
  #Save plot prior to and after data thinning to make sure thinning is not too extreme
  rename <- sub(".csv","", file.names[i]) # remove all the extra stuff in the file name
  
  pdf(paste0("/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Output/Photosynthesis/20230603/",rename,"thinning.pdf")) # open the graphics device
  
  par(omi=rep(0.3, 4)) #set size of the outer margins in inches
  par(mfrow=c(1,2)) #set number of rows and columns in multi plot graphic
  plot(value ~ sec, data=Photo.Data1 , xlab='Time (seconds)', ylab=expression(paste(' O'[2],' (',mu,'mol/L)')), type='n', axes=FALSE) #plot (empty plot to fill) data as a function of time
  usr  <-  par('usr') # extract the size of the figure margins
  rect(usr[1], usr[3], usr[2], usr[4], col='grey90', border=NA) # put a grey background on the plot
  whiteGrid() # make a grid
  box() # add a box around the plot
  points(Photo.Data1 $value ~ Photo.Data1 $sec, pch=16, col=transparentColor('dodgerblue2', 0.6), cex=1.1)
  axis(1) # add the x axis
  axis(2, las=1) # add the y-axis
  
  # Thin the data to make the code run faster
  Photo.Data.orig <-Photo.Data1 #save original unthinned data
  Photo.Data1 <-  thinData(Photo.Data1 ,by=5)$newData1 #thin data by every 20 points for all the O2 values
  Photo.Data1$sec <- as.numeric(rownames(Photo.Data1 )) #maintain numeric values for time
  Photo.Data1$Temp<-NA # add a new column to fill with the thinned data
  Photo.Data1$Temp <-  thinData(Photo.Data.orig,xy = c(1,3),by=5)$newData1[,2] #thin data by every 20 points for the temp values
  
  # plot the thinned data
  plot(value ~ sec, data=Photo.Data1 , xlab='Time (seconds)', ylab=expression(paste(' O'[2],' (',mu,'mol/L)')), type='n', axes=FALSE) #plot thinned data
  usr  <-  par('usr')
  rect(usr[1], usr[3], usr[2], usr[4], col='grey90', border=NA)
  whiteGrid()
  box()
  points(Photo.Data1 $value ~ Photo.Data1 $sec, pch=16, col=transparentColor('dodgerblue2', 0.6), cex=1.1)
  axis(1)
  axis(2, las=1)
  ##Olito et al. 2017: It is running a bootstrapping technique and calculating the rate based on density
  #option to add multiple outputs method= c("z", "eq", "pc")
  Regs  <-  rankLocReg(xall=Photo.Data.orig$sec, yall=Photo.Data.orig$value, alpha=0.5, method="pc", verbose=TRUE)  
  
  # add the regression data
  plot(Regs)
  dev.off()
  
  
  # fill in all the O2 consumption and rate data
  Photosynthesis[i,2:3] <- Regs$allRegs[1,c(4,5)] #inserts slope and intercept in the dataframe
  Photosynthesis[i,1] <- rename #stores the file name in the Date column
  Photosynthesis[i,4] <- mean(Photo.Data1$Temp, na.rm=T)  #stores the Temperature in the Temp.C column
  #Photo.R[i,5] <- PR[j] #stores whether it is photosynthesis or respiration
  
}
write.csv(Photosynthesis, '/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Output/Photosynthesis/20230603/Photosynthesis.csv')

write.csv(Respiration, '/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Output/Respiration/20230619/Respiration.csv')
          
          
##################### PHOTOSYNTHESIS ########################################### #####
path.p<-"/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs/20230619/Porites"

#make a list of the respo file names inside intial timepoint folder, n=120
file.names <- list.files(path = path.p, pattern = "csv$")
file.names.full <- tools::file_path_sans_ext(file.names) #removes .csv 
print(file.names.full)

#create photosynthesis data frame
Photosynthesis<- data.frame(matrix(NA, nrow=length(file.names.full), ncol=4))
colnames(Photosynthesis) <- c("coral_id","Intercept", "umol.L.sec","Temp.C")
Photosynthesis$coral_id <- file.names.full
View(Photosynthesis)


# for every file in list calculate O2 uptake or release rate and add the data to the Photo.R dataframe
for(i in 1:length(file.names)) { # for every file in list calculate O2 uptake or release rate and add the data to the Photo.R dataframe
  
  # read in the O2 data one by one
  Photo.Data1 <-read.csv(file.path(path.p,file.names[i]), skip = 1, header=T) # skips the first line
  Photo.Data1  <- Photo.Data1[,c("delta_t","value","temp")] #subset columns of interest
  #Photo.Data1$Time <- as.POSIXct(Photo.Data1$Time,format="%H:%M:%S", tz = "") #convert time from character to time
  Photo.Data1 <- na.omit(Photo.Data1) #omit NA from data frame
  
  # clean up some of the data
  n<-dim(Photo.Data1)[1] # length of full data
  Photo.Data1 <- Photo.Data1 %>% mutate(delta_t=as.numeric(delta_t))%>%filter(delta_t > 10 & delta_t < 25) #start at beginning of light phase (10 minutes in) and stop at 25 min (start of dark phase)
  n<-dim(Photo.Data1)[1] #list length of trimmed data
  Photo.Data1$sec <- seq(1, by = 3, length.out = n) #set seconds by three from start to finish of run in a new column
  
  #Save plot prior to and after data thinning to make sure thinning is not too extreme
  rename <- sub(".csv","", file.names[i]) # remove all the extra stuff in the file name
  
  pdf(paste0("/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Output/Photosynthesis/20230619/",rename,"thinning.pdf")) # open the graphics device
  
  par(omi=rep(0.3, 4)) #set size of the outer margins in inches
  par(mfrow=c(1,2)) #set number of rows and columns in multi plot graphic
  plot(value ~ sec, data=Photo.Data1 , xlab='Time (seconds)', ylab=expression(paste(' O'[2],' (',mu,'mol/L)')), type='n', axes=FALSE) #plot (empty plot to fill) data as a function of time
  usr  <-  par('usr') # extract the size of the figure margins
  rect(usr[1], usr[3], usr[2], usr[4], col='grey90', border=NA) # put a grey background on the plot
  whiteGrid() # make a grid
  box() # add a box around the plot
  points(Photo.Data1 $value ~ Photo.Data1 $sec, pch=16, col=transparentColor('dodgerblue2', 0.6), cex=1.1)
  axis(1) # add the x axis
  axis(2, las=1) # add the y-axis
  
  # Thin the data to make the code run faster
  Photo.Data.orig <-Photo.Data1 #save original unthinned data
  Photo.Data1 <-  thinData(Photo.Data1 ,by= 5)$newData1 #thin data by every 5 points for all the O2 values
  Photo.Data1$sec <- as.numeric(rownames(Photo.Data1 )) #maintain numeric values for time
  Photo.Data1$Temp<-NA # add a new column to fill with the thinned data
  Photo.Data1$Temp <-  thinData(Photo.Data.orig,xy = c(1,3),by=5)$newData1[,2] #thin data by every 5 points for the temp values
  
  # plot the thinned data
  plot(value ~ sec, data=Photo.Data1 , xlab='Time (seconds)', ylab=expression(paste(' O'[2],' (',mu,'mol/L)')), type='n', axes=FALSE) #plot thinned data
  usr  <-  par('usr')
  rect(usr[1], usr[3], usr[2], usr[4], col='grey90', border=NA)
  whiteGrid()
  box()
  points(Photo.Data1 $value ~ Photo.Data1 $sec, pch=16, col=transparentColor('dodgerblue2', 0.6), cex=1.1)
  axis(1)
  axis(2, las=1)
  ##Olito et al. 2017: It is running a bootstrapping technique and calculating the rate based on density
  #option to add multiple outputs method= c("z", "eq", "pc")
  Regs  <-  rankLocReg(xall=Photo.Data.orig$sec, yall=Photo.Data.orig$value, alpha=0.5, method="pc", verbose=TRUE)  
  
  # add the regression data
  plot(Regs)
  dev.off()
  
  
  # fill in all the O2 consumption and rate data
  Photosynthesis[i,2:3] <- Regs$allRegs[1,c(4,5)] #inserts slope and intercept in the dataframe
  Photosynthesis[i,1] <- rename #stores the file name in the Date column
  Photosynthesis[i,4] <- mean(Photo.Data1$Temp, na.rm=T)  #stores the Temperature in the Temp.C column

}

write.csv(Photosynthesis, '/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Output/Photosynthesis/20230619/Respiration.csv')