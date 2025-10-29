library(tidyverse)
library(readxl)
library(janitor)
library(ggplot2)

# Suppress automatic plotting to prevent Rplots.pdf
pdf(NULL)

calibration<- read.csv('data/raw/surface_area/20230712_wax_calibration.csv')%>%clean_names()%>%
  mutate(wax_weight_g = postwax_weight_g - prewax_weight_g)%>%
  mutate(cal_radius_mm = diameter_mm / 2)%>%
  mutate(cal_radius_cm = cal_radius_mm /10)%>%
  mutate(height_cm = height_mm / 10)%>%
  mutate(CSA_cm2= ((2*3.14*cal_radius_cm*height_cm) + 3.14*(cal_radius_cm)^2)) #curved surface area (CSA) = 2piRH + piR^2 (one area of circle for top of coral)

#calculate the curve coefficients for slope and intercept to apply as the standard
stnd.curve <- lm(CSA_cm2~wax_weight_g, data=calibration)

# Publication-quality calibration curve
p_cal <- ggplot(calibration, aes(x = wax_weight_g, y = CSA_cm2)) +
  geom_point(size = 3, color = "#2E86AB", alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "#A23B72", fill = "#A23B72", alpha = 0.2) +
  labs(
    title = "Wax Dipping Calibration Curve",
    subtitle = paste0("R² = ", round(summary(stnd.curve)$r.squared, 4)),
    x = "Wax Weight (g)",
    y = expression(paste("Surface Area (", cm^2, ")"))
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11, color = "black"),
    panel.grid.major = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )
ggsave("reports/Figures/wax_calibration_curve.png", p_cal, width = 6, height = 5, dpi = 300, bg = "white")

cat("\n✓ Calibration curve saved to reports/Figures/wax_calibration_curve.png\n")
cat(paste0("  R² = ", round(summary(stnd.curve)$r.squared, 4), "\n"))
cat(paste0("  Slope = ", round(stnd.curve$coefficients[2], 4), "\n"))
cat(paste0("  Intercept = ", round(stnd.curve$coefficients[1], 4), "\n\n"))

#bring in the datasheet with coral samples 
smpls<- read.csv("data/raw/surface_area/WoundRespExp_WaxData.csv")%>%clean_names()%>%
#subtract postwax weight from prewax weight
  mutate(wax_weight_g = post_wax_weight_g - pre_wax_weight_g)
#Calculate surface area using the standard curve
smpls$CSA_cm2 <- stnd.curve$coefficients[2] * smpls$wax_weight_g + stnd.curve$coefficients[1]

#check the range to make sure your samples fall within the range of the standards
range(smpls$CSA_cm2)
range(calibration$CSA_cm2) # 6.944456 - 83.406250

#save the output
write.csv(smpls,"data/processed/surface_area/final_surface_areas.csv")
