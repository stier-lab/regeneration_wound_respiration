# File Naming Guide
**Coral Wound Respiration Analysis Project**

This document explains the intuitive naming conventions used throughout the repository.

---

## 📁 Top-Level Structure

```
regeneration_wound_respiration/
├── scripts/          # All R code (numbered pipeline scripts)
├── data/             # All data (raw + processed + metadata)
├── reports/          # All outputs (HTML + figures + documentation)
├── archive/          # Original structure (preserved for reference)
├── README.md         # Main project documentation
└── .gitignore        # Git configuration
```

**Why this structure:**
- ✅ Clear separation of code, data, and results
- ✅ Easy to find what you need
- ✅ Standard for scientific projects
- ✅ Git-friendly

---

## 🔢 Script Naming Convention

### Pattern: `##_action_target.R`

| Script | Purpose | Naming Logic |
|--------|---------|--------------|
| `00_test_pipeline.R` | Test all scripts | `00` = utility/testing |
| `00_run_all.R` | Run complete pipeline | `00` = master control |
| `01_process_growth.R` | Process growth data | `01` = first step |
| `02_process_pam.R` | Process PAM data | `02` = second step |
| `03_process_surface_area.R` | Process surface area | `03` = third step |
| `04_extract_respirometry.R` | Extract O₂ data | `04` = optional step |
| `05_calculate_rates.R` | Calculate O₂ rates | `05` = after extraction |
| `analysis_functions.R` | Reusable functions | No number = support file |
| `data_audit.R` | Validate data | No number = utility |
| `Wound_Respiration_Analysis.Rmd` | Integrated analysis | Capital = main output |

**Naming Rules:**
- Numbers (00-99) = Pipeline order
- `00` = Master/test scripts
- `01-09` = Data processing steps
- `10+` = Analysis steps (if needed)
- No number = Support files
- Capital start = Main deliverable
- Underscores separate words
- `.R` = R script, `.Rmd` = R Markdown

---

## 📊 Data Folder Structure

### data/metadata/
**Contains:** Sample information and experimental design

| File | Description | Key Columns |
|------|-------------|-------------|
| `sample_info.csv` | Master sample metadata | coral_id, genus, treatment, wound_date |

### data/raw/
**Contains:** Original data files (never modified)

```
data/raw/
├── growth/                        # Buoyant weight measurements
│   ├── 20230527_initial.csv      # Pre-experiment weights
│   ├── 20230527_postwound.csv    # Post-wounding weights
│   ├── 20230603.csv               # Day 7 weights
│   └── 20230619.csv               # Final weights
│
├── pam/                           # PAM fluorometry data
│   ├── 20230603_pam.csv          # Day 7 Fv/Fm measurements
│   └── 20230619_pam.csv          # Day 23 Fv/Fm measurements
│
├── surface_area/                  # Wax dipping data
│   ├── 20230712_wax_calibration.csv    # Geometric standards
│   └── WoundRespExp_WaxData.csv        # Coral samples
│
├── chamber_volumes/               # Respirometer chamber volumes
│   ├── initial_vol.csv
│   ├── postwound_vol.csv
│   ├── day7postwound_vol.csv
│   └── final_weight.csv
│
└── respirometry_runs/             # Raw O₂ logger files
    ├── 20230525/                  # Test runs
    ├── 20230526/                  # Pre-wound measurements
    ├── 20230528/                  # Day 1 post-wound
    ├── 20230603/                  # Day 7
    └── 20230619/                  # Day 23 (final)
```

**Date Format:** `YYYYMMDD` (sortable, unambiguous)
**Why:** ISO 8601 standard, sorts chronologically

### data/processed/
**Contains:** Analysis outputs (can be regenerated)

```
data/processed/
├── growth/
│   ├── initial_weight.csv         # Dry skeletal mass (initial)
│   ├── postwound_weight.csv       # Post-wounding mass
│   ├── day7postwound_weight.csv   # Day 7 mass
│   └── final_weight.csv           # Final mass
│
├── pam/
│   ├── all_fvfm.csv              # All replicate measurements
│   ├── average_fvfm.csv          # Averaged per coral
│   └── fvfm.pdf                  # Visualization
│
├── surface_area/
│   └── final_surface_areas.csv   # Calculated CSA (cm²)
│
└── respirometry/
    └── Porites/                   # Organized by genus
        ├── Respiration/           # Dark phase (O₂ consumption)
        │   ├── 20230526/
        │   ├── 20230528/
        │   ├── 20230603/
        │   └── 20230619/
        └── Photosynthesis/        # Light phase (O₂ production)
            ├── 20230526/
            ├── 20230528/
            ├── 20230603/
            └── 20230619/
```

