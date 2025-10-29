#buoyant weight conversion to skeletal mass for juvenile POR corals in respirometry experiments may-june 2023
library(tidyverse)
library(janitor)
library(ggplot2)
library(tidyr)
library(dplyr)

getwd()
#weight
w1<- read.csv("Growth/Data/20230527_initial.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename(initial = dry_mass_coral_g)
write.csv(w1, "Growth/Output/initial_weight.csv")

#getting coral volume for respirometry data analysis 
v1<- read.csv("Growth/Data/20230527_initial.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v1, "Respirometry/Data/chamber_volumes/initial_vol.csv")

#weight
w2<- read.csv("Growth/Data/20230527_postwound.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("postwound" = "dry_mass_coral_g")
write.csv(w2, "Growth/Output/postwound_weight.csv")

#volume
v2<- read.csv("Growth/Data/20230527_postwound.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v2, "Respirometry/Data/chamber_volumes/postwound_vol.csv")

#weight
w3<- read.csv("Growth/Data/20230603.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("day7" = "dry_mass_coral_g")
write.csv(w3, "Growth/Output/day7postwound_weight.csv")

#volume
v3<- read.csv("Growth/Data/20230603.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v3, "Respirometry/Data/chamber_volumes/day7postwound_vol.csv")

#weight
w4<- read.csv("Growth/Data/20230619.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("final" = "dry_mass_coral_g")
write.csv(w4, "Growth/Output/final_weight.csv")

#volume
v4<- read.csv("Growth/Data/20230619.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v4, "Respirometry/Data/chamber_volumes/final_weight.csv")

#read in weight data
w1<- read.csv("Growth/Output/initial_weight.csv")
w2<- read.csv("Growth/Output/postwound_weight.csv")
w3<- read.csv("Growth/Output/day7postwound_weight.csv")
w4<- read.csv("Growth/Output/final_weight.csv")

#filter for species 
w1_por<-w1%>%filter(species == "por")
w2_por<-w2%>%filter(species == "por")%>% select(-species)
w3_por<-w3%>%filter(species == "por")%>% select(-species)
w4_por<-w4%>%filter(species == "por")%>% select(-species)

#combine all weights
list_df<- list(w1_por, w2_por, w3_por, w4_por)
por_weights<-list_df%>%reduce(inner_join, by='coral_id')

# calculating growth (final - initial)
growth_por<-por_weights%>%mutate(growth_g = final - postwound)%>%
  mutate(g_day = (growth_g/23)) #days of experiment post wounding

#filter sample info by genus 
sampinfo<- read.csv("sample_info.csv")%>%
  filter(genus == "por")%>%
  select(coral_id, treatment)%>%
  mutate(treatment = as.factor(treatment))

#combine growth with sample info to standardize by initial coral weight
full_por<- left_join(growth_por, sampinfo, by = "coral_id")%>%
  mutate(growth_g_norm = growth_g / initial)%>%
  mutate(growth_norm_day = (growth_g_norm/23))

#plot
ggplot(full_por)+
  geom_boxplot(aes(treatment, growth_norm_day, fill=treatment))
