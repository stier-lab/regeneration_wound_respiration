# Wound-Induced Metabolic Responses in Two Coral Species

## Overview

This repository contains data and analysis code for examining metabolic responses to experimental wounding in two morphologically distinct coral species: *Porites* spp. (massive morphology) and *Acropora pulchra* (branching morphology).

## Study Details

- **Location**: CRIOBE Research Station, Moorea, French Polynesia
- **Duration**: 23-day experiment (May-June 2023)
- **Sample size**: 117 high-quality respirometry measurements (91.4% data retention)
- **Treatments**: Control, Small wound (5mm), Large wound (10mm)

## Repository Structure

```
regeneration_wound_respiration/
│
├── data/                          # All data files
│   ├── raw/                       # Original measurement files
│   │   ├── respirometry_runs/     # O₂ time-series by date
│   │   ├── chamber_volumes/       # Chamber calibrations
│   │   ├── growth/               # Buoyant weight data
│   │   └── surface_area/         # Wax-dipping measurements
│   ├── processed/
│   │   └── respirometry/
│   │       └── combined_species_final_qc.csv  # Final dataset
│   └── metadata/
│       └── sample_info.csv        # Treatment assignments
│
├── scripts/                       # Analysis pipeline
│   ├── 01-20_*.R                 # Sequential processing
│   └── analysis_functions.R      # Shared functions
│
├── reports/
│   └── Complete_Analysis_Enhanced.html  # Main results
│
├── Complete_Analysis_Enhanced.Rmd  # Analysis document
│
└── archive/                       # Previous versions
```

## Key Findings

1. **Species-specific responses**: *Porites* spp. showed consistent metabolic elevation in wounded colonies at Day 7 (F₂,₁₄ = 4.58, p = 0.029), while *Acropora pulchra* exhibited greater individual variation (F₂,₁₁ = 3.21, p = 0.080).

2. **Temporal dynamics**: Peak metabolic responses occurred at Day 7 post-wounding, with recovery to baseline by Day 23 (paired t-tests, all p > 0.05).

3. **Metabolic balance**: Both species maintained net heterotrophy (P:R < 1) during chamber measurements, typical for isolated respirometry conditions.

4. **Individual variation**: Substantial variation observed even among control colonies, highlighting importance of adequate replication in coral physiology studies.

## Data Quality

### Quality Control Process
Three-phase filtering removed 11 measurements (8.6%):
- **Phase 1**: Physiological limits (rates < -3 µmol/L/min)
- **Phase 2**: Probe malfunction detection
- **Phase 3**: Statistical outlier removal (IQR method)

### Technical Standards
- **R² threshold**: >0.85 for all rate calculations
- **Measurement duration**: 25-40 min dark, 10-25 min light
- **Normalization**: Surface area via wax-dipping method

## Reproducibility

### Requirements
```r
# R version 4.4.0 or higher
install.packages(c("tidyverse", "LoLinR", "knitr",
                   "rmarkdown", "patchwork"))
```

### Running the Analysis
```r
# Clone repository
git clone https://github.com/stier-lab/regeneration_wound_respiration.git

# Generate report
rmarkdown::render("Complete_Analysis_Enhanced.Rmd",
                  output_dir = "reports")
```

## Data Files

### Primary Dataset
`data/processed/respirometry/combined_species_final_qc.csv`

| Column | Description | Units |
|--------|-------------|-------|
| species | Coral species | - |
| coral_id | Individual identifier | - |
| treatment_label | Control/Small/Large Wound | - |
| timepoint | Measurement time | - |
| days_post_wound | Time since wounding | days |
| resp_rate_umol_cm2_hr | Dark respiration rate | µmol O₂ cm⁻² hr⁻¹ |
| photo_rate_umol_cm2_hr | Net photosynthesis | µmol O₂ cm⁻² hr⁻¹ |

## Statistical Analysis

- **Models**: Linear mixed-effects with coral ID as random effect
- **Treatment comparisons**: ANOVA with post-hoc Tukey tests
- **Recovery assessment**: Paired t-tests (Day 23 vs Pre-wound)
- **P:R calculation**: (11hr × P_gross) / (13hr × R)

## Citation

Manuscript in preparation. For data use, please contact:
- Adrian Stier: stier@ucsb.edu
- UC Santa Barbara, Department of Ecology, Evolution, and Marine Biology

## License

This work is licensed under CC BY 4.0. You are free to share and adapt the material with appropriate attribution.

---
**Version**: 1.0.0
**Last Updated**: October 2025
**DOI**: [To be assigned upon publication]