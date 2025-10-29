# Calculate surface areas adjusted for wound removal
# For use in normalizing post-wound respirometry measurements
# Method: Final SA (from wax dipping) - Wound SA = Effective SA

library(tidyverse)
library(janitor)

# Read final surface areas (from wax dipping)
final_SA <- read.csv("data/processed/surface_area/final_surface_areas.csv") %>%
  clean_names() %>%
  select(coral_number, csa_cm2) %>%
  rename(coral_id = coral_number, final_SA_cm2 = csa_cm2)

# Read wound areas
wound_areas <- read.csv("data/processed/wound_areas.csv") %>%
  select(coral_id, wound_area_cm2)

# Read sample info for treatments
sample_info <- read.csv("data/metadata/sample_info.csv") %>%
  select(coral_id, genus, treatment)

# Calculate adjusted surface areas
# Approach: Since we only have final SA measurements (after experiment),
# we need to use final SA as a proxy for both initial and post-wound SA

adjusted_SA <- final_SA %>%
  left_join(wound_areas, by = "coral_id") %>%
  left_join(sample_info, by = "coral_id") %>%
  mutate(
    # For initial timepoint: use final SA (best approximation we have)
    initial_SA_cm2 = final_SA_cm2,

    # For post-wound timepoints: final SA - wound area
    # This assumes wound hasn't regenerated significantly
    postwound_SA_cm2 = final_SA_cm2 - wound_area_cm2,

    # Ensure no negative values
    postwound_SA_cm2 = ifelse(postwound_SA_cm2 < 0, final_SA_cm2 * 0.9, postwound_SA_cm2)
  )

# Summary statistics
summary_stats <- adjusted_SA %>%
  group_by(genus, treatment) %>%
  summarize(
    n = n(),
    mean_final_SA = mean(final_SA_cm2, na.rm = TRUE),
    sd_final_SA = sd(final_SA_cm2, na.rm = TRUE),
    mean_wound_area = mean(wound_area_cm2, na.rm = TRUE),
    mean_postwound_SA = mean(postwound_SA_cm2, na.rm = TRUE),
    pct_reduction = (mean_wound_area / mean_final_SA) * 100,
    .groups = "drop"
  )

cat("Surface area adjustments calculated\n\n")
cat("Summary by genus and treatment:\n")
print(summary_stats, n = 20)

# Save adjusted surface areas
write.csv(adjusted_SA, "data/processed/surface_area/adjusted_surface_areas.csv", row.names = FALSE)

cat("\n✓ Adjusted surface areas saved to data/processed/surface_area/adjusted_surface_areas.csv\n")

# Create timepoint-specific files for easy integration with existing scripts
# Initial timepoint (use final SA as proxy)
initial_SA <- adjusted_SA %>%
  select(coral_id, genus, treatment, initial_SA_cm2) %>%
  rename(SA_cm2 = initial_SA_cm2)
write.csv(initial_SA, "data/processed/surface_area/initial_SA.csv", row.names = FALSE)

# Post-wound timepoints (use adjusted SA)
postwound_SA <- adjusted_SA %>%
  select(coral_id, genus, treatment, postwound_SA_cm2) %>%
  rename(SA_cm2 = postwound_SA_cm2)
write.csv(postwound_SA, "data/processed/surface_area/postwound_SA.csv", row.names = FALSE)

cat("✓ Timepoint-specific SA files created:\n")
cat("  - data/processed/surface_area/initial_SA.csv\n")
cat("  - data/processed/surface_area/postwound_SA.csv\n")

# Publication-quality figure
library(ggplot2)

# Define treatment labels
treatment_labels <- c("0" = "Control", "1" = "Small Wound", "2" = "Large Wound")
genus_labels <- c("acr" = "Acropora pulchra", "por" = "Porites sp.")

p <- ggplot(adjusted_SA, aes(x = as.factor(treatment), y = final_SA_cm2, fill = as.factor(treatment))) +
  geom_boxplot(outlier.shape = 21, outlier.size = 2, alpha = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  facet_wrap(~ genus, scales = "free_y",
             labeller = labeller(genus = genus_labels)) +
  scale_fill_manual(
    values = c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01"),
    labels = treatment_labels,
    name = "Treatment"
  ) +
  scale_x_discrete(labels = treatment_labels) +
  labs(
    title = "Final Surface Area by Wound Treatment",
    subtitle = "Measured by wax-dipping method after 23 days",
    x = "",
    y = expression(paste("Surface Area (", cm^2, ")"))
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 10, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none",
    strip.background = element_rect(fill = "gray95", color = "black"),
    strip.text = element_text(face = "bold.italic", size = 11),
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )

ggsave("reports/Figures/surface_area_by_treatment.png", p,
       width = 9, height = 5, dpi = 300, bg = "white")

cat("\n✓ Surface area plot saved to reports/Figures/surface_area_by_treatment.png\n")
