# Updated Pipeline (2025-10-27)

## ✨ What Changed

The pipeline has been updated to match published methods for coral respirometry and growth analysis. All redundant scripts have been removed for a cleaner workflow.

---

## 📋 Complete Analysis Pipeline

### Step 1: Calculate Wound Areas
```bash
Rscript scripts/02b_calculate_wound_areas.R
```
**Output:** `data/processed/wound_areas.csv`
- Calculates surface area removed by each wound treatment
- Required for adjusting surface area normalization

---

### Step 2: Calculate Adjusted Surface Areas
```bash
Rscript scripts/03b_calculate_adjusted_surface_areas.R
```
**Outputs:**
- `data/processed/surface_area/initial_SA.csv`
- `data/processed/surface_area/postwound_SA.csv`
- `data/processed/surface_area/adjusted_surface_areas.csv`

---

### Step 3: Process Growth Data
```bash
Rscript scripts/01_process_growth.R
```
**Key Fixes:**
- ✅ Added aragonite density constant (2.93 g/cm³)
- ✅ NEW normalization method: mg/cm²/day by final surface area
- ✅ OLD method preserved for comparison

**Outputs:**
- `data/processed/growth/growth_SA_normalized.csv` ← **USE THIS**
- `data/processed/growth/growth_weight_normalized.csv` (old method)

---

### Step 4: Process Respirometry Data
```bash
Rscript scripts/04_process_respirometry.R
```
**Major Fixes:**
- ✅ **Respiration**: Dark phase only (>25 min) - FIXED!
- ✅ **Photosynthesis**: Light phase (10-25 min)
- ✅ **Normalization**: By surface area (umol/cm²/hr) not weight
- ✅ **Wound-adjusted SA**: Used for post-wound timepoints
- ✅ **P_gross**: Calculated (P_net + R)
- ✅ **P:R ratios**: Daily metabolic budget

**Replaces:** Old scripts `04_extract_respirometry.R` and `05_calculate_rates.R`

**Outputs:**
- `data/processed/respirometry/all_rates_combined.csv` ← **Master file**
- Individual timepoint files in `data/processed/respirometry/Porites/[date]/`

**Output Columns:**
- `coral_id`, `genus`, `treatment`, `timepoint`
- `R_umol.cm2.hr` - Respiration rate
- `P_net_umol.cm2.hr` - Net photosynthesis
- `P_gross_umol.cm2.hr` - Gross photosynthesis
- `PR_ratio` - Metabolic budget (>1 = autotrophy, <1 = heterotrophy)
- `SA_cm2` - Surface area used
- `Temp_C` - Temperature

---

### Step 5: Process PAM Data
```bash
Rscript scripts/02_process_pam.R
```
**Status:** ✅ No changes needed (already correct)

---

### Step 6: Process Surface Area (Wax Dipping)
```bash
Rscript scripts/03_process_surface_area.R
```
**Status:** ✅ No changes needed (already correct)

---

### Step 7: Integrated Analysis
```bash
Rscript -e "rmarkdown::render('scripts/Wound_Respiration_Analysis.Rmd', output_dir='reports')"
```
**Note:** Will need to update this Rmd to use new data files

---

## 🔑 Key Differences from Old Pipeline

| Metric | OLD | NEW | Why It Matters |
|--------|-----|-----|----------------|
| **Resp time window** | 10-25 min (LIGHT!) | >25 min (DARK) | Was measuring wrong phase entirely |
| **Photo time window** | 10-25 min | 10-25 min | ✅ Was already correct |
| **Resp units** | umol/g/hr | umol/cm²/hr | Gas exchange happens at surface |
| **Photo units** | umol/g/hr | umol/cm²/hr | Standard practice |
| **Growth units** | g/g/day | mg/cm²/day | Comparable across studies |
| **Wound SA adjust** | Not done | Initial - wound | Accounts for tissue removed |
| **P_gross** | Not calculated | P_net + R | Key metabolic metric |
| **P:R ratio** | Not calculated | (11P)/(13R) | Autotrophy vs heterotrophy |
| **Aragonite density** | Unspecified | 2.93 g/cm³ | Standard value (Jokiel 1978) |

