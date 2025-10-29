# Coral Wound Healing Metabolic Response Analysis

## Overview
This repository contains the complete analysis pipeline for investigating metabolic responses to experimental wounding in two coral species: *Porites spp.* and *Acropora pulchra*.

**Study Location:** CRIOBE Research Station, Moorea, French Polynesia
**Study Period:** May-June 2023
**Principal Investigator:** Adrian Stier Lab

[![Status](https://img.shields.io/badge/Status-Analysis%20Complete-success)]()
[![R](https://img.shields.io/badge/R-4.5+-blue)]()
[![QC](https://img.shields.io/badge/Quality%20Control-Applied-green)]()

## Key Findings
After comprehensive quality control (11 measurements excluded, 8.6% of data):
- Both coral species show **moderate metabolic responses** to wounding
- *Porites spp.* exhibits **consistent, predictable responses** with wound effects at Day 7
- *Acropora pulchra* shows **more variable, colony-specific responses**
- Both species demonstrate **substantial recovery by Day 23** post-wounding
- Control groups remain stable after outlier removal

## Repository Structure

```
regeneration_wound_respiration/
├── data/
│   ├── raw/                       # Original respirometry and measurement data
│   │   ├── respirometry_runs/     # O₂ time series by date
│   │   └── surface_area/          # Wax dipping measurements
│   └── processed/
│       ├── respirometry/
│       │   ├── combined_species_final_qc.csv  # ⭐ FINAL DATASET (use this)
│       │   ├── acropora_rates_simple.csv      # Acropora processing
│       │   ├── respirometry_normalized_final.csv # Porites processing
│       │   └── [QC documentation files]
│       └── surface_area/           # Calculated surface areas
│
├── scripts/
│   ├── MASTER_PIPELINE.R          # ⭐ Complete pipeline (run this)
│   ├── 00_run_all.R               # Alternative full pipeline
│   ├── 01-06_[processing].R       # Data processing steps
│   ├── 09_extract_acropora_data_v2.R # Acropora extraction
│   ├── 11_process_acropora_simple.R  # Acropora analysis
│   ├── 13_full_integrated_analysis.R # Combined species analysis
│   ├── 15_clean_and_reanalyze.R     # Quality control implementation
│   ├── 16_outlier_trace_analysis.R   # Probe issue detection
│   ├── 17_final_quality_control.R    # Final QC application
│   └── analysis_functions.R          # Shared functions
│
├── figures/
│   ├── complete_analysis_summary.png  # Main results visualization
│   └── outlier_identification.png     # QC visualization
│
├── reports/                        # Analysis documentation
│   ├── FINAL_QC_SUMMARY.md       # ⭐ Complete QC documentation
│   └── [other documentation]      # Process documentation
│
├── Complete_Analysis_Final_QC.html    # ⭐ MAIN RESULTS REPORT (view this)
├── Complete_Analysis_Enhanced.Rmd     # Report source code
│
└── archive/                        # Archived intermediate files
```

## Quick Start

### 1. View Results
```bash
# Open the main report in your browser
open Complete_Analysis_Final_QC.html

# Review quality control documentation
open reports/FINAL_QC_SUMMARY.md
```

### 2. Use Final Data
```r
# Load the quality-controlled dataset
data <- read.csv("data/processed/respirometry/combined_species_final_qc.csv")

# Dataset contains 118 high-quality measurements:
# - 67 Porites spp. measurements
# - 51 Acropora pulchra measurements
```

### 3. Reproduce Analysis
```r
# Option 1: Run complete pipeline from raw data
source("scripts/MASTER_PIPELINE.R")

# Option 2: Generate HTML report
rmarkdown::render("Complete_Analysis_Enhanced.Rmd")
```

## Experimental Design

| Parameter | Value |
|-----------|-------|
| **Species** | *Porites spp.* and *Acropora pulchra* |
| **Total Corals** | 36 (18 per species) |
| **Treatments** | Control, Small wound (6.35 mm), Large wound (12.7 mm) |
| **Replication** | 6 colonies per treatment per species |
| **Timepoints** | Pre-wound, Day 1, Day 7, Day 23 post-wounding |
| **Measurements** | Dark respiration, photosynthesis, surface area |

## Data Quality Control

### QC Process
Comprehensive quality control identified and excluded problematic measurements:

1. **Phase 1:** Physiological filtering
   - Removed 6 Acropora measurements with rates < -3 µmol/L/min
   - These rates are physiologically impossible for corals

2. **Phase 2:** Probe issue detection
   - Removed 2 measurements with extreme values despite high R²
   - Removed 2 measurements showing O₂ production during dark periods

### Final Dataset
- **Original:** 128 measurements
- **After QC:** 117 measurements (91.4% retained)
- **Excluded:** 11 measurements (8.6%)

## Key Results Summary

### Respiration Rates (µmol O₂ cm⁻² hr⁻¹)

#### Day 7 (Peak Response)
| Species | Treatment | Mean ± SE | n |
|---------|-----------|-----------|---|
| *Porites spp.* | Control | -0.63 ± 0.25 | 6 |
| *Porites spp.* | Small Wound | -0.27 ± 0.03 | 5 |
| *Porites spp.* | Large Wound | -0.35 ± 0.04 | 6 |
| *Acropora pulchra* | Control | 1.48 ± 0.81 | 5 |
| *Acropora pulchra* | Small Wound | 0.22 ± 0.03 | 5 |
| *Acropora pulchra* | Large Wound | 0.21 ± 0.01 | 5 |

### Recovery (Day 23)
Both species showed substantial recovery, returning close to baseline metabolic rates in most treatments.

## Methods

### Respirometry
- **Dark respiration:** 25-40 min after lights off
- **Photosynthesis:** 10-25 min during light phase
- **Quality threshold:** R² > 0.85 for linear regression fits
- **Chamber volumes:** Individual calibrations per coral

### Surface Area
- Wax-dipping method with geometric calibration
- Post-wound adjustment: Initial SA - wound area
- Used for normalization to µmol O₂ cm⁻² hr⁻¹

### Statistical Analysis
- Linear mixed models with coral ID as random effect
- P:R ratio: (11hr × P_gross) / (13hr × R)
- Pairwise comparisons with Tukey adjustment

## Dependencies

```r
# Required R packages
library(tidyverse)    # Data manipulation and visualization
library(LoLinR)       # Respirometry rate calculations
library(lubridate)    # Date/time handling
library(patchwork)    # Plot composition
library(knitr)        # Report generation
library(rmarkdown)    # HTML report creation
```

## File Descriptions

### Primary Outputs
- `Complete_Analysis_Final_QC.html` - Interactive HTML report with all figures and statistics
- `data/processed/respirometry/combined_species_final_qc.csv` - Clean dataset for analysis
- `figures/complete_analysis_summary.png` - Publication-ready figure

### Key Scripts
- `scripts/MASTER_PIPELINE.R` - Complete pipeline from raw data to final output
- `scripts/17_final_quality_control.R` - Final QC implementation
- `scripts/13_full_integrated_analysis.R` - Integrated analysis of both species

### Documentation
- `reports/FINAL_QC_SUMMARY.md` - Detailed quality control documentation
- `QUICK_START.md` - Quick reference guide for using the repository

## Citation

If using this data or analysis, please cite:
> Stier Lab (2023). Metabolic responses to experimental wounding in *Porites spp.* and *Acropora pulchra*. CRIOBE Research Station, Moorea, French Polynesia. GitHub repository: https://github.com/[username]/regeneration_wound_respiration

## Contact

Adrian Stier Lab
CRIOBE Research Station
Moorea, French Polynesia

---
**Last Updated:** October 28, 2023
**Version:** 2.0.0 (Post-QC)
**Status:** Analysis Complete - Ready for Publication