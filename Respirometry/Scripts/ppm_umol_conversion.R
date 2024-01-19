
library(tidyverse)
#ppm to umol for channels 3,4,5 
run11<- read.csv("Respirometry/Data/Runs/rawdata_ppm/20230603_run_11.csv" , header = TRUE, skip = 1)

run11_to_fix<-run11 %>% 
  filter(Channel %in% c("3", "4", "5")) %>% 
  mutate(per_air_sat= Value / ((Pressure - exp(52.57 - 6690.9 / (273.15 + Temp) - 4.681 * log(273.15 + Temp))) / 1013) * 100 / 0.2095 / (48.998 - 1.335 * Temp + 0.02755 * Temp^2 - 0.000322 * Temp^3 + 0.000001598 * Temp^4) / 32 * 22.414)