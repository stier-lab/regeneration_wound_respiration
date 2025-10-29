library(tidyverse)
library(ggplot2)

getwd()

#read in raw data and combine time points into one data frame
pam1<- read.csv("PAM/Data/20230603_pam.csv")%>%select(-X)
pam2<- read.csv("PAM/Data/20230619_pam.csv")%>% select_if(~ !any(is.na(.)))
combined<- rbind(pam1, pam2)%>%mutate(genus=as.factor(genus))

#read in info about samples (i.e., treatments) 
sample_info<- read.csv("sample_info.csv")

#filter by genus 
samp_info_acr<- sample_info%>%
  filter(genus == "acr")%>%select(treatment, coral_id, genus)
samp_info_por<- sample_info%>%
  filter(genus == "por")%>%select(treatment, coral_id, genus)
###################### NOT AVERAGED Fv/Fm ###################################### #####
#filter acr by genus and date, doing do this to average replicate fv/fm values from 1 timepoint
acr_only <- combined %>%
  filter(genus == "acr")
acr_only_20230603 <- acr_only %>%
  filter(date == 20230603)
acr_only_20230619 <- acr_only %>%
  filter(date == 20230619)

#filter por by date
por_only <- combined %>%
  filter(genus == "por")
por_only_20230603 <- por_only %>%
  filter(date == 20230603)
por_only_20230619 <- por_only %>%
  filter(date == 20230619)


acr_only_full<- left_join(acr_only, samp_info_acr, by = "coral_id")
view(acr_only_full)
acr_only_full<- acr_only_full%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
ggplot(acr_only_full, aes(x = treatment, y = fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

por_only_full<- left_join(por_only, samp_info_por, by = "coral_id")
view(por_only_full)
por_only_full<- por_only_full%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
ggplot(por_only_full, aes(x = treatment, y = fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

combined_full<-rbind(acr_only_full, por_only_full)%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
combined_full<- combined_full%>%select(-genus.y)
combined_full<- combined_full%>%rename(genus = genus.x)

write.csv(combined_full, 'PAM/Output/all_fvfm.csv')
###################### AVERAGING FV/FM ######################################### #####
#acr average 
acr_avg_20230603 <- acr_only_20230603 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))
acr_avg_20230619 <- acr_only_20230619 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))

#combining averaged acr data for timepoint 1 with sample info 
acr_full_20230603<- left_join(acr_avg_20230603, samp_info_acr, by = "coral_id")
acr_full_20230603<- acr_full_20230603%>%mutate(date = 20230603)
view(acr_full_20230603)
#combining averaged acr data for timepoint 2 with sample info 
acr_full_20230619<- left_join(acr_avg_20230619, samp_info_acr, by = "coral_id")
acr_full_20230619<- acr_full_20230619%>%mutate(date = 20230619)
view(acr_full_20230619)

#por average
por_avg_20230603 <- por_only_20230603 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))
por_avg_20230619 <- por_only_20230619 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))

#combining averaged por data for timepoint 1 with sample info 
por_full_20230603<- left_join(por_avg_20230603, samp_info_por, by = "coral_id")
por_full_20230603<- por_full_20230603%>%mutate(date = 20230603)
view(por_full_20230603)
#combining averaged por data for timepoint 2 with sample info 
por_full_20230619<- left_join(por_avg_20230619, samp_info_por, by = "coral_id")
por_full_20230619<- por_full_20230619%>%mutate(date = 20230619)
view(por_full_20230619)

#combining all averaged fv/fm data
final_PAM<- rbind(acr_full_20230603, acr_full_20230619, por_full_20230603, por_full_20230619 )
final_PAM<- final_PAM%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

write.csv(final_PAM, 'PAM/Output/average_fvfm.csv')

###################### VISUALIZING AVG FV/FM POR & ACR ######################### #####
#read in data 
average<- read.csv("PAM/Output/average_fvfm.csv")%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
view(average)

ggplot(average, aes(x = treatment, y = average_fv_fm, fill = date)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ genus)

ggplot(average, aes(x = date, y = average_fv_fm, color = genus)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('timepoint')+
  facet_wrap(~ treatment, scales = "free")

ggplot(average, aes(x = genus, y = average_fv_fm, color = date)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('genus')+
  facet_wrap(~ treatment, scales = "free")

ggplot(average, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ genus)

ggplot(average, aes(x = treatment, y = average_fv_fm, color = genus)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

###################### AVG POR ONLY ############################################ #####

final_POR<- rbind( por_full_20230603, por_full_20230619)

final_POR<- final_PAM%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
ggplot(final_POR, aes(x = date, y = average_fv_fm, color = treatment)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('timepoint')

ggplot(final_POR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

ggplot(final_POR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

###################### AVG ACR ONLY ############################################ #####
final_ACR<- rbind(acr_full_20230603, acr_full_20230619)
final_ACR<- final_ACR%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

ggplot(final_ACR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)



























data<- read.csv("PAM/Output/all_fvfm.csv")%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
view(data)
ggplot(data, aes(x = treatment, y = fv_fm, fill = genus)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

ggplot(data, aes(x = treatment, y = fv_fm, fill = date)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ genus)








