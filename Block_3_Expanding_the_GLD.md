# Block 3: Expanding the GLD

**Pakistan LFS 2024-25 | Proposed duration: 35 minutes | Construct and check both additions**

This block adds variables, evaluates the effect of changing the ICLS definition, and produces the research dataset [Block 4](Block_4_Analysis.md) uses to study commuting and link external AI occupation scores. 

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

> **Start from the harmonized data and concentrate additional harmonization effort on the information required for your research question.**

## 2. Starting point

We begin where the previous workshop block ended.

We already have:

-   the original Pakistan LFS data;
-   the [questionnaire](Docs/Questionnaire-of-LFS-2024-25-Final.pdf) and [supporting documentation](https://github.com/worldbank/gld/tree/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS);
-   the GLD harmonization do-file; and
-   the harmonized GLD dataset produced by that do-file.

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

### Run the harmonization with additions

Continue with the working folder or folder layout you chose in Block 2. There is no requirement to create a new folder for this block. Feel free to do so if that is your preference.

Download [Build the expanded dataset](PAK_2024_LFS_V01_M_V01_A_GLD_ALL_EXPANDER.do), a copy of the harmonization from Block 2 with Section 8A added, to your chosen script location. It reads the original survey and lookup inputs from Block 2 and saves a separate `PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED.dta` dataset.

Before running it, replace its Section 1.2 path settings with your own locations, as shown in Section 3 below. The supplied file's paths are examples from the workshop author's setup, not required folders. Then run your edited copy, using its actual location; for a single-folder layout this could be:

``` stata
do "C:/your/path/gld_workshop/PAK_2024_LFS_V01_M_V01_A_GLD_ALL_EXPANDER.do"
```

Run the file in full so its local macros remain in scope. For participants executing the code, the software dependencies are the same as in [Block 2](../2%20-%20Recreate/Block_2_Reproduce_GLD.md), including internet access for classification validation.

------------------------------------------------------------------------

## 3. Where should additions go?

The GLD harmonization template separates the work into stages. For a research-specific expansion, there are three places to think about:

1.  **Section 1.2 --- directories and output name:** rename the output so the Block 2 file is not overwritten.
2.  **Section 8A --- user-defined additions:** create the additional variables after creating the standard ones.
3.  **Section 9 --- final steps:** add the new variables to the final `keep` list.

The GLD template defines the standard output in Section 1.2 as an `_ALL.dta` file. For our research version, we create a separate `_EXPANDED.dta` output. For example:

``` stata
*----------1.2: Set directories------------------------------*

local path_in_stata "C:/your/path/gld_workshop"
local path_output "`path_in_stata'"
local out_file "PAK_2024_LFS_V01_M_V01_A_GLD_EXPANDED"
```

Set `path_in_stata` to the folder containing your original survey and lookup inputs, not the recreated dataset. Set `path_output` to your chosen output folder; it may be the same folder, as above, or a separate existing, writable folder. Retain the other metadata locals in Section 1.2. The distinct output filename preserves the Block 2 `_RECREATED.dta` file even when both outputs share a folder. Rerunning the expander replaces the existing expanded output and regenerates the migration lookup in the input folder, which must also be writable.

After the standard harmonization has created its variables (last block to create variables is section 8), we insert a section 8A:

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
    Section 8A: user-defined additions
            |
            v
    Section 9: keep standard + added variables and save the expanded output
            |
            v
    Research analysis
```

The important distinction is that `_ALL` remains the standard GLD product. `_EXPANDED` (or other) is our research-specific version built from the same harmonization.

## 4. Add the new variables

We create both sets of additions in Section 8A before examining either one: parallel labour variables under ICLS-13, and variables describing workplace location and commuting.

The 2024 Pakistan LFS implements the newer ICLS framework. Under ICLS-19, own-use production is separated from employment for pay or profit. This changes the treatment of people engaged in farming, livestock rearing, or fishing mainly or only for family use.

The standard harmonized variable `lstatus` is coded as the survey intends. That is ICLS-19. This information is kept in the standard variable `icls_v`. We want to identify respondents whose classification would be different under ICLS-13. The exercise is to create parallel ICLS-13 variables without changing the standard GLD variables.

### 4.1. Add an alternative ICLS definition

We first identify own-use agricultural producers who are not employed under the ICLS-19 construction but would be treated as employed under ICLS-13. The code below is the code used in the expanded harmonization.

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

Then pass the local to the `keep` command in Section 9 alongside the standard GLD variables:

``` stata
/*%%=============================================================================================
    9: Final steps
=============================================================================================%%*/

quietly {
    keep `extension_vars' [STANDARD GLD VARIABLES]
}
```

This ensures that the new variables survive the final variable selection. Run the full expander now, including its final save command, to save the expanded dataset in your chosen output folder.

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

We have made two additions within the same harmonization workflow. One creates a transparent alternative definition; the other retains survey information outside the common dictionary and combines it with the standard GLD core.

```text
Original survey + existing GLD harmonization code
    -> standard GLD variables
    -> Section 8A: parallel ICLS variables + commuting variables
    -> Section 9: retain both sets and save _EXPANDED.dta
    -> Check saved variables and evaluate the ICLS results
    -> Block 4: analyse commuting and link external AI occupation scores
```

The demographic variables, classifications, identifiers, and weights remain available. We can now concentrate on research questions without rebuilding their construction. Keep the expanded dataset, the modified program, and a record of their locations so the additional decisions remain reproducible. Block 4 can use this output directly from wherever you saved it.

In [Block 4](Block_4_Analysis.md), we describe commuting patterns with and without the existing occupation variable `occup`. We then use the harmonized code `occup_isco` to link external AI scores and compare worker groups using GLD's education, sex, and weight variables.
