library("ggplot2")
library("segmented")
library("plotrix")
library("gridExtra")
library("lubridate")
library("chron")
library('plyr')
library('tidyverse')
library('stringr')
library('Rmisc')
library('janitor')
library("tidyr")


getwd()
######################### INITIAL ############################################## #####
# read in info necessary for analysis 
Treatments<-read.csv('sample_info.csv')%>%filter(genus =="por")%>%select(coral_id, treatment)
Volume<- read.csv("Respirometry/Data/initial_vol.csv")%>%filter(species =="por")%>%select(coral_id, chamber_vol)
#read in sample info and combine with other data frames
sample.info<- left_join(Treatments, Volume, by = "coral_id")
sample.info[nrow(sample.info) + 1,] <- list(0, NA, 650)
sample.info[nrow(sample.info) + 1,] <- list(1, NA, 650)
view(sample.info)
#read in R rates
data1<- read.csv("Respirometry/Output/Respiration/20230526/Respiration.csv")%>%select(-X)
#combine sample info with rates by coral id 
Respiration<- left_join(data1, sample.info, by = "coral_id")
#Convert sample/chamber volume to L
Respiration$chamber_vol <- Respiration$chamber_vol/1000 #calculate volume
#Account for chamber volume to convert from umol L-1 s-1 to umol s-1. This standardizes across water volumes (different because of coral size) and removes per Liter
Respiration$umol.sec <- Respiration$umol.L.sec*Respiration$chamber_vol
# Extract rows with blank data from respiration data frame
blankrows <- c(1,2)
blank_rates <- Respiration[blankrows, ]%>% 
  rename(blank_id = coral_id)%>%
  select(blank_id, umol.sec)
#read in blank ids to relates blank rate to sample/coral 
blank_id<- read.csv("Respirometry/Data/Runs/20230526/Porites/blank_id.csv")
#combine data frames by blank id
blanks<- left_join(blank_id, blank_rates, by = "blank_id")
blanks<- blanks%>%rename(blank_rate = umol.sec)
#remove NAs from resp data frame
Respiration<- na.omit(Respiration)
#combine blank rates with coral rates
Respiration<- left_join(Respiration, blanks, by = "coral_id")
Respiration$umol.sec.corr<-Respiration$umol.sec-Respiration$blank_rate
View(Respiration)
#standardize to intitial coral size
w1<- read.csv("Respirometry/Data/initial_weight.csv")%>%rename(weight = X1)%>%filter(species == "por")%>%select(coral_id, weight)
Respiration<- left_join(Respiration, w1, by = "coral_id")
Respiration$umol.g.hr <- (Respiration$umol.sec.corr*3600)/Respiration$weight
Respiration<- Respiration%>%
  mutate(umol.g.hr = abs(umol.g.hr))%>%
  select(coral_id, treatment, umol.g.hr, weight)
Initial_Resp_Norm<- write.csv(Respiration,"Respirometry/Output/Respiration/rates/por/Initial_Resp_Norm.csv") 

#plot
ggplot(Respiration, aes(x=treatment, y=umol.g.hr))+
  geom_boxplot()+
  ylab('Respiration (umol.g.hr)')
######################### POST WOUND ########################################### #####
# read in info necessary for analysis 
Treatments<-read.csv('sample_info.csv')%>%filter(genus =="por")%>%select(coral_id, treatment)
Volume<- read.csv("Respirometry/Data/postwound_vol.csv")%>%filter(species =="por")%>%select(coral_id, chamber_vol)
#Weight_Initial<- read.csv("Respirometry/Data/postwound_weight.csv")%>%filter(species =="por")%>%rename(weight = X1)%>%select(coral_id, weight)
#read in sample info and combine with other data frames
sample.info<- left_join(Treatments, Volume, by = "coral_id")
sample.info[nrow(sample.info) + 1,] <- list(0, NA, 650)
sample.info[nrow(sample.info) + 1,] <- list(1, NA, 650)
view(sample.info)
#read in R rates
data1<- read.csv("Respirometry/Output/Respiration/20230528/Respiration.csv")%>%select(-X)
#combine sample info with rates by coral id 
Respiration<- left_join(data1, sample.info, by = "coral_id")
#Convert sample/chamber volume to L
Respiration$chamber_vol <- Respiration$chamber_vol/1000 #calculate volume
#Account for chamber volume to convert from umol L-1 s-1 to umol s-1. This standardizes across water volumes (different because of coral size) and removes per Liter
Respiration$umol.sec <- Respiration$umol.L.sec*Respiration$chamber_vol
# Extract rows with blank data from respiration data frame
blankrows <- c(1,2)
blank_rates <- Respiration[blankrows, ]%>% 
  rename(blank_id = coral_id)%>%
  select(blank_id, umol.sec)
#read in blank ids to relates blank rate to sample/coral 
blank_id<- read.csv("Respirometry/Data/Runs/20230528/Porites/blank_id.csv")
#combine data frames by blank id
blanks<- left_join(blank_id, blank_rates, by = "blank_id")
blanks<- blanks%>%rename(blank_rate = umol.sec)
#remove NAs from resp data frame
Respiration<- na.omit(Respiration)
#combine blank rates with coral rates
Respiration<- left_join(Respiration, blanks, by = "coral_id")
Respiration$umol.sec.corr<-Respiration$umol.sec-Respiration$blank_rate
View(Respiration)
#standardize to intitial coral size
w2<- read.csv("Respirometry/Data/postwound_weight.csv")%>%rename(weight = X2)%>%filter(species == "por")%>%select(coral_id, weight)
Respiration<- left_join(Respiration, w2, by = "coral_id")
Respiration$umol.hr <- (Respiration$umol.sec.corr*3600) #/Respiration$weight
Respiration<- Respiration%>%
  mutate(umol.hr = abs(umol.hr))%>%
  #select(coral_id, treatment, umol.g.hr, weight)%>%
  mutate(treatment = as.factor(treatment))

#plot
ggplot(Respiration, aes(x=treatment, y=umol.hr))+
  geom_boxplot()+
  ylab('Respiration (umol.hr)')




