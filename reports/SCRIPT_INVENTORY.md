# Script Inventory - Coral Wound Respiration Analysis

**Last Updated:** October 28, 2023

## Active Scripts (in order of execution)

### Data Processing Scripts

| Script | Purpose | Outputs |
|--------|---------|---------|
| `01_process_growth.R` | Process buoyant weight growth data | `growth_summary.csv`, growth figures |
| `02_process_pam.R` | Process PAM fluorometry data | `pam_summary.csv`, PAM figures |
| `02b_calculate_wound_areas.R` | Calculate wound surface areas | `wound_areas.csv` |
| `03_process_surface_area.R` | Process wax-dipping surface area data | `final_surface_areas.csv`, calibration curve |
| `03b_calculate_adjusted_surface_areas.R` | Calculate post-wound adjusted areas | `adjusted_surface_areas.csv` |

### Respirometry Processing

| Script | Purpose | Outputs |
|--------|---------|---------|
| `04_process_respirometry.R` | Process Porites respirometry with LoLinR | Raw Porites rates |
| `05_examine_raw_respirometry.R` | Diagnostic analysis of raw O₂ data | Diagnostic figures |
| `06_process_respirometry_final.R` | Final Porites processing with QC | `respirometry_normalized_final.csv` |
| `07_verify_timeline.R` | Verify experimental timeline | Timeline verification figures |

### Acropora Processing

| Script | Purpose | Outputs |
|--------|---------|---------|
| `08_identify_acropora_runs.R` | Identify which runs contain Acropora | Analysis output |
| `09_extract_acropora_data_v2.R` | Extract Acropora from multi-channel files | Individual coral CSV files |
| `11_process_acropora_simple.R` | Process Acropora respirometry | `acropora_rates_simple.csv` |

### Combined Analysis

| Script | Purpose | Outputs |
|--------|---------|---------|
| `12_combined_species_analysis.R` | Initial combined species analysis | Preliminary figures |
| `13_full_integrated_analysis.R` | **MAIN** - Full integrated analysis | `combined_species_normalized.csv`, all final figures |

### Utility Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `00_run_all.R` | Original pipeline runner | Legacy - use MASTER_PIPELINE.R instead |
| `analysis_functions.R` | Shared analysis functions | Loaded by other scripts |
| `DATA_CONSISTENCY_CHECK.R` | **NEW** - Verify data integrity | Run after processing |
| `MASTER_PIPELINE.R` | **NEW** - Complete pipeline runner | Run entire analysis |

## Archived Scripts

Located in `archive/scripts_backup/`:
- `09_extract_acropora_data.R` - Original extraction (replaced by v2)
- `10_process_acropora_respirometry.R` - Original processing (replaced by script 11)
- `10_process_acropora_respirometry_v2.R` - Second attempt (replaced by script 11)
- `DIAGNOSTIC_respiration.R` - Early diagnostic script
- `check_species_mapping.R` - One-time species check
- `data_audit.R` - Early data audit
- `00_test_pipeline.R` - Pipeline testing script

## RMarkdown Reports

| File | Purpose | Status |
|------|---------|--------|
| `Complete_Analysis_Both_Species.Rmd` | **MAIN** - Full integrated report | ✅ Active |
| `Complete_Analysis_Simple.Rmd` | Simplified Porites-only report | 📁 Archived |
| `Complete_Analysis_Pipeline.Rmd` | Early attempt | 📁 Archived |
| `Wound_Respiration_Analysis.Rmd` | Technical detailed report | ✅ Active |

## How to Run the Complete Analysis

### Option 1: Run Everything (Recommended)
```r
source("scripts/MASTER_PIPELINE.R")
```
This runs all scripts in order and generates all outputs.

### Option 2: Run Specific Components

#### Just Porites:
```r
source("scripts/01_process_growth.R")
source("scripts/02_process_pam.R")
source("scripts/02b_calculate_wound_areas.R")
source("scripts/03_process_surface_area.R")
source("scripts/03b_calculate_adjusted_surface_areas.R")
source("scripts/04_process_respirometry.R")
source("scripts/06_process_respirometry_final.R")
```

#### Just Acropora:
```r
source("scripts/09_extract_acropora_data_v2.R")
source("scripts/11_process_acropora_simple.R")
```

#### Combined Analysis:
```r
source("scripts/13_full_integrated_analysis.R")
```

#### Generate HTML Report:
```r
rmarkdown::render("Complete_Analysis_Both_Species.Rmd",
                  output_file = "reports/Complete_Analysis_Both_Species.html")
```

### Option 3: Check Data Consistency
```r
source("scripts/DATA_CONSISTENCY_CHECK.R")
```

## Key Outputs

### Data Files
- `data/processed/respirometry/combined_species_normalized.csv` - Main dataset
- `data/processed/respirometry/summary_table_both_species.csv` - Summary stats

### Figures
All 29 figures in `reports/Figures/`, key ones:
- `respiration_both_species.png` - Main comparison
- `peak_response_comparison.png` - Day 7 analysis
- `recovery_comparison.png` - Recovery assessment

### Reports
- `reports/Complete_Analysis_Both_Species.html` - Main report

## Notes

- All scripts assume working directory is project root
- LoLinR package required (installed from GitHub)
- Surface area normalization applied to all rates
- Quality threshold: R² > 0.85
- Wound date: May 27, 2023

## Maintenance

- Run `DATA_CONSISTENCY_CHECK.R` after any major changes
- Use `MASTER_PIPELINE.R` for full reproducibility
- Archive old scripts in `archive/scripts_backup/`
- Keep this inventory updated when adding new scripts