# Block 4: From Harmonization to Analysis

**Pakistan LFS 2024-25 | Duration: 35 minutes | Two examples using the research dataset**

We have gone from the original survey to a dataset ready for research. We can now ask substantive questions without rebuilding the variables behind each one.

We will do two things:

1. **Use information we added from the survey.** Compare commuting direction and time, with and without the standard GLD occupation variable `occup`.
2. **Link to information from outside the survey.** Use the harmonized occupation code `occup_isco` to attach AI exposure and complementarity scores, then compare workers with different education levels and compare women and men.

The first example stays entirely within the survey. The second demonstrates interoperability: a common classification makes an external source usable alongside the GLD variables we already have.

## 1. Open the research dataset

Use the expanded dataset saved in Block 3, wherever you chose to put it. Run the code blocks in order, or use the complete script linked in Section 4 as an alternative. The results shown below are rounded; compare them with your computed output.

```stata
local path_input "C:/your/path/gld_workshop"
use "`path_input'/PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED.dta", clear
```

The ICLS comparison is complete in [Block 3, Section 5](../3%20-%20Expand/Block_3_Expanding_the_GLD.md#5-check-the-saved-file-and-evaluate-the-icls-results). Here we use the commuting additions and the existing GLD variables.

## 2. Example 1: Use the survey information we added

### 2.1. Compare commuting direction and time

**Which residence-to-work pattern has the largest share of long commutes?**

`work_mobility` combines rural/urban residence with rural/urban workplace location. `commute_time` retains the questionnaire's time categories, and `long_commute` identifies journeys exceeding 45 minutes.

```stata
tab work_mobility commute_time, row
tab work_mobility long_commute, row
```

These are **unweighted descriptions of the observed sample**. Missing responses are excluded, not treated as zero commuting time. We do not impute commuting answers for the additional employed group from the ICLS bridge.

| Residence-to-work pattern | Less than 30 min | 31-45 min | 46-60 min | 61+ min |
| --- | ---: | ---: | ---: | ---: |
| Rural -> Rural | 80.45% | 14.50% | 2.82% | 2.23% |
| Rural -> Urban | 40.22% | 30.88% | 12.28% | 16.62% |
| Urban -> Rural | 64.99% | 22.17% | 6.83% | 6.01% |
| Urban -> Urban | 64.38% | 24.75% | 7.32% | 3.55% |

Combining the categories into journeys of at most 45 minutes and longer journeys makes the contrast easier to see:

| Residence-to-work pattern | 45 minutes or less | More than 45 minutes |
| --- | ---: | ---: |
| Rural -> Rural | 94.95% | 5.05% |
| Rural -> Urban | 71.09% | 28.91% |
| Urban -> Rural | 87.16% | 12.84% |
| Urban -> Urban | 89.13% | 10.87% |
| Total | 89.64% | 10.36% |

The contrast is immediate: about 5% of rural-to-rural workers report a long commute, compared with about 29% of rural-to-urban workers. That is a difference of roughly 24 percentage points. This is information we could not have obtained from the standard GLD variables alone.

Adding the `chi2` option to either table gives a Pearson test of independence (`p < .001` here). Like the models below, these tests do not account for the survey design.

### 2.2. Estimate the association without occupation

```stata
logistic long_commute ib1.work_mobility
margins work_mobility
```

Stata treats `work_mobility` as categorical, with rural-to-rural as the reference category. `margins` reports predicted probabilities, which in this simple model reproduce the observed group shares.

The rural-to-urban odds ratio is about 7.64; that does not mean its probability is 7.64 times larger. Odds are probability divided by one minus probability: the rural-to-rural odds are about 0.053, and rural-to-urban odds about 0.407. Their ratio is 7.64, while the probability ratio is about 5.7. Predicted probabilities are often easier to communicate.

### 2.3. Add the harmonized occupation variable

**Does the difference remain when we account for occupation?**

```stata
logistic long_commute ib1.work_mobility i.occup
margins work_mobility
```

We did not have to reconstruct occupation. `occup`, the standard GLD one-digit occupation grouping, is already available alongside our commuting variables.

| Residence-to-work pattern | Unadjusted odds ratio | Occupation-adjusted odds ratio |
| --- | ---: | ---: |
| Rural -> Rural | Reference | Reference |
| Rural -> Urban | 7.64 | 4.64 |
| Urban -> Rural | 2.77 | 2.35 |
| Urban -> Urban | 2.29 | 1.39 |

Compare the predicted probabilities from the two models as well. The rural-to-urban odds ratio falls to about 4.64 after adding occupation. The unadjusted model uses 99,785 observations and the adjusted model 99,783. The samples differ slightly, and odds ratios are non-collapsible: their change is not a measure of how much of the commuting difference occupation causally explains.

These models illustrate sample associations. Their standard errors do not account for the survey design. Population inference requires an appropriate specification of weights, strata, and PSUs from the survey documentation.

## 3. Example 2: Link to external AI scores

**Do workers with different education levels work in occupations with different average AI exposure and complementarity? Does the pattern differ between women and men?**

The survey did not ask about AI. But it records occupations, and GLD has already expressed those occupations in a common classification. We can therefore link an external occupation-level measure without returning to the raw survey.

### 3.1. Obtain and understand the scores

Open the [AI Scores Documentation folder](https://github.com/gronert-m/gld-workshop/tree/main/Docs/AI%20Scores%20Documentation), read its [README](https://github.com/gronert-m/gld-workshop/blob/main/Docs/AI%20Scores%20Documentation/README.md), and download [c_aioe_scores.csv](https://raw.githubusercontent.com/gronert-m/gld-workshop/main/Docs/AI%20Scores%20Documentation/c_aioe_scores.csv) to a folder of your choice.

We use three columns:

| CSV variable | Interpretation |
| --- | --- |
| `aioe_all` | AI Occupational Exposure (AIOE): higher values mean greater relative exposure, without distinguishing substitution from complementarity. |
| `complementarity_theta` | Potential complementarity: higher values indicate occupational characteristics more conducive to AI supporting human work. |
| `c_aioe` | Complementarity-adjusted exposure (C-AIOE): greater complementarity reduces adjusted exposure; higher values indicate greater relative potential for substitution. |

**C-AIOE is not a probability of job loss or a percentage of tasks that can be automated.** These measures come from Felten et al. (2021) and Pizzinelli et al. (2023), cited below. We compare continuous scores rather than choosing an arbitrary threshold for "high risk".

### 3.2. Attach the scores using the common occupation code

The Pakistan harmonization identifies its occupation classification as `isco_2008`. The CSV uses the corresponding ISCO-08 keys in `occup_isco`, stored as four-character strings. Preserve leading zeros. Use `occup_isco`, not the broad `occup` grouping used in the commuting model.

The supplied mapping contains both detailed and aggregate occupation codes. We use exact matches to the supplied keys, including aggregate codes where the survey reports them. We do not manufacture a more detailed occupation or recalculate an aggregate score.

Run this block together. It prepares a temporary lookup, restores the survey, and performs a many-to-one merge without saving over either input:

```stata
local path_scores "C:/your/path/gld_workshop"
preserve
import delimited using "`path_scores'/c_aioe_scores.csv", clear varnames(1) stringcols(_all)
keep occup_isco aioe_all complementarity_theta c_aioe
isid occup_isco
foreach score in aioe_all complementarity_theta c_aioe {
	replace `score' = "" if `score' == "NA"
	destring `score', replace
}

tempfile ai_scores
save `ai_scores'
restore

confirm string variable occup_isco
assert isco_version == "isco_2008" if !missing(occup_isco)
merge m:1 occup_isco using `ai_scores'

* We should see all three merge options:

* Codes from the AI scores data matched (_merge == 3)

* Rows that were not matched. These are people without ISCO codes, 
* most of them should not be employed (_merge == 1)

* Codes that AI scores (comprehensive of ISCO code universe)
* has, but are not present in the data.
* For example no codes 2422 "Policy administration professionals"
* were interviewed in 2024 in Pakistan - quite a pity!

* Checking answers that had no match (all should be unemployed, NLF or kids)
tab lstatus if _merge == 1,m

* Drop _merge variable after keeping cases either only from PaK 24 (_merge == 1) or matched (_merge == 3)
keep if inlist(_merge, 1, 3)
drop _merge
```

The lookup must have only one row per key. Keeping master and match retains every survey observation but excludes occupations found only in the lookup. The CSV's `NA` tokens become missing numeric values, not zero scores.

### 3.3. Check coverage before comparing groups

Use respondents aged 15 and above who are employed under the standard survey definition and have a positive, nonmissing weight. Require all three scores so their means describe the same workers. We do not assign detailed occupation scores to the additional ICLS-13 employed group using assumed occupations.

```stata
gen byte ai_eligible = lstatus == 1 & age >= 15 & !missing(age) & weight > 0 & !missing(weight)
gen byte ai_scored = ai_eligible & !missing(aioe_all, complementarity_theta, c_aioe)
tab ai_merge if ai_eligible, missing
count if ai_eligible & ai_merge == 3 & !ai_scored
tab ai_scored if ai_eligible [iw=weight]
tabstat ai_scored if ai_eligible [aw=weight], by(educat4) statistics(mean)
tabstat ai_scored if ai_eligible [aw=weight], by(male) statistics(mean)
```

`ai_merge` distinguishes unmatched survey records from matched keys. A matched key can still have missing scores. The lookup has 590 unique keys, including seven armed-forces keys with missing scores. The mean of `ai_scored` is the weighted share with scores, on a 0-1 scale. Check it by education and sex: unequal coverage can affect comparisons. Missing scores never mean no exposure.

For the supplied Pakistan release, all 97,128 eligible workers match and have all three scores: weighted coverage is 100% overall and within the education and sex groups. None uses an unscored key. The 225,662 unmatched survey records in the full merge are outside this analysis sample.

### 3.4. Compare weighted average scores

```stata
tabstat c_aioe aioe_all complementarity_theta if ai_scored [aw=weight], by(educat4) statistics(mean) format(%9.3f)
tabstat c_aioe aioe_all complementarity_theta if ai_scored [aw=weight], by(male) statistics(mean) format(%9.3f)
graph hbar (mean) c_aioe if ai_scored [aw=weight], over(educat4) ///
	title("C-AIOE by education") ytitle("Weighted mean occupation score")
```

These commands use the survey weights to calculate descriptive weighted means among workers with scores; they do not estimate survey-design-adjusted uncertainty. Groups with missing education or sex are excluded from the corresponding grouped comparison. Each column is a different measure: compare groups within a column, not ratios between columns.

| Education | C-AIOE | AIOE | Potential complementarity |
| --- | ---: | ---: | ---: |
| No education | 4.300 | 5.664 | 0.548 |
| Primary | 4.298 | 5.775 | 0.562 |
| Secondary | 4.345 | 5.980 | 0.580 |
| Post-secondary | 4.394 | 6.194 | 0.598 |
| All eligible workers | 4.312 | 5.799 | 0.563 |

Read the columns together. Does higher education coincide with greater AIOE? Is it also associated with greater potential complementarity? Does the education pattern look different for C-AIOE?

In this release, AIOE and potential complementarity both rise across the education groups, while C-AIOE changes relatively little. These are weighted occupation-score means, not percentages or evidence of an individual return to education.

| Sex | C-AIOE | AIOE | Potential complementarity |
| --- | ---: | ---: | ---: |
| Women | 4.358 | 5.775 | 0.551 |
| Men | 4.299 | 5.806 | 0.566 |

Women have slightly lower mean AIOE than men, but higher mean C-AIOE, alongside lower potential complementarity. Adjustment can therefore change the ordering of groups.

Pizzinelli et al. find that higher exposure can coexist with greater complementarity, particularly in highly educated occupations. That motivates our comparison; it does not predetermine Pakistan's results. The scores are constant within a mapped occupation, so group differences reflect occupational composition, not measured differences in individual AI use or a causal effect of education or sex. No survey-design-adjusted uncertainty is estimated, and the small differences should not be presented as established population effects.

The measures rely on US O*NET occupational characteristics and the technology coverage of the cited studies. Pakistan's tasks, working conditions, and AI adoption may differ. These are not continuously updated measures of the latest generative AI systems.

## 4. Run both examples in one script

The [complete analysis script](PAK_2024_LFS_V01_M_V01_A_GLD_ANALYSIS.do) runs both examples, reports coverage, and produces the graphs. Download it to your chosen script location. Pass the expanded-data folder, CSV folder, and log folder in that order:

```stata
local path_input "C:/your/path/gld_workshop"
local path_scores "C:/your/path/gld_workshop"
local path_output "C:/your/path/gld_workshop"
do "C:/your/path/gld_workshop/PAK_2024_LFS_V01_M_V01_A_GLD_ANALYSIS.do" ///
	"`path_input'" "`path_scores'" "`path_output'"
```

Run these lines together. The folders may be the same or different; no particular folder name or layout is required. The log folder must exist and be writable. Rerunning replaces the analysis log, not the expanded dataset or CSV. The linked scores remain in memory for further analysis.

We have used the same research dataset in two ways: adding analytical value from the survey itself, and joining an external source through a standard classification. That is the practical benefit of a documented, reusable harmonization.

## 5. Sources and attribution

Felten, E., Raj, M., & Seamans, R. (2021). Occupational, industry, and geographic exposure to artificial intelligence: A novel dataset and its potential uses. *Strategic Management Journal*, 42(12), 2195-2217. [doi:10.1002/smj.3286](https://doi.org/10.1002/smj.3286).

Pizzinelli, C., Panton, A., Tavares, M. M., Cazzaniga, M., & Li, L. (2023). *Labor Market Exposure to AI: Cross-country Differences and Distributional Implications*. [IMF Working Paper 23/216](https://www.imf.org/-/media/files/publications/wp/2023/english/wpiea2023216-print-pdf.pdf).

The mappings were shared with the GLD team by the authors of Pizzinelli et al. Please cite both papers when using the scores and retain the required disclaimer:

> The authors of the paper are solely responsible for this data. This data should not be interpreted as the official view of the International Monetary Fund, its Management, or its Board.
