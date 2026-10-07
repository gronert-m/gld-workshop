# Block 1: Understand and Navigate the GLD

The Global Labor Database (GLD) harmonizes labor force surveys and other household surveys with substantial labor-market information into a common data dictionary. But the GLD is not intended to be only a collection of harmonized datasets.

The harmonization code, documentation, and information learned while working with each survey are part of the project as well. The objective is to make the harmonization **open, transparent, traceable, and reusable**: users should be able to understand how a variable was constructed, reproduce the harmonization, and depart from it when their research requires something different.

> **The main idea of this workshop:** GLD gives you a standardized analytical core, but also the code and documentation needed to understand how that core was constructed and to build on it for your own research.

In this first block, we will learn how to navigate those pieces and trace a few variables from the original survey information to the harmonized GLD output. Throughout the workshop we will use the **Pakistan Labour Force Survey (LFS) 2024-25** as our main example.

## 1. What Problem Is GLD Trying to Solve? (5 Minutes)

Labor force surveys contain much of the information researchers need to study labor markets: employment, unemployment, occupation, industry, education, earnings, hours worked, demographic characteristics, and much more.

The difficulty is that surveys are not designed according to one universal template.

Across countries and years:

* variable names differ;
* questionnaires and skip patterns differ;
* response categories differ;
* national classifications differ;
* international standards change;
* ------------------------------
* concepts that appear similar may not mean exactly the same thing; and
* information useful for understanding these differences is spread across questionnaires, reports, data files, and other documentation.

A researcher interested in comparing labor-market outcomes across several surveys therefore often spends substantial time simply understanding and processing each survey before substantive analysis can begin.

GLD does this work once and makes the result reusable.

Conceptually:

```text
Original survey
      |
      | understand questionnaire, data and survey context
      v
GLD harmonization
      |
      | map information to a common data dictionary
      v
Standard GLD variables
      |
      +--------------------> Analysis using GLD as-is
      |
      +--------------------> Research-specific additions
```

There are therefore two broad ways to use GLD.

**Use the standard harmonization.**  
A researcher can work directly with the variables defined in the GLD data dictionary.

**Build on the harmonization.**  
A researcher can start from the existing GLD work and change a definition, recover more detail, or add survey-specific information needed for a particular research question.

Blocks 2 and 3 of this workshop will do exactly those two things: first reproduce a GLD harmonization, and then expand it.

### What surveys and variables are available?

GLD is continuously expanding, so a static list in this workshop would quickly become outdated.

