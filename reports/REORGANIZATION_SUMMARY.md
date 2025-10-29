# Repository Reorganization Summary
**Date:** 2025-10-27
**Status:** ✅ Complete

---

## What Changed

The repository has been reorganized from the original flat/nested structure into a clean, professional layout optimized for reproducibility and collaboration.

### Old Structure → New Structure

```
BEFORE:                              AFTER:
├── analysis_functions.R      →      ├── scripts/
├── data_audit.R              →      │   ├── 00_run_all.R (NEW)
├── Wound_Respiration_Analysis →      │   ├── analysis_functions.R
├── Growth/                   →      │   ├── data_audit.R
│   ├── Data/                →      │   ├── 01_process_growth.R
│   ├── Scripts/             →      │   ├── 02_process_pam.R
│   └── Output/              →      │   ├── 03_process_surface_area.R
├── PAM/                      →      │   ├── 04_extract_respirometry.R
│   ├── Data/                →      │   ├── 05_calculate_rates.R
│   ├── Scripts/             →      │   └── Wound_Respiration_Analysis.Rmd
│   └── Output/              →      │
├── Respirometry/             →      ├── data/
│   ├── Data/                →      │   ├── metadata/
│   │   ├── Runs/           →      │   │   └── sample_info.csv
│   │   └── chamber_volumes/ →      │   ├── raw/
│   ├── Scripts/             →      │   │   ├── growth/
│   └── Output/              →      │   │   ├── pam/
├── Surface_Area/             →      │   │   ├── surface_area/
│   ├── Data/                →      │   │   ├── chamber_volumes/
│   ├── Scripts/             →      │   │   └── respirometry_runs/
│   └── Output/              →      │   └── processed/
├── sample_info.csv           →      │       ├── growth/
├── Figures/                  →      │       ├── pam/
├── *.md files                →      │       ├── surface_area/
└── *.html                    →      │       └── respirometry/
                                     │
                                     ├── reports/
                                     │   ├── Wound_Respiration_Analysis.html
                                     │   ├── Figures/ (7 PNGs)
                                     │   ├── DATA_AUDIT_SUMMARY.md
                                     │   ├── PIPELINE_DOCUMENTATION.md
                                     │   ├── PROJECT_SUMMARY.md
                                     │   └── FILES_CREATED.txt
                                     │
                                     ├── archive/
                                     │   ├── Growth/
                                     │   ├── PAM/
                                     │   ├── Respirometry/
                                     │   ├── Surface_Area/
                                     │   ├── rawdata/
                                     │   ├── similar analysis/
                                     │   ├── sample_info.csv
                                     │   └── old_README.md
                                     │
                                     └── README.md (NEW - comprehensive)
```

---

## Key Improvements

### 1. Standardized Folder Names
- ✅ All lowercase with underscores (scripts/, data/, reports/)
- ✅ Clear purpose for each top-level folder
- ✅ Eliminates spaces in folder names

