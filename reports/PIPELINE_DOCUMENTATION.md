# Complete Analysis Pipeline Documentation
## Wound Effects on Respiration in Porites and Acropora pulchra

**Project:** Moorea 2023 Coral Regeneration Wound Respiration Study
**Last Updated:** 2025-10-27
**Status:** Production Ready

---

## Table of Contents
1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Data Processing Pipeline](#data-processing-pipeline)
4. [Step-by-Step Workflow](#step-by-step-workflow)
5. [Running the Complete Analysis](#running-the-complete-analysis)
6. [Outputs and Interpretation](#outputs-and-interpretation)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This pipeline processes physiological measurements from coral wounding experiments to quantify the metabolic costs of tissue repair. The analysis examines how different wound types affect:

- **Respiration rates** (O₂ consumption, dark phase)
- **Photosynthesis rates** (O₂ production, light phase)
- **Growth rates** (buoyant weight method)
- **Photosynthetic efficiency** (Fv/Fm via PAM fluorometry)

### Experimental Design
- **Species:** Porites sp. and Acropora pulchra
- **Sample size:** 36 corals (18 per species)
- **Treatments:** Control (0), Wound Type 1 (1), Wound Type 2 (2)
- **Replication:** 6 corals per treatment per species
- **Duration:** 23 days post-wounding
- **Timepoints:** 4 measurement periods (Day 0, 1, 7, 23)

---

## Project Structure

```
regeneration_wound_respiration/
│
├── README.md                              # Project description
├── sample_info.csv                        # Master metadata file
├── analysis_functions.R                   # Reusable R functions
├── data_audit.R                           # Data completeness check script
├── Wound_Respiration_Analysis.Rmd         # Main analysis document
├── PIPELINE_DOCUMENTATION.md              # This file
├── DATA_AUDIT_SUMMARY.md                  # Data audit results
│
├── Growth/                                # Skeletal growth data
│   ├── Data/
│   │   ├── 20230527_initial.csv          # Pre-experiment buoyant weights
│   │   ├── 20230527_postwound.csv        # Post-wounding weights
│   │   ├── 20230603.csv                  # Day 7 weights
│   │   └── 20230619.csv                  # Final weights
│   ├── Scripts/
│   │   └── mass_volume.R                 # Converts buoyant weight → dry mass
│   └── Output/
│       ├── initial_weight.csv
│       ├── postwound_weight.csv
│       ├── day7postwound_weight.csv
│       └── final_weight.csv
│
├── PAM/                                   # Photosynthetic efficiency data
│   ├── Data/
│   │   ├── 20230603_pam.csv              # Day 7 Fv/Fm measurements
│   │   └── 20230619_pam.csv              # Day 23 Fv/Fm measurements
│   ├── Scripts/
│   │   └── fvfm.R                        # Averages replicate measurements
│   └── Output/
│       ├── all_fvfm.csv                  # All raw measurements
│       └── average_fvfm.csv              # Averaged per coral
│
├── Respirometry/                          # O₂ exchange rate data
│   ├── Data/
│   │   ├── chamber_volumes/              # Chamber volumes for normalization
│   │   │   ├── initial_vol.csv
│   │   │   ├── postwound_vol.csv
│   │   │   ├── day7postwound_vol.csv
│   │   │   └── final_weight.csv
│   │   └── Runs/
│   │       ├── 20230525/                 # Test runs
│   │       ├── 20230526/                 # Pre-wound
│   │       │   ├── *.csv                 # Raw multi-channel files
│   │       │   └── Porites/              # Processed individual corals
│   │       ├── 20230528/                 # Day 1 post-wound
│   │       ├── 20230603/                 # Day 7
│   │       └── 20230619/                 # Day 23
│   ├── Scripts/
│   │   ├── Resp.R                        # Extract individual coral time series
│   │   ├── PRrates.R                     # Calculate O₂ exchange rates
│   │   └── ppm_umol_conversion.R         # Unit conversions
│   └── Output/
│       └── Porites/
│           ├── Respiration/              # Dark phase rates
│           │   ├── 20230526/
│           │   ├── 20230528/
│           │   ├── 20230603/
│           │   └── 20230619/
│           └── Photosynthesis/           # Light phase rates
│               ├── 20230526/
│               ├── 20230528/
│               ├── 20230603/
│               └── 20230619/
│
├── Surface_Area/                          # Wax dipping surface area
│   ├── Data/
│   │   ├── 20230712_wax_calibration.csv  # Geometric standards
│   │   └── WoundRespExp_WaxData.csv      # Coral sample measurements
│   ├── Scripts/
│   │   └── SA.calculations.R             # Calibration curve & SA calc
│   └── Output/
│       └── final_surface_areas.csv
│
├── Figures/                               # Generated plots
│   ├── growth_by_treatment.png
│   ├── growth_normalized.png
│   ├── fvfm_timeseries.png
│   ├── fvfm_by_species.png
│   ├── respiration_timeseries.png
│   ├── photosynthesis_timeseries.png
│   └── O2_rates_combined.png
│
└── similar analysis/                      # Reference Acropora project
    └── Acropora_Regeneration-main/        # Template for statistical methods
```

---

## Data Processing Pipeline

### Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    RAW DATA COLLECTION                          │
├─────────────────────────────────────────────────────────────────┤
│  • Buoyant Weights (air, fresh, salt water)                    │
│  • PAM Fluorometry (F0, Fm measurements, 3 replicates)         │
│  • Multi-channel Respirometry (O₂ logger, 10 channels/run)     │
│  • Wax Dipping (pre/post wax weights)                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               STEP 1: DATA VALIDATION & AUDIT                   │
├─────────────────────────────────────────────────────────────────┤
│  Script: data_audit.R                                           │
│  • Check file completeness                                       │
│  • Verify sample sizes                                          │
│  • Identify missing data                                        │
│  Output: DATA_AUDIT_SUMMARY.md                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│           STEP 2: PROCESS GROWTH DATA                           │
├─────────────────────────────────────────────────────────────────┤
│  Script: Growth/Scripts/mass_volume.R                           │
│  Input: 20230527_initial.csv, postwound.csv, 20230603.csv,     │
│         20230619.csv                                            │
│  Process:                                                        │
│    1. Calculate stopper density                                 │
│    2. Calculate seawater density                                │
│    3. Calculate coral volume                                    │
│    4. Calculate dry skeletal mass                               │
│    5. Calculate chamber volumes (650 mL - coral volume)         │
│    6. Calculate growth rates                                    │
│  Output: Growth/Output/*.csv,                                   │
│          Respirometry/Data/chamber_volumes/*.csv                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│          STEP 3: PROCESS PAM DATA                               │
├─────────────────────────────────────────────────────────────────┤
│  Script: PAM/Scripts/fvfm.R                                     │
│  Input: 20230603_pam.csv, 20230619_pam.csv                      │
│  Process:                                                        │
│    1. Calculate Fv/Fm = (Fm - F0) / Fm                          │
│    2. Average 3 replicate measurements per coral                │
│    3. Join with treatment assignments                           │
│  Output: PAM/Output/all_fvfm.csv, average_fvfm.csv             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│        STEP 4: PROCESS SURFACE AREA DATA                        │
├─────────────────────────────────────────────────────────────────┤
│  Script: Surface_Area/Scripts/SA.calculations.R                 │
│  Input: 20230712_wax_calibration.csv,                           │
│         WoundRespExp_WaxData.csv                                │
│  Process:                                                        │
│    1. Calculate wax weight gained                               │
│    2. Calculate CSA of geometric standards                      │
│    3. Fit linear regression (CSA ~ wax_weight)                  │
│    4. Apply calibration to coral samples                        │
│  Output: Surface_Area/Output/final_surface_areas.csv            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│       STEP 5: PROCESS RESPIROMETRY DATA                         │
├─────────────────────────────────────────────────────────────────┤
│  Script 5a: Respirometry/Scripts/Resp.R                         │
│  Input: Runs/[date]/[date]_run_[#].csv                          │
│  Process:                                                        │
│    1. Read multi-channel O₂ logger file                         │
│    2. Map channels to coral IDs (via trial datasheets)          │
│    3. Split data by coral                                       │
│    4. Save individual coral time series                         │
│  Output: Runs/[date]/[Genus]/[coral_id].csv                     │
│                                                                  │
│  Script 5b: Respirometry/Scripts/PRrates.R                      │
│  Input: Runs/[date]/[Genus]/[coral_id].csv                      │
│  Process:                                                        │
│    1. Filter to relevant time window (10-25 min)                │
│    2. Thin data by factor of 5                                  │
│    3. Apply rankLocReg (LoLinR package) for robust slope        │
│    4. Extract rate (slope) in µmol O₂/L/sec                     │
│    5. Normalize:                                                │
│       - Multiply by chamber volume → µmol O₂/sec                │
│       - Subtract blank rates                                    │
│       - Divide by dry mass → µmol O₂/g/hr                       │
│    6. Generate QC plots (before/after thinning)                 │
│  Output: Output/[Genus]/[Rate_Type]/[date]/rates.csv,           │
│          [coral_id].pdf                                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│        STEP 6: INTEGRATED STATISTICAL ANALYSIS                  │
├─────────────────────────────────────────────────────────────────┤
│  Script: Wound_Respiration_Analysis.Rmd                         │
│  Input: All processed CSV files from steps 2-5                  │
│  Process:                                                        │
│    1. Load and merge all datasets                               │
│    2. Exploratory data analysis (boxplots, time series)         │
│    3. Statistical modeling:                                     │
│       - Growth: lm(growth_norm ~ treatment)                     │
│       - Fv/Fm: lmer(fvfm ~ treatment*timepoint + (1|coral))    │
│       - Respiration: lmer(rate ~ treatment*time + (1|coral))    │
│    4. Pairwise comparisons (emmeans with Tukey adjustment)      │
│    5. Generate publication-quality figures                      │
│  Output: Wound_Respiration_Analysis.html,                       │
│          Figures/*.png                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Workflow

### Prerequisites

**Required R packages:**
```r
install.packages(c(
  "tidyverse",
  "lmerTest",
  "emmeans",
  "rstatix",
  "janitor",
  "ggthemes",
  "knitr",
  "kableExtra",
  "pbkrtest",
  "sjPlot",
  "cowplot",
  "patchwork",
  "rmarkdown",
  "Rmisc",
  "LoLinR"  # For respirometry rate calculations
))
```

### Workflow Steps

#### Step 0: Validate Data
```bash
cd /Users/adrianstiermbp2023/regeneration_wound_respiration
Rscript data_audit.R
```

**What it does:**
- Checks presence and completeness of all data files
- Verifies sample sizes match experimental design
- Identifies any missing measurements
- Generates `DATA_AUDIT_SUMMARY.md`

**Expected output:** "Audit completed, Data quality: Excellent"

---

#### Step 1: Process Growth Data
```bash
Rscript Growth/Scripts/mass_volume.R
```

**What it does:**
- Converts buoyant weights to dry skeletal mass using aragonite density (2.94 g/cm³)
- Calculates coral volumes for chamber volume corrections
- Computes growth rates (g/day) and size-normalized growth

**Outputs:**
- `Growth/Output/initial_weight.csv` (18 Acr + 18 Por)
- `Growth/Output/postwound_weight.csv`
- `Growth/Output/day7postwound_weight.csv`
- `Growth/Output/final_weight.csv`
- `Respirometry/Data/chamber_volumes/*.csv` (for rate normalization)

**Expected runtime:** < 10 seconds

---

#### Step 2: Process PAM Data
```bash
Rscript PAM/Scripts/fvfm.R
```

**What it does:**
- Reads raw F0 and Fm fluorescence measurements
- Calculates Fv/Fm = (Fm - F0) / Fm for each replicate
- Averages 3 technical replicates per coral per timepoint
- Joins with treatment assignments from `sample_info.csv`

**Outputs:**
- `PAM/Output/all_fvfm.csv` (108 measurements per timepoint)
- `PAM/Output/average_fvfm.csv` (36 corals × 2 timepoints)

**Expected runtime:** < 5 seconds

---

#### Step 3: Process Surface Area Data
```bash
Rscript Surface_Area/Scripts/SA.calculations.R
```

**What it does:**
- Calculates curved surface area of geometric standards
- Fits linear regression: CSA (cm²) ~ wax weight gained (g)
- Applies calibration curve to coral samples
- Validates that coral SAs fall within calibration range

**Outputs:**
- `Surface_Area/Output/final_surface_areas.csv` (36 corals)
- Regression equation printed to console
- R² value (expected: > 0.97)

**Expected runtime:** < 5 seconds

---

#### Step 4: Process Respirometry Data

**4a. Extract Individual Coral Time Series (if needed for Acropora):**
```bash
# Edit Resp.R to specify:
# - Date folder
# - Channel mapping
# - Output genus folder

Rscript Respirometry/Scripts/Resp.R
```

**What it does:**
- Reads multi-channel O₂ logger CSV
- Maps Channel 1-10 to coral IDs based on trial datasheet
- Splits data by coral_id
- Saves individual time series with columns: delta_t, value, temp, coral_id

**Note:** Porites data already processed. Only needed for Acropora.

---

**4b. Calculate O₂ Exchange Rates:**
```bash
# Edit PRrates.R to specify:
# - Date folder
# - Genus folder
# - Rate type (Respiration or Photosynthesis)
# - Time window for filtering

Rscript Respirometry/Scripts/PRrates.R
```

**What it does:**
- Filters O₂ time series to relevant phase (e.g., minutes 10-25)
- Applies LoLinR `rankLocReg` for robust rate estimation
- Normalizes rates:
  - Volume correction: rate × chamber_volume
  - Blank subtraction
  - Mass normalization: rate / dry_mass_g
- Generates QC PDFs showing fit quality

**Outputs:**
- `Respirometry/Output/[Genus]/[RateType]/[Date]/rates.csv`
- `Respirometry/Output/[Genus]/[RateType]/[Date]/[coral_id].pdf`

**Expected runtime:** ~2-5 minutes per date (18 corals + 2 blanks)

---

#### Step 5: Integrated Analysis
```bash
Rscript -e "rmarkdown::render('Wound_Respiration_Analysis.Rmd')"
```

**What it does:**
- Loads all processed data
- Merges datasets using `coral_id` and `genus` as keys
- Performs exploratory data analysis
- Runs statistical models:
  - **Growth**: `lm(growth_normalized ~ treatment)`
  - **PAM**: `lmer(average_fv_fm ~ treatment * timepoint + (1|coral_id))`
  - **Respiration**: `lmer(rate ~ treatment * timepoint + (1|coral_id))`
  - **Photosynthesis**: Similar to respiration
- Calculates pairwise comparisons with Tukey adjustment
- Generates 7 high-resolution figures
- Produces HTML report with tables and statistics

**Outputs:**
- `Wound_Respiration_Analysis.html` (interactive report)
- `Figures/growth_by_treatment.png`
- `Figures/growth_normalized.png`
- `Figures/fvfm_timeseries.png`
- `Figures/fvfm_by_species.png`
- `Figures/respiration_timeseries.png`
- `Figures/photosynthesis_timeseries.png`
- `Figures/O2_rates_combined.png`

**Expected runtime:** 30-60 seconds

---

## Running the Complete Analysis

### Full Pipeline (One Command)
```bash
# Navigate to project directory
cd /Users/adrianstiermbp2023/regeneration_wound_respiration

# Run complete pipeline
Rscript Growth/Scripts/mass_volume.R && \
Rscript PAM/Scripts/fvfm.R && \
Rscript Surface_Area/Scripts/SA.calculations.R && \
Rscript -e "rmarkdown::render('Wound_Respiration_Analysis.Rmd')" && \
echo "Analysis complete! Open Wound_Respiration_Analysis.html to view results."
```

**Total runtime:** ~2-3 minutes

### View Results
```bash
# macOS
open Wound_Respiration_Analysis.html

# Linux
xdg-open Wound_Respiration_Analysis.html

# Or navigate to the file in your file browser
```

---

## Outputs and Interpretation

### Key Figures

#### 1. Growth by Treatment (`growth_by_treatment.png`)
- **X-axis:** Treatment (0=Control, 1=Wound Type 1, 2=Wound Type 2)
- **Y-axis:** Growth rate (g/day)
- **Facets:** Acropora | Porites
- **Interpretation:** Look for reduced growth in wounded corals indicating metabolic costs

#### 2. Normalized Growth (`growth_normalized.png`)
- **Y-axis:** Growth rate / initial mass
- **Purpose:** Accounts for size effects
- **Expected pattern:** If wound effect is proportional to size, patterns should be similar to Fig 1

#### 3. Fv/Fm Time Series (`fvfm_timeseries.png`)
- **X-axis:** Timepoint (Day 7, Day 23)
- **Y-axis:** Fv/Fm (photosynthetic efficiency)
- **Colors:** Treatment groups
- **Interpretation:** Healthy corals have Fv/Fm ~ 0.6-0.7. Values < 0.5 indicate stress

#### 4. Respiration Time Series (`respiration_timeseries.png`)
- **X-axis:** Timepoint (Pre-wound, Day 1, Day 7, Day 23)
- **Y-axis:** Respiration rate (µmol O₂/L/sec, negative values)
- **Interpretation:** More negative = higher O₂ consumption. Wounded corals may show elevated respiration during healing

#### 5. Photosynthesis Time Series (`photosynthesis_timeseries.png`)
- **Y-axis:** Photosynthesis rate (µmol O₂/L/sec, positive values)
- **Interpretation:** Higher values = more O₂ production. Check if photosynthesis compensates for increased respiration

#### 6. Combined O₂ Rates (`O2_rates_combined.png`)
- **Facets:** Respiration | Photosynthesis
- **Points with error bars:** Mean ± SE
- **Lines:** Connect timepoints to show trajectory
- **Use:** Compare temporal dynamics between treatments

### Statistical Output

The HTML report contains:

1. **ANOVA tables** (Type III SS)
   - Test for main effects of treatment, timepoint, and their interaction
   - F-statistics, df, p-values

2. **Pairwise comparisons** (Tukey HSD)
   - Contrasts between treatment levels
   - Adjusted p-values to control family-wise error rate
   - Effect sizes with confidence intervals

3. **Model summaries**
   - Fixed effects coefficients
   - Random effects variance components
   - Model fit statistics (R², AIC)

4. **Summary tables**
   - Mean ± SE by treatment and timepoint
   - Sample sizes
   - Range of values

---

## Troubleshooting

### Common Issues

#### Issue 1: "Package not found"
```
Error: there is no package called 'X'
```

**Solution:**
```r
install.packages("X")
```

---

#### Issue 2: "Cannot find file"
```
Error: 'path/to/file.csv' does not exist
```

**Solution:**
- Check working directory: `getwd()`
- Ensure you're in the project root directory
- Verify file path in error message matches actual location

---

#### Issue 3: "Coral ID not found in sample_info"
```
Warning: Missing coral IDs: 59, 60
```

**Solution:**
- Check that `sample_info.csv` contains entries for all coral IDs used in experiment
- Remember: coral IDs are reused between genera! Always filter by genus

---

#### Issue 4: "Regression line does not fit data well"
In respirometry rate calculation, PDFs show poor fit

**Solution:**
- Check time window filter (default: 10-25 minutes)
- Adjust `alpha` parameter in `rankLocReg()` (default: 0.5)
- Inspect raw data for anomalies (air bubbles, sensor drift)

---

#### Issue 5: "Many-to-many relationship detected"
When joining datasets

**Solution:**
- Use `coral_id + genus` as compound key:
```r
left_join(data1, data2, by = c("coral_id", "genus"))
```

---

#### Issue 6: Package conflicts (plyr vs dplyr)
```
Error: object 'n' not found
```

**Solution:**
- Load `tidyverse` BEFORE other packages
- If using `plyr` functions, use explicit namespace: `plyr::summarize()`
- Or use `conflicted` package:
```r
library(conflicted)
conflict_prefer("summarize", "dplyr")
```

---

## Data Archive and Reproducibility

### Session Info
Include in your reports:
```r
sessionInfo()
```

### Data Backup
```bash
# Create dated backup
DATE=$(date +%Y%m%d)
tar -czf ../wound_resp_backup_$DATE.tar.gz \
  --exclude='*.html' \
  --exclude='Figures/' \
  .
```

### Git Version Control (Recommended)
```bash
git init
git add *.R *.Rmd *.csv sample_info.csv
git commit -m "Initial commit: analysis scripts and metadata"
```

---

## Citation and Contact

If using this pipeline, please cite:

- **LoLinR package:** Olito, C. and White, C.R. (2020). LoLinR: Local Linear Regression for Oxygen Consumption Rate Calculation from Closed Respirometry Systems. R package version 1.0.0.

- **Buoyant weight method:** Jokiel, P.L., et al. (1978). Coral growth: buoyant weight technique. In *Coral Reefs: Research Methods*. UNESCO.

- **PAM fluorometry:** Maxwell, K., and Johnson, G.N. (2000). Chlorophyll fluorescence—a practical guide. *Journal of Experimental Botany*, 51(345), 659-668.

---

**Pipeline developed by:** Claude Code Analysis Tool
**Project PI:** [Your Name]
**Institution:** [Your Institution]
**Date:** May-June 2023 (fieldwork), October 2025 (analysis pipeline)

**Questions?** Check the `similar analysis/` folder for reference implementations.

---

*End of Pipeline Documentation*
