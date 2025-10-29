library(tidyverse)
library(readxl)
library(janitor)

calibration<- read.csv('Surface_Area/Data/20230712_wax_calibration.csv')%>%clean_names()%>%
  mutate(wax_weight_g = postwax_weight_g - prewax_weight_g)%>%
  mutate(cal_radius_mm = diameter_mm / 2)%>%
  mutate(cal_radius_cm = cal_radius_mm /10)%>%
  mutate(height_cm = height_mm / 10)%>%
  mutate(CSA_cm2= ((2*3.14*cal_radius_cm*height_cm) + 3.14*(cal_radius_cm)^2)) #curved surface area (CSA) = 2piRH + piR^2 (one area of circle for top of coral)

#calculate the curve coefficients for slope and intercept to apply as the standard
stnd.curve <- lm(CSA_cm2~wax_weight_g, data=calibration)
plot(CSA_cm2~wax_weight_g, data=calibration)
stnd.curve$coefficients
summary(stnd.curve)$r.squared

#bring in the datasheet with coral samples 
smpls<- read.csv("Surface_area/Data/WoundRespExp_WaxData.csv")%>%clean_names()%>%
#subtract postwax weight from prewax weight
  mutate(wax_weight_g = post_wax_weight_g - pre_wax_weight_g)
#Calculate surface area using the standard curve
smpls$CSA_cm2 <- stnd.curve$coefficients[2] * smpls$wax_weight_g + stnd.curve$coefficients[1]

#check the range to make sure your samples fall within the range of the standards
range(smpls$CSA_cm2)
range(calibration$CSA_cm2) # 6.944456 - 83.406250

#save the output
write.csv(smpls,"Surface_Area/Output/final_surface_areas.csv")