**Naming Pattern:**
- `initial`, `postwound`, `day7postwound`, `final` = Timepoint labels
- `_weight.csv` = Mass data
- `_vol.csv` = Volume data
- `all_*` = Complete dataset with replicates
- `average_*` = Summarized/averaged data
- `final_*` = Processed/calibrated values

---

## 📑 Reports Folder

```
reports/
├── Wound_Respiration_Analysis.html    # Main results (interactive)
├── analysis_results.html              # Alternative output name
│
├── Figures/                           # Publication-quality plots
│   ├── growth_by_treatment.png       # Growth rates by treatment
│   ├── growth_normalized.png         # Size-normalized growth
│   ├── fvfm_timeseries.png          # Fv/Fm over time
│   ├── fvfm_by_species.png          # Fv/Fm comparison
│   ├── respiration_timeseries.png   # O₂ consumption rates
│   ├── photosynthesis_timeseries.png # O₂ production rates
│   └── O2_rates_combined.png        # Combined P & R plot
│
├── DATA_AUDIT_SUMMARY.md             # Data completeness report
├── PIPELINE_DOCUMENTATION.md         # Complete workflow guide
├── PROJECT_SUMMARY.md                # Executive summary
└── FILES_CREATED.txt                 # File index
```

**Naming Rules:**
- `.html` = Interactive reports
- `_timeseries` = Data over time
- `_by_*` = Grouped comparisons
- `_normalized` = Size-corrected values
- `_combined` = Multiple measures in one plot
- ALL_CAPS.md = Major documentation
- lowercase_snake.png = Figure files

---

## 🗄️ Archive Folder

Contains the original folder structure before reorganization:
- `Growth/`, `PAM/`, `Respirometry/`, `Surface_Area/`
- `rawdata/`, `similar analysis/`
- `old_README.md`, `sample_info.csv`

**Purpose:** Preserve original structure for reference
**Use:** Reference only, do not modify

---

## 📐 Naming Conventions Summary

### Dates
✅ **Use:** `YYYYMMDD` format (e.g., `20230527`)
❌ **Avoid:** `MM-DD-YY`, `DD/MM/YYYY`
**Why:** Sortable, unambiguous, ISO standard

### Files
✅ **Use:** `lowercase_with_underscores.ext`
❌ **Avoid:** `CamelCase.ext`, `spaces in names.ext`
**Exception:** `Capital_For_Main_Deliverables.Rmd`

### Folders
✅ **Use:** `lowercase/`, `singular_noun/`
❌ **Avoid:** `MixedCase/`, `Spaces In Names/`

### Variables (in scripts)
✅ **Use:** `snake_case` for variables and functions
❌ **Avoid:** `camelCase`, `PascalCase`
**Why:** R community standard (tidyverse style)

### Versioning
✅ **Use:** Numbers for ordered scripts (`01_`, `02_`)
✅ **Use:** Dates for data files (`20230527_`)
✅ **Use:** Descriptive names for outputs (`final_`, `average_`)

---

## 🎯 Quick Reference

### Finding Files

**Need sample metadata?**
→ `data/metadata/sample_info.csv`

**Need raw growth data?**
→ `data/raw/growth/20230527_initial.csv`

**Need processed rates?**
→ `data/processed/respirometry/Porites/Respiration/20230526/`

**Need to run analysis?**
→ `scripts/00_run_all.R` (master script)
→ `scripts/01_process_growth.R` (individual step)

**Need results?**
→ `reports/Wound_Respiration_Analysis.html`
→ `reports/Figures/`

**Need documentation?**
→ `README.md` (start here)
→ `reports/PIPELINE_DOCUMENTATION.md` (detailed guide)

---

## ✅ File Naming Best Practices