---

## 📁 Files Created/Updated

### New Scripts
- `scripts/02b_calculate_wound_areas.R` ✅
- `scripts/03b_calculate_adjusted_surface_areas.R` ✅
- `scripts/04_process_respirometry.R` ✅ (replaces 04 & 05)

### Updated Scripts
- `scripts/01_process_growth.R` ✅ (added SA normalization)

### Archived Scripts (renamed to .OLD)
- `scripts/04_extract_respirometry.R.OLD`
- `scripts/05_calculate_rates.R.OLD`

### New Data Files
- `data/processed/wound_areas.csv`
- `data/processed/surface_area/adjusted_surface_areas.csv`
- `data/processed/growth/growth_SA_normalized.csv`
- `data/processed/respirometry/all_rates_combined.csv` (when run)

---

## 🧪 Testing the Pipeline

### Quick Test
```bash
# Test growth processing
Rscript scripts/01_process_growth.R

# Test surface area calculations
Rscript scripts/02b_calculate_wound_areas.R
Rscript scripts/03b_calculate_adjusted_surface_areas.R

# Test respirometry (NOTE: Requires LoLinR package)
Rscript scripts/04_process_respirometry.R
```

### Expected Output
- Growth: Both old and new method CSVs created
- Wound areas: 6 treatment groups with correct areas
- Surface areas: Initial and postwound SA files
- Respirometry: Master combined file with all timepoints

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| **UPDATED_PIPELINE.md** (this file) | Quick reference for new workflow |
| **PIPELINE_FIXES_SUMMARY.md** | One-page summary of all changes |
| **reports/PIPELINE_COMPARISON.md** | Detailed comparison with reference methods |
| **reports/IMPLEMENTATION_GUIDE.md** | Step-by-step troubleshooting guide |

---

## ⚠️ Known Issues

1. **LoLinR Package**: If `04_process_respirometry.R` fails with "package 'LoLinR' not found", install it:
   ```r
   # LoLinR is on GitHub, not CRAN
   # install.packages("devtools")
   # devtools::install_github("colin-olito/LoLinR")
   ```

2. **Path Issues**: All scripts assume working directory is repository root

3. **Blank ID Files**: Script looks for `blank_id.csv` in each run folder. If missing, uses mean of corals 0 and 1 as blank.

---

## ✅ Validation Checklist

After running the pipeline:

### Growth Data
- [ ] Units are mg/cm²/day (not dimensionless ratio)
- [ ] Output file is `growth_SA_normalized.csv`
- [ ] Aragonite density = 2.93 visible in script

### Surface Area Data
- [ ] Wound areas match treatment specifications
- [ ] Initial SA available for all corals
- [ ] Postwound SA = initial SA - wound area

### Respirometry Data
- [ ] Column names include `R_umol.cm2.hr`, `P_net_umol.cm2.hr`, `P_gross_umol.cm2.hr`
- [ ] NOT `umol.g.hr` (old wrong units)
- [ ] `PR_ratio` column exists
- [ ] Values look reasonable (R typically 0.5-5, P typically 1-20)

---

## 🚀 Next Steps

1. **Run new respirometry script** - This is the biggest change
2. **Update integrated analysis** - Modify `Wound_Respiration_Analysis.Rmd` to use new data files
3. **Regenerate figures** - With correct normalization
4. **Compare results** - Document how conclusions changed (if at all)

---

## 💡 Quick Reference: What to Use

| Analysis | Data File | Column |
|----------|-----------|--------|
| Growth rate | `growth_SA_normalized.csv` | `mg_cm2_day` |
| Respiration | `all_rates_combined.csv` | `R_umol.cm2.hr` |
| Net photosynthesis | `all_rates_combined.csv` | `P_net_umol.cm2.hr` |
| Gross photosynthesis | `all_rates_combined.csv` | `P_gross_umol.cm2.hr` |
| Metabolic status | `all_rates_combined.csv` | `PR_ratio` |
| PAM | `all_fvfm.csv` | `fv_fm` |

---

**Last Updated:** 2025-10-27
**Status:** Pipeline cleaned and consolidated
**Next:** Test respirometry script with LoLinR
