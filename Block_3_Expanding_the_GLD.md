# Block 3: Expanding the GLD

**Pakistan LFS 2024-25 | Proposed duration: 35 minutes | Construct and check both additions**

This block builds on the corrected harmonization program you created in Block 2. You will add variables, evaluate the effect of changing the ICLS definition, and produce the research dataset [Block 4](Block_4_Analysis.md) uses to study commuting and link external AI occupation scores.

## 1. Introduction

In the previous blocks, we introduced the Global Labour Database (GLD), its data dictionary, and the harmonization workflow. We then reproduced a harmonization from the original survey data and created a standard harmonized GLD dataset.

In this block, we take the next step. Rather than asking **how do we harmonize an entire labour force survey?**, we ask:

> **How can we adapt an existing GLD harmonization to the needs of a particular research project?**

A harmonized dataset gives us a standardized analytical core. Variables such as labour force status, education, occupation, industry, employment status, demographic characteristics, geography, and survey weights have already been constructed and documented. For many research projects, most of the work has therefore already been done.

A researcher may only need to understand a small part of the original questionnaire and add a few variables relevant to the particular research question. This can substantially reduce the time between obtaining a survey and beginning substantive analysis.

In this exercise, we use the **Pakistan Labour Force Survey (LFS) 2024** to examine two different ways in which researchers may want to expand a GLD harmonization:

1.  **Creating an alternative version of a concept that already exists in the GLD dictionary.**\
    We reconstruct labour-market variables using an alternative ICLS definition.

2.  **Adding information that is not included in the standard GLD dictionary.**\
    We add information about workplace location and commuting time and use it to construct new analytical variables.

These are different ways to expand the GLD, but the principle is the same:

> **Build on your working harmonization program and concentrate additional effort on the information required for your research question.**

## 2. Starting point

We begin where the previous workshop block ended.

We already have:

-   the original Pakistan LFS data;
-   the [questionnaire](Docs/Questionnaire-of-LFS-2024-25-Final.pdf) and [supporting documentation](https://github.com/worldbank/gld/tree/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS);
-   your corrected harmonization do-file from Block 2; and
-   the standard harmonized GLD dataset you saved locally with that do-file.

We do **not** need to write the harmonization again. We will add code to a copy of your working program and rerun it from the original survey inputs. We are not adding variables directly to the saved Block 2 dataset, because the new variables use source questions that the standard output does not retain.

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

### Continue with your Block 2 program

Continue with the working folder or folder layout you chose in Block 2. There is no requirement to create a new folder for this block. Feel free to do so if that is your preference.

Use **Save As** on the corrected Block 2 program to make a second copy, for example `PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDER.do`. Keep your Block 2 version unchanged so it still reproduces the standard harmonization. You will add the Block 3 variables to this copy.

Your copy already contains your corrected input filename, path settings, and other repairs from Block 2. Keep them. Work through Sections 3 and 4 below to change the output name and add the research variables before running the program.

The inputs and software dependencies remain those used in [Block 2](../2%20-%20Recreate/Block_2_Reproduce_GLD.md), including internet access for classification validation. No new harmonization do-file is needed.

------------------------------------------------------------------------

## 3. Where should additions go?

The GLD harmonization template separates the work into stages. For a research-specific expansion, there are three places to think about:

1.  **Section 1.2 --- directories and output name:** in your copied Block 2 program, change the output name so the Block 2 file is not overwritten.
2.  **Section 8A --- user-defined additions:** create the additional variables after creating the standard ones.
3.  **Section 9 --- final steps:** add the new variables to the final `keep` list.

In Block 2, you set the output name to `_RECREATED.dta`. In Section 1.2 of your copied program, replace only the `out_file` definition with:

``` stata
local out_file "`level_2_harm'_EXPANDED.dta"
```

Retain all the path and metadata locals you defined in Block 2, including `level_2_harm`. The new filename will be `PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED.dta`, saved in your existing `path_output` folder. You may choose a different existing, writable output folder if you prefer, but there is no need to change the input paths. The distinct filename preserves your `_RECREATED.dta` output. Rerunning the expanded program replaces its expanded output and regenerates the migration lookup in the input folder, just as in Block 2.

Next, insert a new Section 8A between the end of Section 8 and the start of Section 9 in your copied program. Leave the existing Section 8 code intact. The outline below shows the insertion point; the bracketed text is a placeholder, not executable Stata code:

``` stata

/*%%=============================================================================================
	8: Labour
==============================================================================================%%*/

    [CONTENT OF SECTION 8]

*</_% Correction min age_>
}

/*%%=============================================================================================
    8A: User-defined additions
=============================================================================================%%*/

    [YOUR CONTENT TO BE ADDED HERE]

/*%%=============================================================================================
	9: Final steps
==============================================================================================%%*/

```

This keeps our additions separate from the standard GLD construction.

Finally, Section 9 explicitly controls the variables retained in the output. You will add the new variables to its existing `keep` statement in Section 4.3 below, retaining the standard variable list and the rest of the final steps. Conceptually, the workflow is:

``` text
    Original survey files
            |
            v
    Section 1.2: retain your paths and change the output name
            |
            v
    Sections 2–8: standard GLD harmonization
            |
            v
    Section 8A: user-defined additions
            |
            v
    Section 9: keep standard + added variables and save the expanded output
            |
            v
    Research analysis