The [**GLD Platform**](https://datanalytics.worldbank.org/gld-platform/) provides the current survey coverage and allows users to see which GLD variables are available in each survey. The platform is currently in beta.

The platform intends to answer questions such as:

* Is country X available?
* Which surveys and years have been harmonized?
* Is `occup_isco` available in the surveys I want to use?
* Which countries contain a particular variable?
* Download the selection of survey coverage (not microdata) as a spreadsheet

The platform includes surveys brought in from other harmonizations of the World Bank. These are not present in the GLD Repository. An alternative is to ask AI to read the repository and answer the questions like: "how many PAK surveys are there and which years?" - AI works best with well documented infrastructure.

We will instead spend our workshop time understanding what those variables mean and how to trace their construction.

## 2. How We Think About Harmonization (7 Minutes)

Before looking at the files, it is useful to understand the principles behind the harmonization.

### 2.1 Harmonization does not mean pretending surveys are identical

The scope of the standard GLD harmonization is the [**GLD data dictionary**](https://github.com/worldbank/gld/blob/main/Support/A%20-%20Guides%20and%20Documentation/GLD_Dictionary_v01.xlsx).

For every survey, we ask whether and how the information collected by that survey can support the concepts in the dictionary.

But the source survey comes first. If a survey does not contain enough information to construct a concept defensibly, harmonization should not manufacture that information.

Two principles guide this approach:

1. **Each survey is harmonized independently.**
2. **Where the source information does not provide an unambiguous answer, users should be given the information needed to make an informed decision rather than having consequential assumptions hidden inside the harmonization.**

This matters especially when concepts or classifications change over time.

A survey collected under an older standard is not retrospectively treated as though respondents had answered a questionnaire designed under a newer standard. Instead, GLD records the relevant context and lets researchers decide how they want to handle differences across surveys.

### 2.2 Special concepts require to preserve, standardize, and derive

For certain key concepts, GLD retains information close to what was provided in the original survey, converts it to an internationally comparable standard, and then derives convenient analytical variables.

We will see this particularly clearly with occupation:

```text
occup_orig  ->  occup_isco  ->  occup
```

These variables do different jobs.

Keeping the original information means that the standardized GLD variable is not a dead end. Researchers can inspect the mapping and, where appropriate, make a different choice.

### 2.3 Transparency is part of the product

The harmonized dataset is only one GLD output.

The broader GLD product includes:

* the standard **data dictionary**;
* the **harmonization programs**;
* the **GLD Manual**, explaining the dictionary and methodology;
* **Country Survey Details**, documenting information specific to particular surveys; and
* supporting tools and quality checks.

The exact production and validation procedures can evolve over time. The important principle for users is that the harmonization logic and supporting material are made available so that the work can be inspected and reproduced.

## 3. Finding Your Way Around GLD (7 Minutes)

You do not need to memorize the GLD repository structure or its naming conventions.

You should instead leave this workshop knowing **where to look when you need to understand something**.

### 3.1 Start with the GLD Manual (on [website](https://worldbank.github.io/gld/))

The public [GLD documentation is organized as a website](https://worldbank.github.io/gld/README.html).

Three parts are particularly useful:

**[Introduction to the GLD](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/Introduction%20to%20the%20GLD.html)**  
What GLD is, why it exists, and its guiding principles.

**[GLD harmonization methodology](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/GLD%20harmonization%20methodology.html)**  
How the harmonization is organized and the principles used when translating source surveys into the GLD dictionary.

**[GLD data dictionary](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/GLD%20data%20dictionary.html)**  
What each harmonized variable means and how it should be coded.

If six months from now you encounter a GLD convention that you do not remember from this workshop, the objective is not to remember the answer. It is to know how to find it here.

### 3.2 The GitHub repository

The repository contains two areas we will use repeatedly.

```text
gld/
│
├── GLD/
│   └── harmonization programs
│
└── Support/
    ├── A - Guides and Documentation/
    ├── B - Country Survey Details/
    ├── ...
    └── D - Q Checks/
```

The **GLD** folder contains the survey harmonization programs.

The **Support** folder contains the broader material needed to understand and use them.

For this workshop, two Support areas matter most:

**A - Guides and Documentation**  
Contains the GLD manuals and data dictionary.

**B - Country Survey Details**  
Contains information that is specific to particular countries and surveys and cannot be adequately captured simply by looking at the harmonization code.

For Pakistan, for example, the Country Survey Details describe the survey, where the source data can be obtained, changes across survey rounds, definitions of labor status, the transition between ICLS standards, and occupation and industry classifications.

You may also see **D - Q Checks**, which contains GLD quality-checking code. We will not teach the GLD team's current production or validation workflow in this workshop; those procedures can change. What matters here is that the checks themselves are also openly available.

### 3.3 Anatomy of a harmonization program

GLD harmonization programs follow a standard structure (the [harmonization program template](https://github.com/worldbank/gld/blob/main/Support/C%20-%20Templates/GLD_Harmonization_Template.do) is also available online).

The program begins with a **preamble**, containing information about the survey and relevant standards.

It is then divided into sections:

```text
0   Preamble

1   Set up program environment and assemble source data

2   Survey & ID
3   Geography
4   Demography
5   Migration
6   Education
7   Training
8   Labour

9   Final steps
```

Sections 2–8 correspond to blocks of the GLD data dictionary.

Variables are also marked explicitly in the programs. For example:

```stata
*<_urban_>

    [code creating urban]

*</_urban_>
```

This makes it possible to search directly for the GLD variable you are interested in.

That is the skill we will try next.

## 4. Exercise: Trace a Variable (6 Minutes)

We have not yet walked through the Pakistan harmonization in detail.

Using the [**GLD Manual**](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/Education.html) and the [**Pakistan 2024 harmonization program**](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do), try to trace the variable:

```text
educat7
```

Work through the following questions.

1. Find `educat7` in the GLD Manual's data dictionary section. What concept does it represent?
2. Which block of the dictionary does it belong to?
3. Find `educat7` in the Pakistan harmonization program.
4. Which original survey variable(s) is(are) used to construct it?
5. Does the harmonization simply rename an existing variable, or does it make additional coding decisions?

You are not expected to understand every education code in the Pakistan survey. The objective is to learn the route:

```text
Definition in GLD dictionary
          |
          v
Variable in harmonization program
          |
          v
Original survey variables
```

<details>
<summary><strong>Reveal: what should you find?</strong></summary>

`educat7` is in **Section 6: Education**.

For Pakistan 2024, the construction begins from the survey variable `s4c9` and also uses `s4c10` for some categories:

```stata

*  Variable      Storage   Display    Value
*      name         type    format    label      Variable label
*  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*  s4c9            double  %38.0g     S4C9       Education Level
*  s4c10           double  %33.0g     S4C10      Current Enrollment

gen byte educat7 = s4c9

recode educat7 (3=2) (4=3) (5/6=4) (8/16=7)

replace educat7=5 if s4c9==7 & s4c10==1
replace educat7=7 if s4c9==7 & inrange(s4c10,8,15)

replace educat7=. if age<ed_mod_age
```

The important point is not to memorize these codes.

It is that you can move from **the standardized concept**, to **the code implementing it**, to **the original survey information used to construct it**.

</details>

## 5. Reading the Harmonization Through Variables (17 Minutes)

We will now look at a small number of variables in more detail.

Rather than touring the complete data dictionary, these examples illustrate different things GLD harmonization can do.

We will follow:

* [`icls_v`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L145)
* [`urban`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L295)
* [`lstatus`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L854)
* [`occup_orig`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L1048)
* [`occup_isco`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L1056)
* [`occup`](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do#L1077)
```

### 5.1 `icls_v`: record the conceptual context

Start in Section 2 of the Pakistan program.

```stata
gen icls_v = "ICLS-19"
label var icls_v "ICLS version underlying questionnaire questions"
```

`icls_v` records the version of the International Conference of Labour Statisticians standards underlying the survey's concepts of work and employment.

Why does this matter?

The definition of employment changed substantially between the 13th and 19th ICLS standards. Among other changes, the newer framework distinguishes employment for pay or profit from some forms of own-use production that were previously included within employment.

Pakistan's 2024-25 LFS introduced the ICLS-19 framework, replacing the older framework used in previous rounds.

This illustrates the principle from the beginning of this block:

> **GLD harmonizes the survey that was actually collected.**

We do not retrospectively recode an older questionnaire as though respondents had answered the newer questionnaire.

Instead, the standard followed by the survey is recorded, the relevant changes are documented, and researchers can decide how they want to handle the resulting break in comparability.

We will return to this issue in Block 3 when we construct an alternative labor-market definition for research purposes.

### 5.2 `urban`: a relatively simple standardization

Now move to Section 3: Geography.

```stata
gen byte urban = region
recode urban 1=0 2=1

label var urban "Location is urban"
label define lblurban 1 "Urban" 0 "Rural"
label values urban lblurban
```

This is close to the simplest harmonization case. The survey already contains the information we need. GLD changes the coding so that it follows the common GLD definition (from 1 - Rural / 2 - Urban to 0 - Rural / 1 - Urban). 

### 5.3 `lstatus`: construct a concept from the questionnaire

`lstatus` is different.

There is not simply one source variable called "labor status" that we rename.

GLD defines three harmonized categories:

```text
1 = Employed
2 = Unemployed
3 = Not in labor force
```

To determine which category a person belongs to, the harmonization needs to combine information from several questions and respect the employment concept underlying the survey.

For Pakistan 2024, for example, the code checks whether the respondent:

* worked for pay or wages;
* had a job but was temporarily absent;
* performed other work;
* worked in farming, livestock, or fishing and whether the production was intended for sale;
* searched for work; and
* was available to begin work.

Part of the code therefore looks like:

```stata
gen byte lstatus = .

* Worked for pay/wage
replace lstatus = 1 if s5c1 == 1

* Had a job but was temporarily absent
replace lstatus = 1 if s5c4 == 1 & (s5c6 == 1 | s5c7 == 1) ///
    & missing(lstatus)

* Farming/livestock/fishing mainly or only for sale
replace lstatus = 1 ///
    if inrange(s5c9, 1, 3) ///
    * The key bit here - only all sold (1) or mostly sold (2)
    & inrange(s5c10, 1, 2) ///
    & missing(lstatus)

* Unemployed: searched and available
replace lstatus = 2 ///
    if s9c1 == 1 & s9c6 == 1 ///
    & missing(lstatus)

* Remaining respondents of working age
replace lstatus = 3 ///
    if missing(lstatus) & age >= minlaborage
```

To understand `lstatus`, we potentially need:

```text
GLD definition
      +
ICLS standard
      +
Pakistan questionnaire
      +
survey skip patterns
      +
harmonization decisions
```

To document these decision points and choices the GLD Team makes the code and [Country Survey Details available alongside the harmonized data](https://github.com/worldbank/gld/blob/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS/Labor_Status_and_Labor_Force_Participation.md).

### 5.4 Occupation: preserve -> standardize -> derive

Occupation gives us a useful example of the chain introduced earlier.

#### Step 1: `occup_orig` — preserve

```stata
gen occup_orig = string(s5c12, "%04.0f")

replace occup_orig = "" if lstatus != 1

label var occup_orig ///
    "Original occupation record primary job 7 day recall"
```

`occup_orig` retains the occupation coding supplied by the original survey.

This is intentionally close to the source information.

Why keep it?

Because standardization inevitably involves decisions. Retaining the original information lets researchers see where the standardized value came from and gives them a route back if they want to use the source classification differently.

#### Step 2: `occup_isco` — standardize

The next variable expresses occupation using the relevant International Standard Classification of Occupations:

```stata
gen occup_isco = occup_orig
```

For Pakistan 2024 this step is unusually direct because the national classification used by the survey, PSCO-2015, is based on ISCO-08.

The program nevertheless validates the resulting codes against the ISCO universe and corrects a code that does not belong to the valid classification:

```stata
replace occup_isco = "4100" if occup_isco == "4140"
```

This is an important distinction:

```text
occup_orig => what the source survey records

occup_isco => information expressed and checked against the relevant international standard
```

For another survey, moving between these two steps may require a more substantial mapping.

#### Step 3: `occup` — derive

Finally, GLD creates a convenient broad occupational variable from the standardized ISCO code.

Conceptually:

```text
1000–1999 -> Managers
2000–2999 -> Professionals
...
9000–9999 -> Elementary occupations
0000–0999 -> Armed forces
```

The program therefore constructs:

```stata
gen byte occup = .

replace occup = 1  if inrange(occup_isco, "1000", "1999")
replace occup = 2  if inrange(occup_isco, "2000", "2999")
...
replace occup = 9  if inrange(occup_isco, "9000", "9999")
replace occup = 10 if inrange(occup_isco, "0000", "0999")
```

We have therefore moved through the complete chain:

```text
Original Pakistan occupation information
                |
                v
           occup_orig
             PRESERVE
                |
                v
           occup_isco
           STANDARDIZE
                |
                v
              occup
              DERIVE
```

Those three variables are deliberately all retained. 

A researcher interested only in broad occupational groups can use `occup`.

A researcher needing detailed internationally standardized occupation codes can use `occup_isco`.

A researcher who wants to inspect or alter how the original Pakistan classification was treated can go back to `occup_orig` and the harmonization code.

That is the broader GLD philosophy in one example.

## 6. Carry Forward (3 Minutes)

At this point, you should not know the entire GLD data dictionary or remember every repository convention.

You should instead be able to answer six practical questions:

1. **What is GLD?**  
   A common harmonization of labor-market survey microdata, accompanied by the code and documentation needed to understand and build on it.

2. **What does harmonization mean in GLD?**  
   Translating the information actually available in each survey into a common data dictionary while making assumptions and limitations visible.

3. **Where do I find the definition of a GLD variable?**  
   In the GLD data dictionary and Manual.

4. **Where do I find how that variable was constructed for a particular survey?**  
   In that survey's harmonization program, supplemented by its Country Survey Details where additional explanation is needed.

5. **What do I do when GLD does not contain exactly what my research requires?**  
   Trace the existing harmonization back to its source information and build from it rather than starting again from zero.

6. **What do I do if I see something wrong?**
   You can [raise an issue on GitHub](https://github.com/worldbank/gld/issues) if you see a mistake or have any other information you think we should address.

So far we have only **read** the chain:

```text
source survey
     ->
GLD code and documentation
     ->
harmonized variables
```

In **Block 2**, we will put that chain to work.

We will obtain the original Pakistan LFS data and the published GLD harmonization code, run the harmonization ourselves, resolve its external dependencies, and reproduce the GLD output.
