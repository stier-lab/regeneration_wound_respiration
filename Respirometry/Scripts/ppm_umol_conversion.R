install.packages("respR")
library(tidyverse)
library(respR)
#ppm to umol for channels 3,4,5 
setwd("/Volumes/Stier_Lab/regeneration_wound_respiration/Respirometry/Data/Runs")
run11_ppm<- read.csv("rawdata_ppm/20230603_run_11.csv" , header = TRUE, skip = 1)
run_11_umol<- read.csv("20230603/20230603_run_11.csv", header = TRUE, skip = 1)


# Convert a numeric value to units which require t, S and P
convert_DO(2.639, from = "ppm", to = "umol/L", S = 33, t = 28.561, P= 1.014)

convert_DO(47.249, from = "ppm", to = "umol/L", S = 33, t = 28.561, P= 1.014) # time 0

convert_DO(46.999, from = "ppm", to = "umol/L", S = 33, t = 28.432, P= 1.014) # mid point

convert_DO(46.451, from = "ppm", to = "umol/L", S = 33, t = 28.383, P= 1.014) # end 



convert_DO(1476.521, from = "umol/L", to = "ppm", S = 33, t = 28.561, P= 1.014) 



run11_to_fix<-run11 %>% 
  filter(Channel %in% c("3", "4", "5")) %>% 
  mutate(per_air_sat= Value / ((Pressure - exp(52.57 - 6690.9 / (273.15 + Temp) - 4.681 * log(273.15 + Temp))) / 1013) * 100 / 0.2095 / (48.998 - 1.335 * Temp + 0.02755 * Temp^2 - 0.000322 * Temp^3 + 0.000001598 * Temp^4) / 32 * 22.414)
