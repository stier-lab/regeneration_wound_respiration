#buoyant weight conversion to skeletal mass for juvenile POR corals in respirometry experiments may-june 2023
library(tidyverse)
library(janitor)
library(ggplot2)
library(tidyr)
library(dplyr)

getwd()

# Set aragonite density constant (Jokiel 1978)
density_aragonite <- 2.93  # g/cm³

#weight
w1<- read.csv("data/raw/growth/20230527_initial.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename(initial = dry_mass_coral_g)
write.csv(w1, "data/processed/growth/initial_weight.csv")

#getting coral volume for respirometry data analysis 
v1<- read.csv("data/raw/growth/20230527_initial.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v1, "data/raw/chamber_volumes/initial_vol.csv")

#weight
w2<- read.csv("data/raw/growth/20230527_postwound.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("postwound" = "dry_mass_coral_g")
write.csv(w2, "data/processed/growth/postwound_weight.csv")

#volume
v2<- read.csv("data/raw/growth/20230527_postwound.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v2, "data/raw/chamber_volumes/postwound_vol.csv")

#weight
w3<- read.csv("data/raw/growth/20230603.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("day7" = "dry_mass_coral_g")
write.csv(w3, "data/processed/growth/day7postwound_weight.csv")

#volume
v3<- read.csv("data/raw/growth/20230603.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v3, "data/raw/chamber_volumes/day7postwound_vol.csv")

#weight
w4<- read.csv("data/raw/growth/20230619.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  select(c(coral_id, species, dry_mass_coral_g))%>%
  rename("final" = "dry_mass_coral_g")
write.csv(w4, "data/processed/growth/final_weight.csv")

#volume
v4<- read.csv("data/raw/growth/20230619.csv")%>%
  mutate(density_stopper = (air_weight_g * 0.9965)/(air_weight_g - fresh_weight_g))%>%
  mutate(density_sw = (air_weight_g - salt_weight_g)/ (air_weight_g / density_stopper))%>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw))%>%
  mutate(dry_mass_coral_g= vol_coral_cm3 * density_aragonite)%>%
  mutate(chamber_vol= 650 - vol_coral_cm3)%>%
  select(c(coral_id, species, chamber_vol))
write.csv(v4, "data/raw/chamber_volumes/final_weight.csv")

#read in weight data
w1<- read.csv("data/processed/growth/initial_weight.csv")
w2<- read.csv("data/processed/growth/postwound_weight.csv")
w3<- read.csv("data/processed/growth/day7postwound_weight.csv")
w4<- read.csv("data/processed/growth/final_weight.csv")

#filter for species 
w1_por<-w1%>%filter(species == "por")
w2_por<-w2%>%filter(species == "por")%>% select(-species)
w3_por<-w3%>%filter(species == "por")%>% select(-species)
w4_por<-w4%>%filter(species == "por")%>% select(-species)

#combine all weights
list_df<- list(w1_por, w2_por, w3_por, w4_por)
por_weights<-list_df%>%reduce(inner_join, by='coral_id')

# calculating growth (final - postwound, per methods)
growth_por<-por_weights%>%
  mutate(growth_g = final - postwound)%>%
  mutate(g_day = (growth_g/23)) #days of experiment post wounding (23 days total)

#filter sample info by genus
sampinfo<- read.csv("data/metadata/sample_info.csv")%>%
  filter(genus == "por")%>%
  select(coral_id, treatment)%>%
  mutate(treatment = as.factor(treatment))

#combine growth with sample info to standardize by initial coral weight (OLD METHOD)
full_por<- left_join(growth_por, sampinfo, by = "coral_id")%>%
  mutate(growth_g_norm = growth_g / initial)%>%
  mutate(growth_norm_day = (growth_g_norm/23))

# Plot old method (optional - commented out to avoid Rplots.pdf)
# p_old <- ggplot(full_por)+
#   geom_boxplot(aes(treatment, growth_norm_day, fill=treatment))+
#   labs(title = "Growth Rate (OLD: normalized by initial weight)")
# ggsave("reports/Figures/growth_old_method.png", p_old, width = 6, height = 4, dpi = 300)

# NEW METHOD: Normalize by final surface area (mg/cm²/day)
# Read final surface areas
final_SA <- read.csv("data/processed/surface_area/final_surface_areas.csv")%>%
  clean_names()%>%
  rename(coral_id = coral_number)%>%
  filter(coral_id %in% growth_por$coral_id)%>%  # Filter to Porites only
  select(coral_id, csa_cm2)

# Calculate growth rate in mg/cm²/day
growth_por_SA <- growth_por %>%
  left_join(sampinfo, by = "coral_id")%>%
  left_join(final_SA, by = "coral_id")%>%
  mutate(growth_mg = growth_g * 1000)%>%  # Convert g to mg
  mutate(mg_cm2_day = growth_mg / (23 * csa_cm2))  # mg / (days × cm²)

# Save both versions
write.csv(full_por, "data/processed/growth/growth_weight_normalized.csv", row.names = FALSE)
write.csv(growth_por_SA, "data/processed/growth/growth_SA_normalized.csv", row.names = FALSE)

# Publication-quality figure
# Define treatment labels for clarity
treatment_labels <- c("0" = "Control", "1" = "Small Wound", "2" = "Large Wound")

p_new <- ggplot(growth_por_SA, aes(x = as.factor(treatment), y = mg_cm2_day, fill = as.factor(treatment))) +
  geom_boxplot(outlier.shape = 21, outlier.size = 2, alpha = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 2) +
  scale_fill_manual(
    values = c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01"),
    labels = treatment_labels,
    name = "Treatment"
  ) +
  scale_x_discrete(labels = treatment_labels) +
  labs(
    title = "Calcification Rate by Wound Treatment",
    subtitle = "Porites sp. - 23 days post-wounding",
    y = expression(paste("Calcification Rate (mg ", cm^-2, " ", day^-1, ")")),
    x = ""
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11, color = "black"),
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )

ggsave("reports/Figures/growth_SA_normalized.png", p_new,
       width = 7, height = 5, dpi = 300, bg = "white")

cat("\n✓ Growth rates calculated with both methods:\n")
cat("  OLD: growth_weight_normalized.csv (dimensionless ratio)\n")
cat("  NEW: growth_SA_normalized.csv (mg/cm²/day)\n")
cat("\nNEW METHOD follows published methods:\n")
cat("  - Normalized by final surface area (from wax dipping)\n")
cat("  - Units: mg/cm²/day\n")
cat("  - Growth calculated from postwound to final (23 days)\n")
