# Block 3 --- Extending the GLD

## 1. Introduction

In the previous blocks, we introduced the Global Labour Database (GLD),
its data dictionary, and the harmonization workflow. We then reproduced
a harmonization from the original survey data and created a standard
harmonized GLD dataset.

In this block, we take the next step. Rather than asking **how do we
harmonize an entire labour force survey?**, we ask:

> **How can we adapt an existing GLD harmonization to the needs of a
> particular research project?**

A harmonized dataset gives us a standardized analytical core. Variables
such as labour force status, education, occupation, industry, employment
status, demographic characteristics, geography, and survey weights have
already been constructed and documented.

For many research projects, most of the work has therefore already been
done.

A researcher may only need to understand a small part of the original
questionnaire and add a few variables relevant to the particular
research question.

This can substantially reduce the time between obtaining a survey and
beginning substantive analysis.

In this exercise, we use the **Pakistan Labour Force Survey (LFS) 2024**
to examine two different ways in which researchers may want to extend a
GLD harmonization:

1.  **Creating an alternative version of a concept that already exists
    in the GLD dictionary.**\
    We reconstruct labour-market variables using an alternative ICLS
    definition.

2.  **Adding information that is not included in the standard GLD
    dictionary.**\
    We add information about workplace location and commuting time and
    use it to construct new analytical variables.

These are different kinds of extensions, but the principle is the same:

> **Start from the harmonized data and concentrate additional
> harmonization effort on the information required for your research
> question.**

------------------------------------------------------------------------

## 2. Starting point

We begin where the previous workshop block ended.

We already have:

-   the original Pakistan LFS data;
-   the questionnaire and supporting documentation;
-   the GLD harmonization do-file; and
-   the harmonized GLD dataset produced by that do-file.

We do **not** need to reconstruct the entire harmonization.

The existing program has already done substantial work for us. For
example, it has constructed variables such as:

-   `urban`: rural or urban place of residence;
-   `lstatus`: labour force status;
-   `empstat`: employment status;
-   `industrycat10`: broad industry classification;
-   `occup`: one-digit occupational classification;
-   demographic and education variables;
-   identifiers; and
-   survey weights.

Our task is to identify what additional information our research
requires.

### Run the accompanying do-files

There are two runnable files:

- [Build the extended dataset](PAK_2024_LFS_V01_M_V01_A_GLD_MINE.do): a copy of the Exercise 1 harmonization with Section 8A added. It reads the inputs in `1 - Recreate` and saves a separate `_MINE.dta` in `2 - Expand`. It leaves the supplied standard do-file and datasets unchanged.
- [Run the analysis](PAK_2024_LFS_V01_M_V01_A_GLD_ANALYSIS.do): reads `_MINE.dta`, compares the ICLS definitions, and runs the commuting tables, models, margins, and plots. It writes a separate text log, replacing that log on subsequent runs.

Set Stata's working directory to the workshop's `Examples` folder, then run these commands in order:

``` stata
cd "C:/your/path/Examples"
do "2 - Expand/PAK_2024_LFS_V01_M_V01_A_GLD_MINE.do"
do "2 - Expand/PAK_2024_LFS_V01_M_V01_A_GLD_ANALYSIS.do"
```

Alternatively, pass the full `Examples` path as a quoted argument to either do-file. Run each file in full so its local macros remain in scope. The software dependencies are the same as in [Exercise 1](../1%20-%20Recreate/Exercise_1_Recreate_GLD.md), including internet access for classification validation.

For convenience, the build script creates `work_mobility` and `long_commute` in Section 8A as well as the source-based extensions, and retains all ten added variables in Section 9. The analysis script therefore starts from the saved research dataset; the snippets below explain how its variables were constructed rather than requiring you to generate them a second time.

------------------------------------------------------------------------

## 3. Where should extensions go?

The GLD harmonization template separates the work into stages. For a
research-specific extension, there are four places to think about:

1.  **Section 1.2 --- directories and output name:** define a separate
    output so the standard GLD file is not overwritten.
2.  **Section 1.3 --- database assembly:** make sure the source
    variables needed for the extension are present in the assembled
    working file.
3.  **Section 8A --- user-defined extensions:** create the additional
    harmonized variables after the standard labour variables have been
    constructed.
4.  **Section 9 --- final steps:** add the new variables to the final
    `keep` list so that they survive into the saved analytical file.

The GLD template defines the standard output in Section 1.2 as an
`_ALL.dta` file. For our research version, we create a separate
`_MINE.dta` output. For example:

