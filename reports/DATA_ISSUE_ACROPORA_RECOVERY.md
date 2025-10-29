# Data Issue: Acropora Small Wound Recovery

**Date Identified:** October 28, 2023
**Status:** ✅ **IDENTIFIED & DOCUMENTED**

---

## Issue Summary

Missing paired data for Acropora pulchra small wound treatment prevents proper recovery assessment between Pre-wound and Day 23 timepoints.

---

## Data Pattern Discovered

### Acropora Small Wound (Treatment 1) - Coral Presence by Timepoint:

| Coral ID | Pre-wound | Day 1 | Day 7 | Day 23 | Notes |
|----------|-----------|-------|-------|---------|-------|
| 42 | ✓ | ✓ | ✓ | ✗ | Lost by Day 23 |
| 43 | ✗ | ✓ | ✓ | ✓ | No pre-wound baseline |
| 47 | ✗ | ✓ | ✓ | ✓ | No pre-wound baseline |
| 49 | ✓ | ✓ | ✓ | ✓ | **Complete series** |
| 54 | ✓ | ✓ | ✓ | ✗ | Lost by Day 23 |
| 58 | ✓ | ✓ | ✓ | ✗ | Lost by Day 23 |

### Summary:
- **Only 1 of 6 corals (ID 49)** has both Pre-wound and Day 23 measurements
- **3 corals** (42, 54, 58) were lost between Day 7 and Day 23
- **2 corals** (43, 47) have no Pre-wound baseline measurements

---

## Impact on Analysis

### Recovery Assessment:
- **Cannot calculate group mean** % change for Acropora Small Wound
- **Only individual value** available (Coral 49: 75.3% change)
- **No standard error** calculation possible (n=1)

### Statistical Power:
- Reduces power for species × treatment × time interactions
- Limits conclusions about Acropora small wound recovery

---

## Likely Causes

### Fragment Loss (42, 54, 58):
1. **Mortality** - Fragments may have died between Day 7-23
2. **Poor health** - Too unhealthy to measure reliably
3. **Handling issues** - Damage during measurement
4. **Species sensitivity** - Acropora more sensitive to small wounds?

### Missing Baselines (43, 47):
1. **Initial extraction issue** - May not have been measured pre-wound
2. **Data recording error** - Measurements not properly recorded
3. **File naming issue** - Data exists but not properly linked

---

## How It Was Fixed in Report

### 1. Updated Recovery Figure:
- Added caption note about limited paired data
- Figure still displays available data

### 2. Enhanced Recovery Table:
- Added footnote explaining n=1 for Acropora Small Wound
- Listed missing coral IDs
- Shows NA for SE when n=1

### 3. Added Study Limitations Section:
- Clear disclosure of data attrition
- Discussion of possible causes
- Acknowledgment of impact on conclusions

---

## Biological Interpretation

The pattern suggests **Acropora pulchra may be more sensitive to small wounds** than other treatments:

1. **Higher mortality/attrition** in small wound treatment
2. **Contrasts with large wound** treatment which retained more corals
3. **Different from Porites** which had complete data

This could indicate:
- Small wounds create localized stress without triggering full healing response
- Acropora's branching morphology makes small wounds more problematic
- Energy allocation differences between wound sizes

---

## Recommendations

### For Current Analysis:
✅ **Done:** Clearly document limitation in report
✅ **Done:** Present available data with appropriate caveats
✅ **Done:** Focus conclusions on treatments with complete data

### For Future Studies:
1. **Increase replication** - Start with 8-10 fragments per treatment
2. **Monitor health** - Daily health checks during critical periods
3. **Backup fragments** - Keep reserve fragments for each treatment
4. **Photo documentation** - Visual record of fragment condition
5. **Water quality logs** - Track any system issues

---

## Data Files Affected

- `data/processed/respirometry/acropora_rates_simple.csv` - Contains all measurements
- `data/processed/respirometry/combined_species_normalized.csv` - Missing pairs evident
- `reports/Complete_Analysis_Enhanced_Fixed.html` - Now includes proper documentation

---

## Verification

To verify this issue:
```r
# Check paired data availability
combined_data %>%
  filter(species == "Acropora pulchra", treatment == 1) %>%
  group_by(coral_id) %>%
  summarise(
    timepoints = paste(unique(timepoint), collapse = ", "),
    n_timepoints = n_distinct(timepoint)
  )
```

---

## Conclusion

While this data limitation affects the Acropora small wound recovery assessment, it:
- ✅ Has been properly identified
- ✅ Is now documented in the report
- ✅ Does not invalidate other findings
- ✅ May provide biological insight into differential stress responses
- ✅ Informs future experimental design

The overall analysis remains robust, with this limitation appropriately acknowledged.