```

Your Block 2 program and `_RECREATED.dta` output remain the standard reproduction. The copied program and `_EXPANDED.dta` output are your research-specific version built from that same harmonization.

## 4. Add the new variables

Insert the construction code from Sections 4.1 and 4.2 into your new Section 8A, in the order shown. We create both sets of additions before examining either one: parallel labour variables under ICLS-13, and variables describing workplace location and commuting.

The 2024 Pakistan LFS implements the newer ICLS framework. Under ICLS-19, own-use production is separated from employment for pay or profit. This changes the treatment of people engaged in farming, livestock rearing, or fishing mainly or only for family use.

The standard harmonized variable `lstatus` is coded as the survey intends. That is ICLS-19. This information is kept in the standard variable `icls_v`. We want to identify respondents whose classification would be different under ICLS-13. The exercise is to create parallel ICLS-13 variables without changing the standard GLD variables.

### 4.1. Add an alternative ICLS definition

We first identify own-use agricultural producers who are not employed under the ICLS-19 construction but would be treated as employed under ICLS-13. Add the following code at the start of Section 8A in your copied program.

``` stata
* ------------------------------------------------------------------
* ICLS 13th BRIDGE CODE — PAK LFS 2024
* ------------------------------------------------------------------

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

Our second addition brings in information that is not part of the standard GLD dictionary. The questionnaire records workplace location in `s5c22` and commuting time in `s5c23`. We retain those two variables and derive two analytical variables by combining them with the existing GLD variable `urban`.

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

### 4.3. Retain the added variables

At the end of Section 8A, collect all ten additions in a local macro:

``` stata
local extension_vars extra_icls_13_emp lstatus_13 empstat_13 ocusec_13 ///
    industrycat10_13 occup_13 work_location commute_time work_mobility long_commute
```

In the existing Section 9 `keep` command, insert `extension_vars` as a macro reference before the standard variable list, as illustrated below. Keep that list and the remaining Section 9 code unchanged; do not paste the placeholder `[STANDARD GLD VARIABLES]` into your program.

``` stata
/*%%=============================================================================================
    9: Final steps
=============================================================================================%%*/

quietly {
    keep `extension_vars' [STANDARD GLD VARIABLES]
}
```

This ensures that the new variables survive the final variable selection. Keep the existing final save command: it uses the output name you changed in Section 1.2.

Save your edits, then run the **whole copied do-file**, not just Section 8A, so the local macros remain in scope. Use your actual script location and filename; for the example name in Section 2:

```stata
do "C:/your/path/gld_workshop/PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDER.do"
```

The program reads your original inputs, reruns the standard harmonization, constructs the additions, and saves the expanded dataset in your chosen output folder.

## 5. Check the saved file and evaluate the ICLS results

Open the file saved at the end of Section 4 and confirm that all ten added variables are present with a single command. Set `path_output` below to your chosen output folder and run the block together:

```stata
local path_output "C:/your/path/gld_workshop"
use "`path_output'/PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED.dta", clear
confirm variable extra_icls_13_emp lstatus_13 empstat_13 ocusec_13 ///
    industrycat10_13 occup_13 work_location commute_time work_mobility long_commute
```

We now have the standard variables and their alternative ICLS-13 counterparts:

| Standard GLD | ICLS-13 alternative |
| --- | --- |
| `lstatus` | `lstatus_13` |
| `empstat` | `empstat_13` |
| `ocusec` | `ocusec_13` |
| `industrycat10` | `industrycat10_13` |
| `occup` | `occup_13` |

The standard variables remain untouched. The `_13` variables make the alternative definition explicit and can be used directly in analysis. The weighted results for respondents aged 15 and above show the impact of the definition change:

| Indicator | ICLS-13 | ICLS-19 |
| --- | ---: | ---: |
| Labour force participation rate | 55.26% | 53.79% |
| Unemployment rate | 6.86% | 7.05% |
| Share of workers in agriculture | 34.45% | 32.53% |
| Share of paid employees among agricultural workers | 13.60% | 14.83% |
| Share of paid employees among all workers | 42.50% | 43.75% |

Including own-use agricultural producers as employed raises labour force participation and agriculture's share of employment. The unemployment rate falls as the labour force denominator grows. Paid-employee shares fall because the additional workers are classified as self-employed. These differences follow the definition and the assigned characteristics discussed in Section 4.1; they are not interchangeable estimates of an unchanged concept.

Labour force participation uses respondents with valid labour status as its denominator; unemployment uses the labour force; agricultural employment and paid-employee shares use the relevant employed group. These are weighted point estimates, not survey-design-adjusted uncertainty estimates.

Run the following code together to check key weighted totals underlying the comparison against the expected results for this release. The category assertions ensure that the matrix entries refer to the intended groups; the totals are checked within one weighted person to allow for rounding. These checks support the comparison but do not independently test every percentage in the table.

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

An assertion passes silently and stops with an error if the expected result does not match. If it fails, inspect the inputs and expansion code before changing the expected values.

> A harmonized variable is not only a variable name and coding scheme. Its underlying statistical definition matters as well. When a research question requires another definition, we can construct a transparent parallel version without reharmonizing the rest of the survey.

## 6. Carry forward to analysis

We have added two research components to the Block 2 harmonization. One creates a transparent alternative definition; the other retains survey information outside the common dictionary and combines it with the standard GLD core.

```text
Original survey + your corrected Block 2 program, copied for expansion
    -> standard GLD variables
    -> Section 8A: parallel ICLS variables + commuting variables
    -> Section 9: retain both sets and save _EXPANDED.dta
    -> Check saved variables and evaluate the ICLS results
    -> Block 4: analyse commuting and link external AI occupation scores
```

The demographic variables, classifications, identifiers, and weights remain available. We can now concentrate on research questions without rebuilding their construction. Keep both do-files, the original inputs, the expanded dataset, and a record of their locations so the additional decisions remain reproducible. Block 4 can use this output directly from wherever you saved it.

In [Block 4](Block_4_Analysis.md), we describe commuting patterns with and without the existing occupation variable `occup`. We then use the harmonized code `occup_isco` to link external AI scores and compare worker groups using GLD's education, sex, and weight variables.