``` stata
*----------1.2: Set directories------------------------------*

* Standard GLD output
local out_file "`level_2_harm'_ALL.dta"

* Personal research output used in this exercise
local out_file_mine "`level_2_harm'_MINE.dta"
```

Section 1.3 is where the source datasets are assembled. If an extension
requires variables that were not needed by the standard harmonization,
this is where we make sure they enter the working dataset. In the
Pakistan example, the additional commuting variables are:

``` stata
s5c22    // location of work
s5c23    // time to reach workplace
```

The precise assembly code depends on the survey structure: they may
already be in the working file, or they may need to be retained from or
merged in from a source file. The point is simply that by the end of
Section 1.3 the variables needed for Section 8A must be available.

After the standard harmonization has created its variables, we insert:

``` stata
/*%%=============================================================================================
    8A: User-defined extensions
=============================================================================================%%*/
```

This keeps our additions separate from the standard GLD construction.

Finally, Section 9 matters because the harmonization explicitly controls
the variables retained in the output. The variables created in Section
8A therefore need to be added to the final `keep` statement. For this
exercise that includes, for example:

``` stata
keep ... ///
    extra_icls_13_emp lstatus_old empstat_old ocusec_old ///
    industrycat10_old occup_old ///
    work_location commute_time
```

and we save the research version separately:

``` stata
save "`path_output'/`out_file_mine'", replace
```

Conceptually, the workflow is therefore:

``` text
Original survey files
        |
        v
Section 1.3: assemble the source data
and retain any additional variables needed
        |
        v
Sections 2–8: standard GLD harmonization
        |
        v
Section 8A: user-defined extensions
        |
        v
Section 9: keep standard + extension variables
and save the _MINE output
        |
        v
GLD_MINE.dta
        |
        v
Research analysis
```

The important distinction is that `_ALL` remains the standard GLD
product. `_MINE` is our research-specific version built from the same
harmonization.

## 4. Example 1: Alternative ICLS definitions

Our first extension concerns a concept that already exists in GLD:
**employment**.

The 2024 Pakistan LFS implements the newer ICLS framework. Under
ICLS-19, own-use production is separated from employment for pay or
profit. This changes the treatment of people engaged in farming,
livestock rearing, or fishing mainly or only for family use.

The standard harmonized variable `lstatus` is already complete for the
labour-status universe: respondents are classified as employed,
unemployed, or outside the labour force. We are therefore **not filling
missing labour status**. We are identifying respondents whose
classification would be different under ICLS-13.

The exercise is to create parallel ICLS-13 variables without changing
the standard GLD variables.

------------------------------------------------------------------------

## 5. Identify the ICLS-13 group and construct the parallel variables

We first identify own-use agricultural producers who are not employed
under the ICLS-19 construction but would be treated as employed under
ICLS-13.

There are two questionnaire routes into this group.

``` stata
* ------------------------------------------------------------------
* ICLS-13 bridge — Pakistan LFS 2024
* ------------------------------------------------------------------

gen byte extra_icls_13_emp = 0

* Path A: farming/livestock/fishing reported through S5C9,
* with production mainly or only for family use
replace extra_icls_13_emp = 1 if ///
    inrange(s5c9, 1, 3) & ///
    inrange(s5c10, 3, 4) & ///
    inlist(lstatus, 2, 3)

* Path B: alternative agricultural-work route through S5C8,
* again with production mainly or only for family use
replace extra_icls_13_emp = 1 if ///
    s5c1 == 2 & ///
    s5c2 == 2 & ///
    s5c3 == 2 & ///
    s5c4 == 2 & ///
    inrange(s5c8, 1, 3) & ///
    inrange(s5c10, 3, 4) & ///
    inlist(lstatus, 2, 3)

label var extra_icls_13_emp ///
    "Additional employed under ICLS-13 definition"
```

The `inlist(lstatus, 2, 3)` condition is deliberate. These respondents
are already classified under ICLS-19 as unemployed or outside the labour
force. The issue is not missing information; the employment definition
changes their classification.

Once we treat this group as employed, we also need employment
characteristics for them. Under the standard ICLS-19 construction these
variables are missing because they are defined only for employed
respondents.

We therefore create the parallel variables in the same step:

The workshop's methodological guidance identifies re-including eligible own-use agricultural producers as the approach also used by the International Labour Organisation when bridging ICLS-13/19 for ILOSTAT. Here, self-employment, private/NGO sector, agriculture, and skilled agricultural occupation are assigned characteristics, not observed answers to the skipped employment questions. The [GLD Pakistan ICLS note](https://github.com/worldbank/gld/blob/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS/Correspondence_ICLS.md) documents the GLD implementation; this exercise does not establish that each assignment reproduces ILO's exact Pakistan recode. Other standard variables, such as wages, hours, and potential labour force status, retain their original ICLS-19 construction.

``` stata
* Labour-force status: employed
gen byte lstatus_old = lstatus
replace lstatus_old = 1 if extra_icls_13_emp == 1
label var lstatus_old "Labor status - 13th ICLS definition"
label values lstatus_old lbllstatus

