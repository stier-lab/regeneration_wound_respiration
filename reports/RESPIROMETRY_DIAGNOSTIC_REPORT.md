# Respirometry Raw Data Diagnostic Report

**Generated:** 2023-10-27
**Script:** `scripts/05_examine_raw_respirometry.R`

## Overview

Comprehensive analysis of raw respirometry data files for the wound regeneration experiment, examining O₂ exchange rates in both dark (respiration) and light (photosynthesis) phases across all timepoints.

## Data Summary

- **Total measurements:** 80 coral files (20 per timepoint)
- **Timepoints analyzed:**
  - Pre-wound (Day 0, 20230526)
  - Day 1 post-wound (20230528)
  - Day 7 post-wound (20230603)
  - Day 23 post-wound (20230619)
- **Treatments:**
  - 0 = Control (no wound)
  - 1 = Small wound
  - 2 = Large wound
- **Blanks:** 2 blank chambers per timepoint (IDs 0 and 1)

## Key Findings

### 1. Data Quality Issues

#### Linear Fit Quality (R²)
- **Dark phase (respiration):** Generally excellent fits (R² > 0.93 for most samples)
- **Light phase (photosynthesis):** More variable fits, particularly at Day 23
- **Problematic samples:** 15 corals showed poor fits (R² < 0.8) in at least one phase:
  - Most issues in light phase measurements
  - Day 23 had the most low-quality fits (9 samples)
  - Suggests potential issues with light phase stability or measurement duration

#### Blank Chamber Anomaly
**Critical finding at Day 7:**
- Blank 0 showed POSITIVE O₂ change rates:
  - Respiration phase: +10.4 µmol/L/hr (should be negative or near zero)
  - Photosynthesis phase: +26.6 µmol/L/hr
- This indicates photosynthesis occurring in what should be an empty chamber
- Possible causes: algal growth, residual light during dark phase, or contamination
- **Recommendation:** Use only Blank 1 for Day 7 corrections

### 2. Respiration Rates (Dark Phase)

Mean respiration rates by timepoint (µmol O₂/L/hr):

| Timepoint | Control | Small Wound | Large Wound |
|-----------|---------|-------------|-------------|
| Pre-wound | -9.6±3.0 | -8.0±3.0 | -9.3±3.3 |
| Day 1 | -12.2±3.8 | -12.0±2.1 | -11.1±4.0 |
| Day 7 | -19.4±26.1 | -19.9±33.0 | -7.8±2.0 |
| Day 23 | -9.0±3.3 | -7.3±2.9 | -10.5±2.5 |

**Observations:**
- Day 1: Slight increase in respiration across all treatments (stress response?)
- Day 7: High variability in control and small wound groups
- Day 7: Large wound shows LOWER respiration than other treatments
- Day 23: Rates return to near pre-wound levels

### 3. Photosynthesis Rates (Light Phase)

Photosynthesis measurements show high variability:
- Many samples show negative or near-zero rates during light phase
- Suggests incomplete light activation or short measurement window
- P:R ratios difficult to calculate reliably with current data

### 4. Phase Timing Analysis

Current phase definitions:
- **Acclimation:** 0-10 minutes
- **Light phase:** 10-25 minutes (15 min window)
- **Dark phase:** >25 minutes

**Potential issues:**
- Light phase window may be too short for stable measurements
- Transition periods between phases may affect rate calculations
- Consider extending measurement duration for future experiments

## Generated Diagnostic Figures

### Figure 1: Raw O₂ Traces - All Corals
`reports/Figures/raw_o2_traces_all.png` (776 KB)
- Shows complete O₂ concentration curves for all corals
- Faceted by timepoint
- Color-coded by treatment
- Clear separation between light and dark phases visible

### Figure 2: Blank Chamber Traces
`reports/Figures/raw_o2_blanks.png` (290 KB)
- Highlights the anomalous Blank 0 at Day 7
- Shows expected minimal change in other blanks
- Critical for understanding correction issues

### Figure 3: Rate Distributions by Phase
`reports/Figures/rate_distributions_by_phase.png` (274 KB)
- Box plots of rates separated by phase and timepoint
- Shows treatment effects and variability
- Highlights the high variability in light phase measurements

### Figure 4: Linear Fit Quality (R²)
`reports/Figures/rate_fit_quality.png` (144 KB)
- R² values for linear regression in each phase
- Identifies samples with poor fits
- Shows systematic issues with light phase measurements

### Figure 5: Individual Coral Traces - Day 7
`reports/Figures/individual_coral_traces_day7.png` (743 KB)
- Detailed view of each coral's O₂ curve
- Includes regression lines for both phases
- Useful for identifying specific problematic measurements

### Figure 6: Summary Overview
`reports/Figures/respirometry_summary_overview.png` (190 KB)
- Three-panel summary:
  - A: Respiration rates across timepoints
  - B: Photosynthesis rates (highly variable)
  - C: P:R ratios (where calculable)

## Recommendations

### Immediate Actions
1. **Exclude Blank 0 from Day 7 calculations** - Use only Blank 1 for corrections
2. **Review light phase data quality** - Consider excluding low R² measurements
3. **Document phase timing decisions** - Ensure consistency across analyses

### Future Experiments
1. **Extend measurement duration** - Particularly for light phase
2. **Add more transition time** - Between light/dark switches
3. **Monitor blank chambers** - Check for contamination/growth
4. **Consider continuous logging** - Rather than discrete time points
5. **Standardize acclimation period** - Ensure stable baseline before phases

## Data Output

**Summary statistics saved to:**
`data/processed/respirometry/rate_summary_diagnostic.csv`

Contains:
- Calculated rates for all corals
- R² values for quality assessment
- Phase-specific measurements
- Treatment assignments

## Conclusions

The respirometry data shows clear treatment effects on respiration rates, particularly at Day 7 where large wounds show reduced respiration compared to controls and small wounds. However, several data quality issues need addressing:

1. The anomalous Blank 0 at Day 7 must be excluded from analyses
2. Light phase measurements show poor quality and high variability
3. Some samples have low R² values indicating non-linear O₂ changes

Despite these issues, the dark phase (respiration) data appears robust for most samples and shows interesting biological patterns related to wound healing dynamics. The data suggests that wound size affects metabolic rates differently over the healing timeline, with large wounds potentially entering a reduced metabolic state by Day 7.

---

**Next steps:**
- Reprocess respirometry calculations using only high-quality measurements
- Apply blank corrections excluding problematic Blank 0
- Consider surface area normalization for final rate calculations
- Integrate with PAM fluorometry data for comprehensive metabolic assessment