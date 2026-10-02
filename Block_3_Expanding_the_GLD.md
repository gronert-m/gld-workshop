# Block 3: Extending the GLD

## 1. Introduction

In the previous blocks, we introduced the Global Labour Database (GLD), its data dictionary, and the harmonization workflow. We then reproduced a harmonization from the original survey data and created a standard harmonized GLD dataset.

In this block, we take the next step. Rather than asking **how do we harmonize an entire labour force survey?**, we ask:

> **How can we adapt an existing GLD harmonization to the needs of a particular research project?**

A harmonized dataset gives us a standardized analytical core. Variables such as labour force status, education, occupation, industry, employment status, demographic characteristics, geography, and survey weights have already been constructed and documented. For many research projects, most of the work has therefore already been done.

A researcher may only need to understand a small part of the original questionnaire and add a few variables relevant to the particular research question. This can substantially reduce the time between obtaining a survey and beginning substantive analysis.

In this exercise, we use the **Pakistan Labour Force Survey (LFS) 2024** to examine two different ways in which researchers may want to extend a GLD harmonization:

1.  **Creating an alternative version of a concept that already exists in the GLD dictionary.**\
    We reconstruct labour-market variables using an alternative ICLS definition.

2.  **Adding information that is not included in the standard GLD dictionary.**\
    We add information about workplace location and commuting time and use it to construct new analytical variables.

These are different kinds of extensions, but the principle is the same:

> **Start from the harmonized data and concentrate additional harmonization effort on the information required for your research question.**

## 2. Starting point

We begin where the previous workshop block ended.

We already have:

-   the original Pakistan LFS data;
-   the questionnaire and supporting documentation;
-   the GLD harmonization do-file.

We do **not** need to reconstruct the entire harmonization.

The existing program has already done substantial work for us. For example, it has constructed variables such as:

-   `urban`: rural or urban place of residence;
-   `lstatus`: labour force status;
-   `empstat`: employment status;
-   `industrycat10`: broad industry classification;
-   `occup`: one-digit occupational classification;
-   demographic and education variables;
-   identifiers; and
-   survey weights.

Our task is to identify what additional information our research requires.

## 3. Where should extensions go?

The GLD harmonization template separates the work into stages. For a research-specific extension, there are three places to think about:

1.  **Section 1.2 --- directories and output name:** rename the output so the Block 2 file is not overwritten.
2.  **Section 8A --- user-defined extensions:** create the additional variables after creating the standard ones.
3.  **Section 9 --- final steps:** add the new variables to the final `keep` list.

The GLD template defines the standard output in Section 1.2 as an `_ALL.dta` file. For our research version, we create a separate `_EXPANDED.dta` output. For example:

``` stata
*----------1.2: Set directories------------------------------*

** Ad-Hoc paths for Expansion Exercise
local gen_path "C:/Users/wb529026/WBG/WKPEJ Files - GLD Expansion - P509260/Dissemination and Tracking GLD Use/GLD Workshop/Examples"
local path_in_stata "`gen_path'/1 - Recreate"

local path_output "`gen_path'/2 - Expand"
local out_file "PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED.dta"
```

After the standard harmonization has created its variables (last block to create variables is section 8), we insert a section 8A:

``` stata

/*%%=============================================================================================
	8: Labour
==============================================================================================%%*/

    [CONTENT OF SECTION 8]

*</_% Correction min age_>
}

/*%%=============================================================================================
    8A: User-defined extensions
=============================================================================================%%*/

    [YOUR CONTENT TO BE ADDED HERE]

/*%%=============================================================================================
	9: Final steps
==============================================================================================%%*/

```

This keeps our additions separate from the standard GLD construction.

Finally, Section 9 matters because the harmonization explicitly controls the variables retained in the output. The variables created in Section 8A therefore need to be added to the final `keep` statement. For this exercise that includes, for example:

``` stata
keep [**vars already in GLD dictionary standard set**] [**variables we added**]
```

and save it to as the new expansion file. Conceptually, the workflow is therefore:

``` text
    Original survey files
            |
            v
    Section 1.2: define your paths
            |
            v
    Sections 2–8: standard GLD harmonization
            |
            v
    Section 8A: user-defined extensions
            |
            v
    Section 9: keep standard + extension variables and save the expanded output
            |
            v
    Research analysis