### DO:
- ✅ Use consistent naming patterns
- ✅ Include dates in ISO format (YYYYMMDD)
- ✅ Use descriptive names (`growth_by_treatment` not `fig1`)
- ✅ Separate words with underscores
- ✅ Keep names lowercase (except main deliverables)
- ✅ Number pipeline scripts in execution order
- ✅ Use standard extensions (`.csv`, `.R`, `.Rmd`, `.md`)

### DON'T:
- ❌ Use spaces in filenames
- ❌ Use special characters (!@#$%^&*)
- ❌ Use ambiguous dates (03/04/23)
- ❌ Create deep nested folders (max 3 levels)
- ❌ Use cryptic abbreviations (grth.csv)
- ❌ Mix naming conventions
- ❌ Create duplicate files with version numbers (analysis_v2_final_FINAL.R)

---

## 🔄 Renaming Convention

If you need to rename a file, follow this pattern:

**Old:** `figure1.png`
**New:** `growth_by_treatment.png`

**Old:** `data_03_04.csv`
**New:** `20230304_measurements.csv`

**Old:** `Script Final v2.R`
**New:** `01_process_data.R`

---

## 📝 Adding New Files

When adding new files, follow these guidelines:

### New Data File
**Location:** `data/raw/[category]/`
**Name:** `YYYYMMDD_description.csv`
**Example:** `data/raw/temperature/20230527_logger_data.csv`

### New Script
**Location:** `scripts/`
**Name:** `##_action_target.R` (if pipeline) or `descriptive_name.R` (if utility)
**Example:** `scripts/06_analyze_temperature.R`

### New Figure
**Location:** `reports/Figures/`
**Name:** `measurement_type_comparison.png`
**Example:** `reports/Figures/temperature_by_treatment.png`

### New Documentation
**Location:** `reports/` or root
**Name:** `DESCRIPTIVE_TITLE.md`
**Example:** `reports/SUPPLEMENTARY_METHODS.md`

---

## 🎓 Learning the System

**For New Users:**
1. Start with `README.md` (project overview)
2. Check `scripts/` folder (numbered scripts show workflow)
3. Look in `data/metadata/` for sample information
4. Browse `reports/` for results

**For Collaborators:**
1. Read `README.md` and `reports/PIPELINE_DOCUMENTATION.md`
2. Check `scripts/00_test_pipeline.R` to verify setup
3. Run individual scripts (`01_`, `02_`, `03_`)
4. Review outputs in `data/processed/` and `reports/`

**For Future You (6 months later):**
1. Everything is named logically - no guessing
2. Scripts are numbered in execution order
3. Dates are sortable (YYYYMMDD format)
4. Documentation explains everything

---

## 📊 File Naming Examples

### Good Examples ✅

```
scripts/01_process_growth.R
data/raw/growth/20230527_initial.csv
data/processed/pam/average_fvfm.csv
reports/Figures/growth_by_treatment.png
reports/PIPELINE_DOCUMENTATION.md
```

### Bad Examples ❌

```
scripts/Script1.R                    → Use 01_process_growth.R
data/raw/Data 05-27-23.csv          → Use 20230527_measurements.csv
data/processed/output.csv           → Use growth_rates_processed.csv
reports/fig1.png                    → Use growth_by_treatment.png
reports/documentation.md            → Use PIPELINE_DOCUMENTATION.md
```

---

## 🔍 Troubleshooting File Names

**Can't find a file?**
1. Check if it's in the expected folder (raw vs processed)
2. Look for date in filename (YYYYMMDD)
3. Search by category (growth, pam, respirometry)
4. Check archive/ for original names

**File path not working?**
1. Use relative paths from project root
2. Check for typos (case-sensitive!)
3. Verify file exists: `file.exists("path/to/file")`

**Getting duplicate files?**
1. Check if original is in archive/
2. Use version control (git) instead of v1, v2, etc.
3. Delete old versions after confirming new one works

---

## 📦 Archiving Old Files

**Before archiving:**
1. Confirm new file works correctly
2. Document what changed
3. Move to `archive/` with date suffix if needed

**Example:**
```bash
# Old file working but being replaced
mv old_script.R archive/old_script_20231027.R

# Document in commit message
git commit -m "Replace old_script with 01_process_growth (reorganization)"
```

---

**Last Updated:** 2025-10-27
**Version:** 1.0.0
**Applies to:** Reorganized repository structure

For questions about file organization, see `reports/PIPELINE_DOCUMENTATION.md`
