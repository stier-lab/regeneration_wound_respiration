# Calculate wound surface areas for different treatments
# Based on experimental design:
# - Unwounded: No injury
# - Small Wound: 8mm branch cut (Acropora) or 1/4" circular wound (Porites)
# - Large Wound: 8mm second branch cut (Acropora) or 1/2" circular wound (Porites)

library(tidyverse)
library(janitor)

# Read sample information
sample_info <- read.csv("data/metadata/sample_info.csv") %>%
  clean_names()

# Define wound dimensions by treatment and species
# Wound area calculation: CSA = 2πrh + πr² (cylinder with one circular face)
# For circular wounds on Porites: approximate as flat circle (πr²)
# For branch cuts on Acropora: use cylinder formula

calculate_wound_area <- function(genus, treatment) {
  # Treatment codes: 0 = control, 1 = small wound, 2 = large wound
  if (treatment == 0) {
    return(0)
  }

  if (genus == "por") {
    # Porites: circular punch wounds
    if (treatment == 1) {
      # Small: 1/4 inch = 6.35 mm diameter
      diameter_mm <- 6.35
      radius_cm <- (diameter_mm / 2) / 10
      # Approximate as circular area
      wound_area <- pi * radius_cm^2

    } else if (treatment == 2) {
      # Large: 1/2 inch = 12.7 mm diameter
      diameter_mm <- 12.7
      radius_cm <- (diameter_mm / 2) / 10
      wound_area <- pi * radius_cm^2

    } else {
      wound_area <- 0
    }

  } else if (genus == "acr") {
    # Acropora: branch cuts
    # 8mm diameter branch, assume ~10mm length cut
    if (treatment %in% c(1, 2)) {
      diameter_mm <- 8
      length_mm <- 10  # estimated cut length
      radius_cm <- (diameter_mm / 2) / 10
      height_cm <- length_mm / 10
      # Cylinder surface area: 2πrh + πr² (curved surface + one end)
      wound_area <- 2 * pi * radius_cm * height_cm + pi * radius_cm^2

    } else {
      wound_area <- 0
    }

  } else {
    wound_area <- 0
  }

  return(wound_area)
}

# Calculate wound areas for all samples
wound_areas <- sample_info %>%
  rowwise() %>%
  mutate(wound_area_cm2 = calculate_wound_area(genus, treatment)) %>%
  ungroup() %>%
  select(coral_id, genus, treatment, wound_area_cm2)

# Summary by treatment
wound_summary <- wound_areas %>%
  group_by(genus, treatment) %>%
  summarize(
    n = n(),
    mean_wound_area = mean(wound_area_cm2),
    .groups = "drop"
  )

print("Wound areas calculated:")
print(wound_summary)

# Save wound areas
write.csv(wound_areas, "data/processed/wound_areas.csv", row.names = FALSE)

cat("\n✓ Wound areas calculated and saved to data/processed/wound_areas.csv\n")
cat("\nSummary by treatment:\n")
print(wound_summary)

# Expected values for reference:
# Porites small (1/4" = 6.35mm): π × (0.3175cm)² ≈ 0.32 cm²
# Porites large (1/2" = 12.7mm): π × (0.635cm)² ≈ 1.27 cm²
# Acropora (8mm branch): 2π(0.4)(1.0) + π(0.4)² ≈ 3.02 cm²

cat("\nExpected wound areas:\n")
cat("  Porites small (1/4\" circular): ~0.32 cm²\n")
cat("  Porites large (1/2\" circular): ~1.27 cm²\n")
cat("  Acropora branch cut (8mm × 10mm): ~3.02 cm²\n")