```

The important distinction is that `_ALL` remains the standard GLD product. `_EXPANDED` (or other) is our research-specific version built from the same harmonization.

## 4. Add the extension variables

We create both sets of additions in Section 8A before examining either one: parallel labour variables under ICLS-13, and variables describing workplace location and commuting.

The 2024 Pakistan LFS implements the newer ICLS framework. Under ICLS-19, own-use production is separated from employment for pay or profit. This changes the treatment of people engaged in farming, livestock rearing, or fishing mainly or only for family use.

The standard harmonized variable `lstatus` is coded as the survey intends. That is ICLS-19. This information is kept in the standard variable `icls_v`. We want to identify respondents whose classification would be different under ICLS-13. The exercise is to create parallel ICLS-13 variables without changing the standard GLD variables.

### 4.1. Add an alternative ICLS definition

We first identify own-use agricultural producers who are not employed under the ICLS-19 construction but would be treated as employed under ICLS-13. The code below is the code used in the expanded harmonization.

``` stata
* ------------------------------------------------------------------
* 1. Identify respondents employed under ICLS-13 but not ICLS-19
* ------------------------------------------------------------------

gen byte extra_icls_13_emp = 0
* own-use farming/livestock/fishing through S5C10
replace extra_icls_13_emp = 1 if inrange(s5c10, 3, 4) & inlist(lstatus, 2, 3)
label variable extra_icls_13_emp "Additional employed under ICLS-13 definition"
```

The `inlist(lstatus, 2, 3)` condition is deliberate. These respondents are already classified under ICLS-19 as unemployed or outside the labour force. The issue is not missing information; the employment definition changes their classification.

Once we treat this group as employed, we also need employment characteristics for them. Under the standard ICLS-19 construction these variables are missing because they are defined only for employed respondents. We therefore create the parallel variables in the same step: self-employment, private/NGO sector, agriculture, and skilled agricultural occupation are assigned characteristics, not observed answers to the skipped employment questions. The approach shown below mirrors the one used by the ILO's ILOSTAT team when differentiating between ICLS-13 and ICLS-19 versions.

``` stata
* ------------------------------------------------------------------
* 2. Construct parallel ICLS-13 variables
* ------------------------------------------------------------------

* Labour-force status
gen byte lstatus_13 = lstatus
replace lstatus_13  = 1 if extra_icls_13_emp == 1
label variable lstatus_13 "Labor status - 13th ICLS definition"
label values lstatus_13 lbllstatus

* Employment status: self-employed
gen byte empstat_13 = empstat
replace empstat_13 = 4 if extra_icls_13_emp == 1
replace empstat_13 = . if lstatus_13 != 1
label variable empstat_13 "Employment status - 13th ICLS definition"
label values empstat_13 lblempstat

* Sector: Private / NGO
gen byte ocusec_13 = ocusec
replace ocusec_13 = 2 if extra_icls_13_emp == 1
replace ocusec_13 = . if lstatus_13 != 1
label variable ocusec_13 "Sector of activity - 13th ICLS definition"
label values ocusec_13 lblocusec

* Industry: Agriculture
gen byte industrycat10_13 = industrycat10
replace industrycat10_13 = 1 if extra_icls_13_emp == 1
replace industrycat10_13 = . if lstatus_13 != 1
label variable industrycat10_13 "Industry category - 13th ICLS definition"
label values industrycat10_13 lblindustrycat10

* Occupation: Skilled agricultural
gen byte occup_13 = occup
replace occup_13 = 6 if extra_icls_13_emp == 1
replace occup_13 = . if lstatus_13 != 1
label variable occup_13 "Occupation - 13th ICLS definition"
label values occup_13 lbloccup
```

### 4.2. Add the commuting variables

Our second extension adds information that is not part of the standard GLD dictionary. The questionnaire records workplace location in `s5c22` and commuting time in `s5c23`. We retain those two variables and derive two analytical variables by combining them with the existing GLD variable `urban`.

``` stata
* Assert ranges are correct
assert inlist(s5c22, 1, 2) | missing(s5c22)
assert inrange(s5c23, 1, 4) | missing(s5c23)

* Add work location
gen byte work_location = s5c22
label define lblwork_location 1 "Rural" 2 "Urban"
label values work_location lblwork_location
label var work_location "Location of workplace"

* Add commute time
gen byte commute_time = s5c23
label define lblcommute_time 1 "Less than 30 minutes" 2 "31-45 minutes" ///
    3 "46-60 minutes" 4 "61 minutes or more"
label values commute_time lblcommute_time
label var commute_time "Time to reach workplace"

* Combine residence and workplace location
gen byte work_mobility = .
replace work_mobility = 1 if urban == 0 & work_location == 1
replace work_mobility = 2 if urban == 0 & work_location == 2
replace work_mobility = 3 if urban == 1 & work_location == 1
replace work_mobility = 4 if urban == 1 & work_location == 2
label define work_mobility_lbl 1 "Rural -> Rural" 2 "Rural -> Urban" ///
    3 "Urban -> Rural" 4 "Urban -> Urban"
label values work_mobility work_mobility_lbl
label var work_mobility "Residence-to-work rural/urban pattern"