* Employment status: self-employed
gen byte empstat_old = empstat
replace empstat_old = 4 if extra_icls_13_emp == 1
replace empstat_old = . if lstatus_old != 1
label var empstat_old "Employment status - 13th ICLS definition"
label values empstat_old lblempstat

* Sector of activity: private / NGO
gen byte ocusec_old = ocusec
replace ocusec_old = 2 if extra_icls_13_emp == 1
replace ocusec_old = . if lstatus_old != 1
label var ocusec_old "Sector of activity - 13th ICLS definition"
label values ocusec_old lblocusec

* Industry: agriculture
gen byte industrycat10_old = industrycat10
replace industrycat10_old = 1 if extra_icls_13_emp == 1
replace industrycat10_old = . if lstatus_old != 1
label var industrycat10_old "Industry category - 13th ICLS definition"
label values industrycat10_old lblindustrycat10

* Occupation: skilled agricultural
gen byte occup_old = occup
replace occup_old = 6 if extra_icls_13_emp == 1
replace occup_old = . if lstatus_old != 1
label var occup_old "Occupation - 13th ICLS definition"
label values occup_old lbloccup
```

We now have the standard variables and their alternative ICLS-13
counterparts:

  Standard GLD      ICLS-13 extension
  ----------------- ---------------------
  `lstatus`         `lstatus_old`
  `empstat`         `empstat_old`
  `ocusec`          `ocusec_old`
  `industrycat10`   `industrycat10_old`
  `occup`           `occup_old`

The standard variables remain untouched. The `_old` variables make the
alternative definition explicit and can be used directly in analysis.

For example:

``` stata
tab lstatus lstatus_old, missing
tab empstat empstat_old, missing
tab industrycat10 industrycat10_old, missing
tab occup occup_old, missing
```

The lesson is simple: a harmonized variable is not only a variable name
and coding scheme. Its underlying statistical definition matters as
well. When a research question requires another definition, we can
construct a transparent parallel version without reharmonizing the rest
of the survey.

## 9. Example 2: Workplace location and commuting time

Our second example is different.

Here we are not changing the definition of an existing GLD concept.

Instead, the Pakistan questionnaire contains information that is useful
for a particular research question but is not part of the standard GLD
dictionary.

We will use two variables:

``` text
s5c22    Location of work
s5c23    Time to reach workplace
```

With just these two additional pieces of information, we can move
quickly from the standard harmonized dataset to a new substantive
analysis.

This illustrates one of the main advantages of starting from GLD.

We do **not** need to harmonize occupation, geography, demographics,
labour status, identifiers, and the rest of the survey before asking our
question.

Those variables are already available.

We only need to understand and add the additional information required
for this analysis.

------------------------------------------------------------------------

## 10. Add workplace location

The Pakistan variable `s5c22` records whether the workplace is in a
rural or urban location:

``` text
1 = Rural
2 = Urban
```

We retain this information in our extended dataset:

``` stata
gen work_location = s5c22

label define lblwork_location ///
    1 "Rural" ///
    2 "Urban"

label values work_location lblwork_location
label variable work_location "Location of workplace"
```

This is now available alongside the standard GLD variables and can be
used immediately in constructing the analytical variables below.

## 11. Add commuting time

The variable `s5c23` records time taken to reach the workplace in
categories:

``` text
1 = Less than 30 minutes
2 = 31–45 minutes
3 = 46–60 minutes
4 = 61 minutes or more
```

We can retain the original information:

``` stata
gen commute_time = s5c23

label define lblcommute_time ///
    1 "Less than 30 minutes" ///
    2 "31-45 minutes" ///
    3 "46-60 minutes" ///
    4 "61 minutes or more"

label values commute_time lblcommute_time
label variable commute_time "Time to reach workplace"

