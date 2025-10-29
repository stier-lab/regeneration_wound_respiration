# Acropora pulchra Data Status Report

**Generated:** October 28, 2023

## Summary

**Acropora respirometry data (dark/light O₂ measurements) is NOT available in this repository.**

## Current Data Availability

### ✅ Data Available for Acropora:
1. **Growth (Buoyant Weight)**: Complete for all timepoints
2. **PAM Fluorometry (Fv/Fm)**: Available for Day 7 and Day 23
3. **Surface Area**: Complete measurements

### ❌ Data NOT Available for Acropora:
1. **Respirometry (O₂ consumption/production)**: No processed data
2. **Dark phase respiration rates**: Missing
3. **Light phase photosynthesis rates**: Missing

## Evidence

### 1. Directory Structure
```
data/raw/respirometry_runs/
├── 20230526/
│   └── Porites/  (NO Acropora directory)
├── 20230528/
│   └── Porites/  (NO Acropora directory)
├── 20230603/
│   └── Porites/  (NO Acropora directory)
└── 20230619/
    └── Porites/  (NO Acropora directory)
```

### 2. README Status
From the main README.md:
- **Respirometry (Porites)**: 18 samples, 4 timepoints, **Complete**
- **Respirometry (Acropora)**: 18 samples, 4 timepoints, **Pending**

### 3. Sample Information
- 18 Acropora corals exist in the experiment (IDs 41-58)
- Same coral IDs are used for both species
- All respirometry processing only includes Porites

## Likely Reasons

1. **Data Not Yet Processed**: Raw run files may contain Acropora data but haven't been extracted
2. **Technical Issues**: Possible equipment or experimental issues with Acropora measurements
3. **Different Run Schedule**: Acropora may have been run separately and data not yet integrated
4. **Species-Specific Challenges**: Acropora branching morphology may have presented measurement challenges

## Raw Data Investigation

The raw respirometry run files (e.g., `20230526_run_3.csv`) contain:
- Multi-channel sensor data (Channels 1-10)
- Continuous O₂ measurements over time
- No direct coral ID assignments in raw files

**To process Acropora data would require:**
1. Channel-to-coral ID mapping for Acropora
2. Extraction scripts configured for Acropora samples
3. LoLinR analysis for rate calculations
4. Quality control and filtering

## Impact on Analysis

### What We CAN Analyze for Acropora:
- Growth rates (calcification)
- Photosynthetic efficiency (Fv/Fm)
- Surface area changes
- Wound healing (qualitative)

### What We CANNOT Analyze for Acropora:
- Metabolic rates (respiration/photosynthesis)
- P:R ratios
- Metabolic response to wounding
- Species comparison of respiratory dynamics

## Recommendations

1. **Check with Data Collector**: Confirm if Acropora respirometry was completed
2. **Review Lab Notes**: Check for any documented issues with Acropora measurements
3. **Process Raw Files**: If data exists in raw runs, create extraction pipeline
4. **Update Documentation**: Clearly note this limitation in manuscripts

## Current Analysis Limitation

All respirometry results in the current analysis apply **ONLY to Porites sp.**

The wound-size metabolic paradox discovered (small wounds increase respiration, large wounds suppress it) has only been demonstrated in Porites and cannot be confirmed for Acropora without the respirometry data.

---

**Note:** This is a significant limitation that should be clearly stated in any publications or presentations of this work.