* Reduce commute time to two categories
gen byte long_commute = .
replace long_commute = 0 if inlist(commute_time, 1, 2)
replace long_commute = 1 if inlist(commute_time, 3, 4)
label define long_commute_lbl 0 "45 minutes or less" 1 "More than 45 minutes"
label values long_commute long_commute_lbl
label var long_commute "Commute time greater than 45 minutes"
```

`work_location` and `commute_time` retain the questionnaire categories. `work_mobility` distinguishes rural-to-rural, rural-to-urban, urban-to-rural, and urban-to-urban workers. `long_commute` identifies commutes exceeding 45 minutes.

### 4.3. Retain the extension variables

At the end of Section 8A, collect all ten additions in a local macro:

``` stata
local extension_vars extra_icls_13_emp lstatus_13 empstat_13 ocusec_13 ///
    industrycat10_13 occup_13 work_location commute_time work_mobility long_commute
```

Then pass the local to the `keep` command in Section 9 alongside the standard GLD variables:

``` stata
/*%%=============================================================================================
    9: Final steps
=============================================================================================%%*/

quietly {
    keep `extension_vars' [STANDARD GLD VARIABLES]
}
```

This ensures that the new variables survive the final variable selection and are saved in the expanded dataset.

## 5. Evaluate the ICLS results

We now have the standard variables and their alternative ICLS-13 counterparts:

  Standard GLD      ICLS-13 extension
  ----------------- ---------------------
    `lstatus`         `lstatus_13`
    `empstat`         `empstat_13`
    `ocusec`          `ocusec_13`
    `industrycat10`   `industrycat10_13`
    `occup`           `occup_13`

The standard variables remain untouched. The `_13` variables make the alternative definition explicit and can be used directly in analysis. Below a comparison of the results with one and the other. We can clearly see the impact of the definition change. 

| Indicator | ICLS-13 | ICLS-19 |
| --- | ---: | ---: |
| Labour force participation rate | 55.26% | 53.79% |
| Unemployment rate | 6.86% | 7.05% |
| Share of workers in agriculture | 34.45% | 32.53% |
| Share of paid employees among agricultural workers | 13.60% | 14.83% |
| Share of paid employees among all workers | 42.50% | 43.75% |

The below is the code to check the results agree:

``` stata
tab lstatus if inrange(age, 15, 999) [iw=weight], matcell(freq) matrow(vals)
matrix lstatus_freq = freq
matrix lstatus_vals = vals

tab lstatus_13 if inrange(age, 15, 999) [iw=weight], matcell(freq) matrow(vals)
matrix lstatus_13_freq = freq
matrix lstatus_13_vals = vals

tab empstat if industrycat10 == 1 & inrange(age, 15, 999) [iw=weight], matcell(freq) matrow(vals)
matrix empstat_ag_freq = freq
matrix empstat_ag_vals = vals

tab empstat_13 if industrycat10_13 == 1 & inrange(age, 15, 999) [iw=weight], matcell(freq) matrow(vals)
matrix empstat_13_ag_freq = freq
matrix empstat_13_ag_vals = vals

assert lstatus_vals[1,1] == 1
assert lstatus_13_vals[1,1] == 1
assert empstat_ag_vals[4,1] == 4
assert empstat_13_ag_vals[4,1] == 4

assert abs(lstatus_freq[1,1] - 75396847.4) < 1
assert abs(lstatus_13_freq[1,1] - 77607254) < 1
assert abs(empstat_ag_freq[4,1] - 9876372.7) < 1
assert abs(empstat_13_ag_freq[4,1] - 12086779.3) < 1
```

> A harmonized variable is not only a variable name and coding scheme. Its underlying statistical definition matters as well. When a research question requires another definition, we can construct a transparent parallel version without reharmonizing the rest of the survey.

## 6. Use the commuting variables

We now use the expanded dataset to study how commuting differs across rural and urban places of residence and work. The examples below deliberately use **unweighted sample estimates**. Their Pearson tests and model standard errors do not account for the survey design, and the associations are not causal effects. Population inference requires an appropriate specification of weights, strata, and PSUs using the survey documentation.

### 6.1. Describe commuting patterns

Before constructing a model, start with the data. Missing commuting responses are not treated as zero commutes.

``` stata
tab work_mobility commute_time, row chi2
```

The row percentages show a striking pattern.

| Residence-to-work pattern | <30 min | 31–45 min | 46–60 min | 61+ min |
|---|---:|---:|---:|---:|
| Rural → Rural | 80.45% | 14.50% | 2.82% | 2.23% |
| Rural → Urban | 40.22% | 30.88% | 12.28% | 16.62% |
| Urban → Rural | 64.99% | 22.17% | 6.83% | 6.01% |
| Urban → Urban | 64.38% | 24.75% | 7.32% | 3.55% |

Rural-to-rural workers have the shortest observed commuting times.

Rural-to-urban workers stand out in the opposite direction. Only around 40 percent report commuting less than 30 minutes, while approximately 29 percent report commuting more than 45 minutes.

The Pearson chi-square test rejects independence between the two variables (`p < .001`).

We can also compare residence-to-work patterns using the `long_commute` indicator created in Section 4.2:

``` stata
tab work_mobility long_commute, row chi2
```

We obtain:

| Residence-to-work pattern | ≤45 minutes | >45 minutes |
|---|---:|---:|
| Rural → Rural | 94.95% | 5.05% |
| Rural → Urban | 71.09% | 28.91% |
| Urban → Rural | 87.16% | 12.84% |
| Urban → Urban | 89.13% | 10.87% |
| **Total** | **89.64%** | **10.36%** |

The contrast is now particularly easy to see. Around **5 percent** of rural-to-rural workers have commutes exceeding 45 minutes, compared with almost **29 percent** of rural-to-urban
workers.

This is information that we could not have obtained from the standard GLD variables alone.

### 6.2. Estimate a simple model

We can formalize the comparison using logistic regression.

Because `work_mobility` is categorical, we use Stata's factor-variable notation:

``` stata
logistic long_commute ib1.work_mobility
```

The `i.` tells Stata to treat the variable as categorical, while `b1` selects category 1---`Rural -> Rural`---as the reference category.

The estimated odds ratios are approximately:

| Residence-to-work pattern | Odds ratio |
|---|---:|
| Rural → Rural | Reference |
| Rural → Urban | 7.64 |
| Urban → Rural | 2.77 |
| Urban → Urban | 2.29 |

For rural-to-urban workers, the odds ratio of 7.64 means that the
**odds** of a commute exceeding 45 minutes are estimated to be 7.64
times the odds for rural-to-rural workers.

That is not the same as saying that rural-to-urban workers are "7.64
times more likely" to have a long commute. Odds and probabilities are
different quantities.

The descriptive probabilities make the distinction concrete. In our
data:

``` text
Rural -> Rural:   5.05% have a commute >45 minutes
Rural -> Urban:  28.91% have a commute >45 minutes
```

For rural-to-rural workers, the odds are approximately:

``` text
0.0505 / (1 - 0.0505) = 0.053
```

For rural-to-urban workers:

``` text
0.2891 / (1 - 0.2891) = 0.407
```

and:

``` text
0.407 / 0.053 ≈ 7.64
```

So the model's 7.64 odds ratio corresponds here to an observed long-commute share rising from about **5% to 29%**. In probability terms, that is about **24 percentage points higher**, or roughly **5.7 times the probability**. The latter is a descriptive probability ratio, not the logistic-regression odds ratio.

### 6.3. Add occupation

So far, our analysis has used:

``` text
urban                Standard GLD variable
work_location        Our extension
commute_time         Our extension
```

We can now bring another standard harmonized variable back into the analysis. The GLD harmonization already provides `occup`, a one-digit occupational
classification. This is where the benefit of extending an existing harmonization becomes especially clear. We do not need to go back to the original occupational codes, understand
the classification, convert them to ISCO, and construct broad occupational groups. That work has already been done. We can simply estimate:

``` stata
logistic long_commute ib1.work_mobility i.occup
```

This asks whether differences across residence-to-work patterns remain after accounting for differences in occupational composition.

The residence-to-work estimates become:

| Residence-to-work pattern | Unadjusted OR | Occupation-adjusted OR |
|---|---:|---:|
| Rural → Rural | Reference | Reference |
| Rural → Urban | 7.64 | 4.64 |
| Urban → Rural | 2.77 | 2.35 |
| Urban → Urban | 2.29 | 1.39 |

The association becomes smaller after occupation is introduced. The change is particularly substantial for rural-to-urban and urban-to-urban workers.

## 7. Conclusion

Extending GLD does not mean reharmonizing the survey. The standard demographic and labour variables, classifications, identifiers, and weights remain available; the researcher concentrates on the additional information required for the research question.

This exercise illustrated two forms of extension. First, we created transparent parallel variables when the analysis required an alternative definition of a concept already represented in GLD:

``` text
Standard GLD                  ICLS-13 extension
lstatus             ->       lstatus_13
empstat             ->       empstat_13
industrycat10       ->       industrycat10_13
occup               ->       occup_13
```

Second, we retained information outside the common GLD dictionary and combined it with the harmonized core:

``` text
s5c22 + GLD urban    ->       work_mobility
s5c23                ->       commute_time and long_commute
GLD occup            ->       occupation-adjusted analysis
```

A common dictionary makes comparison possible, but it cannot contain every useful question asked in every labour force survey. Starting from GLD allows researchers to preserve the standard harmonization, document their additions separately, and spend more time on the analysis for which the data were obtained.