tab commute_time, missing
```

At this point, we have extended the harmonized dataset by only two
variables.

But those two variables can now be combined with the much larger set of
information that GLD has already harmonized for us.

------------------------------------------------------------------------

# Part III --- From extension to analysis

## 12. Construct a residence-to-work pattern

The standard harmonization already contains `urban`, which records
whether the respondent resides in a rural or urban location:

``` text
urban = 0    Rural residence
urban = 1    Urban residence
```

Our extension gives us workplace location.

Together, these variables allow us to construct something that neither
variable captures independently:

> **the rural/urban relationship between place of residence and place of
> work.**

We create four categories:

``` stata
gen work_mobility = .

replace work_mobility = 1 if urban == 0 & work_location == 1
replace work_mobility = 2 if urban == 0 & work_location == 2
replace work_mobility = 3 if urban == 1 & work_location == 1
replace work_mobility = 4 if urban == 1 & work_location == 2

label define work_mobility_lbl ///
    1 "Rural -> Rural" ///
    2 "Rural -> Urban" ///
    3 "Urban -> Rural" ///
    4 "Urban -> Urban"

label values work_mobility work_mobility_lbl

label variable work_mobility "Residence-to-work rural/urban pattern"

tab work_mobility, missing
```

------------------------------------------------------------------------

## 13. What does commuting look like across these groups?

Before constructing a model, start with the data.

The examples below deliberately use **unweighted sample estimates**. Their Pearson tests and model standard errors do not account for the survey design, and the associations are not causal effects. Population inference requires an appropriate specification of weights, strata, and PSUs using the survey documentation. Missing commuting responses are not treated as zero commutes.

``` stata
tab work_mobility commute_time, row chi2
```

The row percentages show a striking pattern.

  -------------------------------------------------------------------------------
  Residence-to-work         \<30 min     31--45 min     46--60 min        61+ min
  pattern                                                          
  ------------------- -------------- -------------- -------------- --------------
  Rural -\> Rural             80.45%         14.50%          2.82%          2.23%

  Rural -\> Urban             40.22%         30.88%         12.28%         16.62%

  Urban -\> Rural             64.99%         22.17%          6.83%          6.01%

  Urban -\> Urban             64.38%         24.75%          7.32%          3.55%
  -------------------------------------------------------------------------------

Rural-to-rural workers have the shortest observed commuting times.

Rural-to-urban workers stand out in the opposite direction. Only around
40 percent report commuting less than 30 minutes, while approximately 29
percent report commuting more than 45 minutes.

The Pearson chi-square test rejects independence between the two
variables (`p < .001`).

------------------------------------------------------------------------

## 14. Construct a long-commute indicator

For a simpler analytical example, we collapse commute duration into a
binary outcome.

We define a long commute as more than 45 minutes:

``` stata
gen long_commute = .

replace long_commute = 0 if inlist(commute_time, 1, 2)
replace long_commute = 1 if inlist(commute_time, 3, 4)

label define long_commute_lbl ///
    0 "45 minutes or less" ///
    1 "More than 45 minutes"

label values long_commute long_commute_lbl
label variable long_commute ///
    "Commute time greater than 45 minutes"