### 2. Separated Data Types
- **raw/** - Original data files (immutable)
- **processed/** - Analysis outputs (reproducible)
- **metadata/** - Sample information & experimental design

### 3. Organized Scripts
- ✅ Numbered pipeline scripts (01_, 02_, 03_...)
- ✅ Master run script (`00_run_all.R`)
- ✅ All analysis code in one place
- ✅ Renamed with descriptive names

### 4. Consolidated Reports
- ✅ All documentation in `reports/`
- ✅ Figures in `reports/Figures/`
- ✅ HTML report easily accessible
- ✅ No loose files in root

### 5. Archived Old Structure
- ✅ Original folders preserved in `archive/`
- ✅ Reference materials maintained
- ✅ Nothing deleted, just reorganized

---

## File Path Updates

All scripts have been updated to use new paths:

| Old Path | New Path |
|----------|----------|
| `Growth/Data/` | `data/raw/growth/` |
| `Growth/Output/` | `data/processed/growth/` |
| `PAM/Data/` | `data/raw/pam/` |
| `PAM/Output/` | `data/processed/pam/` |
| `Surface_Area/Data/` | `data/raw/surface_area/` |
| `Surface_Area/Output/` | `data/processed/surface_area/` |
| `Respirometry/Data/Runs/` | `data/raw/respirometry_runs/` |
| `Respirometry/Output/` | `data/processed/respirometry/` |
| `sample_info.csv` | `data/metadata/sample_info.csv` |
| `Figures/` | `reports/Figures/` |

---

## How to Use New Structure

### Run Complete Analysis

```bash
# Option 1: Master script (recommended)
Rscript scripts/00_run_all.R

# Option 2: Individual steps
Rscript scripts/01_process_growth.R
Rscript scripts/02_process_pam.R
Rscript scripts/03_process_surface_area.R
Rscript -e "rmarkdown::render('scripts/Wound_Respiration_Analysis.Rmd', output_dir='reports')"
```

### Access Results

```bash
# View HTML report
open reports/Wound_Respiration_Analysis.html

# View figures
open reports/Figures/

# Read documentation
open reports/PIPELINE_DOCUMENTATION.md
```

### Access Data

```bash
# Raw data (original files)
ls data/raw/

# Processed data (analysis outputs)
ls data/processed/

# Metadata (sample information)
cat data/metadata/sample_info.csv
```

---

## What's in Archive/

The `archive/` folder contains:
- **Original folder structure** (Growth/, PAM/, Respirometry/, Surface_Area/)
- **Raw data folders** (rawdata/)
- **Reference project** (similar analysis/)
- **Old README** (old_README.md)
- **Original sample_info.csv**

⚠️ **Important:** Archive is for reference only. Do NOT modify archive contents. Always use files in `data/`, `scripts/`, and `reports/`.

---

## Benefits of New Structure

### For Collaboration
✅ Clear separation of code, data, and results
✅ Easy to navigate for new users
✅ Standard scientific project layout

### For Reproducibility
✅ Raw data preserved separately from processed
✅ All scripts in one location
✅ Clear pipeline order (numbered scripts)

### For Publication
✅ Reports and figures in dedicated folder
✅ Documentation consolidated
✅ Archive maintains provenance

### For Version Control
✅ Fewer top-level items
✅ Logical .gitignore structure
✅ Clear what should be tracked vs. generated

---

## Suggested .gitignore

```gitignore
# Processed data (can be regenerated)
data/processed/

# Reports (can be regenerated)
reports/*.html
reports/Figures/

# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata

# Archive (original structure, optional to track)
archive/

# System files
.DS_Store
```

---

## Migration Checklist

- [x] Create new folder structure (scripts/, data/, reports/, archive/)
- [x] Move R scripts to scripts/ with descriptive names
- [x] Organize data into raw/ and processed/
- [x] Move documentation to reports/
- [x] Archive original structure
- [x] Update file paths in all scripts
- [x] Create master run script
- [x] Write comprehensive README.md
- [x] Test scripts with new paths
- [x] Document reorganization

---

## Testing the New Structure

### Quick Test

```bash
# 1. Check folder structure
ls -la

# Expected: README.md, scripts/, data/, reports/, archive/

# 2. Verify data copied correctly
ls data/raw/
ls data/processed/

# 3. Check scripts
ls scripts/

# 4. View reports
ls reports/

# 5. Confirm archive
ls archive/
```

### Full Pipeline Test

```bash
# Run complete analysis
Rscript scripts/00_run_all.R

# Check outputs
ls data/processed/growth/
ls data/processed/pam/
ls reports/Figures/
open reports/Wound_Respiration_Analysis.html
```

---

## Troubleshooting

### "File not found" errors

**Problem:** Scripts can't find data files

**Solution:**
```r
# Check working directory
getwd()

# Should be: /path/to/regeneration_wound_respiration
# If not, set it:
setwd("/Users/adrianstiermbp2023/regeneration_wound_respiration")
```

### Missing output folders

**Problem:** "cannot open file for writing"

**Solution:**
```bash
# Create missing output directories
mkdir -p data/processed/growth
mkdir -p data/processed/pam
mkdir -p data/processed/surface_area
mkdir -p data/processed/respirometry
mkdir -p reports/Figures
```

### Archive too large

**Problem:** Repository size bloated by archive/

**Solution:**
```bash
# Option 1: Exclude from git
echo "archive/" >> .gitignore

# Option 2: Move outside repository
mv archive/ ../regeneration_wound_respiration_archive/

# Option 3: Compress
tar -czf archive.tar.gz archive/
rm -rf archive/
```

---

## Rollback (If Needed)

To restore original structure:

```bash
# Copy everything back from archive
cp -r archive/Growth ./
cp -r archive/PAM ./
cp -r archive/Respirometry ./
cp -r archive/Surface_Area ./
cp -r archive/rawdata ./
cp archive/sample_info.csv ./
cp archive/old_README.md README.md

# Remove new structure
rm -rf scripts/ data/ reports/
```

⚠️ **Not recommended unless critical issue found**

---

## Summary

### Files Created: 3
- `README.md` (comprehensive project documentation)
- `scripts/00_run_all.R` (master pipeline script)
- `REORGANIZATION_SUMMARY.md` (this file)

### Files Modified: 6
- `scripts/01_process_growth.R` (path updates)
- `scripts/02_process_pam.R` (path updates)
- `scripts/03_process_surface_area.R` (path updates)
- `scripts/data_audit.R` (path updates)
- `scripts/Wound_Respiration_Analysis.Rmd` (path updates)
- `scripts/analysis_functions.R` (no changes, just moved)

### Files Moved: All
- 8 scripts → `scripts/`
- 5 data folders → `data/raw/` and `data/processed/`
- 6 documentation files → `reports/`
- 7 original folders → `archive/`

### Files Deleted: 0
Everything preserved in archive/

---

**Reorganization completed:** 2025-10-27
**Status:** ✅ Production Ready
**Tested:** Yes
**Rollback Available:** Yes (via archive/)

---

*For questions about new structure, see README.md*
*For detailed workflow, see reports/PIPELINE_DOCUMENTATION.md*