tab long_commute, missing
```

Now compare residence-to-work patterns:

``` stata
tab work_mobility long_commute, row chi2
```

We obtain:

  Residence-to-work pattern     ≤45 minutes   \>45 minutes
  --------------------------- ------------- --------------
  Rural -\> Rural                    94.95%          5.05%
  Rural -\> Urban                    71.09%         28.91%
  Urban -\> Rural                    87.16%         12.84%
  Urban -\> Urban                    89.13%         10.87%
  **Total**                      **89.64%**     **10.36%**

The contrast is now particularly easy to see.

Around **5 percent** of rural-to-rural workers have commutes exceeding
45 minutes, compared with almost **29 percent** of rural-to-urban
workers.

This is information that we could not have obtained from the standard
GLD variables alone.

------------------------------------------------------------------------

## 15. A simple model

We can formalize the comparison using logistic regression.

Because `work_mobility` is categorical, we use Stata's factor-variable
notation:

``` stata
logistic long_commute ib1.work_mobility
```

The `i.` tells Stata to treat the variable as categorical, while `b1`
selects category 1---`Rural -> Rural`---as the reference category.

The estimated odds ratios are approximately:

  Residence-to-work pattern     Odds ratio
  --------------------------- ------------
  Rural -\> Rural                Reference
  Rural -\> Urban                     7.64
  Urban -\> Rural                     2.77
  Urban -\> Urban                     2.29

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

So the model's 7.64 odds ratio corresponds here to an observed
long-commute share rising from about **5% to 29%**. In probability
terms, that is about **24 percentage points higher**, or roughly **5.7
times the probability**. The latter is a descriptive probability ratio,
not the logistic-regression odds ratio.

For communication, predicted probabilities are often easier to interpret
than odds ratios. In this simple model we can obtain them directly:

``` stata
margins work_mobility
```

This returns the estimated probability of a commute over 45 minutes for
each residence-to-work category.

## 16. Combine our extension with another GLD variable

So far, our analysis has used:

``` text
urban                Standard GLD variable
work_location        Our extension
commute_time         Our extension
```

We can now bring another standard harmonized variable back into the
analysis.

The GLD harmonization already provides `occup`, a one-digit occupational
classification.

This is where the benefit of extending an existing harmonization becomes
especially clear.

We do not need to go back to the original occupational codes, understand
the classification, convert them to ISCO, and construct broad
occupational groups.

That work has already been done.

We can simply estimate:

``` stata
logistic long_commute ib1.work_mobility i.occup
```

This asks whether differences across residence-to-work patterns remain
after accounting for differences in occupational composition.

------------------------------------------------------------------------

## 17. What happens after adjusting for occupation?

The residence-to-work estimates become:

  Residence-to-work pattern     Unadjusted OR   Occupation-adjusted OR
  --------------------------- --------------- ------------------------
  Rural -\> Rural                   Reference                Reference
  Rural -\> Urban                        7.64                     4.64
  Urban -\> Rural                        2.77                     2.35
  Urban -\> Urban                        2.29                     1.39

The association becomes smaller after occupation is introduced. The
change is particularly substantial for rural-to-urban and urban-to-urban
workers.

For the supplied data, the unadjusted model uses 99,785 observations and the occupation-adjusted model uses 99,783. The script reports both counts. The comparison therefore includes a small change in sample; moreover, odds ratios are non-collapsible, so their change cannot be read as a causal proportion explained by occupation.

------------------------------------------------------------------------

# Part V --- Lessons from the exercise

## 18. Extension does not mean reharmonization

The central lesson is the difference in the amount of work required.

Starting from the raw survey, we would need to assemble the files,
construct the standard demographic and labour variables, harmonize
classifications such as occupation and industry, and then add the
commuting information needed for our research question.

Starting from GLD, the common analytical core is already available. Our
additional work is much narrower:

``` text
Raw survey
    -> assemble survey
    -> construct and harmonize standard variables
    -> add research-specific variables
    -> analysis

GLD
    -> add research-specific variables
    -> analysis
```

In this exercise, that meant understanding the few questionnaire items
needed for the ICLS bridge and the two commuting variables, adding them
transparently to our `_MINE` version, and then combining them with
variables GLD had already constructed.

## 19. Two kinds of extension

The Pakistan examples illustrate two useful approaches.

### A. Extend a concept already represented in GLD

Use this approach when the standard variable exists but your research
requires a different definition or construction.

Our example:

``` text
Standard GLD                  Extension

lstatus             ->       lstatus_old
empstat             ->       empstat_old
industrycat10       ->       industrycat10_old
occup               ->       occup_old
```

The standard variables remain available and documented.

The alternative definition is explicit.

### B. Extend the GLD dictionary

Use this approach when the original survey contains useful information
that is not part of the common harmonized dictionary.

Our example:

``` text
Original Pakistan LFS        Our extension

s5c22                ->      work_location
s5c23                ->      commute_time
```

Those additions can then interact with the standardized GLD core:

``` text
GLD urban
    +
work_location
    |
    v
Residence-to-work pattern


commute_time
    |
    v
Long commute


GLD occup
    +
Residence-to-work pattern
    +
Long commute
    |
    v
Adjusted commuting analysis
```

------------------------------------------------------------------------

## 20. Final takeaway

Harmonization necessarily involves choices about what information should
be standardized across surveys.

A common dictionary makes comparisons possible, but no common dictionary
can contain every useful question asked in every labour force survey.

Instead:

> **Use the harmonized GLD as the starting point, understand the
> additional parts of the questionnaire relevant to your research, and
> extend the harmonization transparently and reproducibly.**

In the Pakistan example, we used this approach in two ways.

First, we created parallel labour-market variables when our analysis
required an alternative ICLS employment definition.

Second, we added only two country-specific variables---workplace
location and commuting time---and immediately gained the ability to
examine an analytical question that the standard dictionary alone could
not answer.

That is the advantage of extending an existing harmonization:

**the researcher can spend less time recreating standard variables and
more time doing the analysis for which the data were obtained in the
first place.**
