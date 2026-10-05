# Block 2: Reproduce a GLD Harmonization

**Pakistan Labour Force Survey 2024-25 | Proposed duration: 35 minutes | Guided reproduction, with optional execution**

The introductory session described GLD's approach: the harmonized dataset is accompanied by the code and survey-specific documentation needed to inspect, reproduce, and extend it. Here we put that approach to work. We will start with the published code and the original survey, diagnose two file-dependency problems, and produce a harmonized dataset.

The survey covers 2024-25; its GLD identifier uses the starting year, `PAK_2024_LFS`. We are reproducing the standard variables, not yet changing their definitions.

## 1. Locate and Obtain the Inputs (7 Minutes)

Choose a **working folder** for your attempt and use your chosen layout throughout Blocks 2-4. A single folder such as `gld_workshop` can hold all scripts, inputs, and outputs; separate folders are equally valid. Neither the name `Examples` nor the numbered folders used to organize these handouts is required. The paths below are placeholders: replace them with your own locations. Use a new folder or keep backup copies of any files you do not want overwritten.

1. Open the [Pakistan LFS country-survey documentation](https://github.com/worldbank/gld/blob/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS/1.%20Introduction%20to%20Pakistan%20LFS.md#where-can-the-data-be-found). Follow its data-access link to the [Pakistan Bureau of Statistics labour force statistics page](https://www.pbs.gov.pk/labour-force-statistics).
2. Download the **2024-25 Stata microdata** directly from PBS as `LFS-2024-25-STATA.zip`, and extract it. Keep the archive as your original download. We work with the extracted dataset, not the ZIP archive.
3. Download the [GLD harmonization do-file](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do). Use GitHub's **Download raw file** control, or open **Raw** and download the text. Do not save the GitHub HTML page as a do-file. You may also open the raw file, use Ctr+A to select all and copy-paste.

### How to participate without installing software

Everyone can locate the PBS download, inspect the public do-file, predict which dependency is missing, and interpret the verification checks. Participants obtain respondent microdata directly from PBS; the workshop does not distribute a copy. Begin the download early and continue with the code walkthrough while it finishes.

Execution is optional during the session. Participants with a suitable environment can run the exercise or work in pairs. The facilitator can use an available Stata installation, or a prepared R/Python browser environment with dependencies installed. If download or runtime setup stalls, continue with the displayed errors and aggregate verification results; finish the full run using the supplied scripts after the workshop. No participant installation is required to follow the session.

### Software check for an executing environment

The original harmonization was written for **Stata 18**. The Stata route needs its supporting commands and network access for classification checks. In the executing environment, run:

```stata
capture which labmask
if _rc {
    ssc install labutil2
}

capture which int_classif_universe
if _rc {
    net install GLD-isic-isco-universe-check, from("https://raw.githubusercontent.com/worldbank/gld/main/Support/Z%20-%20GLD%20Ecosystem%20Tools/ISIC%20ISCO%20universe%20check")
}

```

`labmask` attaches labels from lookup data. `int_classif_universe` is a GLD function we created to check industry and occupation codes against the relevant international classifications; see its [installation and usage guide](https://github.com/worldbank/gld/tree/main/Support/Z%20-%20GLD%20Ecosystem%20Tools/ISIC%20ISCO%20universe%20check). If installation or network access fails, switch to the guided walkthrough while the facilitator resolves execution. Retain the validation checks.

## 2. Set Paths and Run (8 Minutes)

Open your downloaded do-file. In **Section 1.2**, replace the directory-setup block with the following, changing the first path to your working folder. This example puts inputs and outputs together; if you keep them separately, set each path local to the appropriate folder. This makes the workshop independent of the GLD team's internal directory structure and explicitly defines the output filename.

```stata
local path_in_stata "C:/your/path/gld_workshop"
* Below for ease here we just define all sources and outputs as the same folder - structure normally as best suits you.
local path_in_other "`path_in_stata'"
local path_output "`path_in_stata'"

local country "PAK"
local year "2024"
local survey "LFS"
local vermast "V01"
local veralt "V01"
local level_1 "`country'_`year'_`survey'"
local level_2_mast "`level_1'_`vermast'_M"
local level_2_harm "`level_1'_`vermast'_M_`veralt'_A_GLD"
* Use the workshop's canonical suffix for the reproduced output
local out_file "`level_2_harm'_RECREATED.dta"
```

Use an existing, writable folder. Forward slashes work in Stata on Windows, and the quotation marks protect paths containing spaces. The version locals also populate metadata in the output, so retain them.

Run the **whole do-file**, not just a selection. Local macros must be defined within the execution that uses them. At this stage, leave Section 1.3 unchanged.

### Pause: What Stopped the Run?

Read the first error and the command immediately above it. Which file is Stata trying to open? Does that exact filename exist in your working folder?

<details>
<summary>Reveal hint: inspect the input filename</summary>

The first `use` command in Section 1.3 names the microdata file. Compare it with the extracted filename, including spaces and extensions. A correct directory does not guarantee a correct filename.

</details>

<details>
<summary>Reveal solution: the provider's filename has changed</summary>

The published program expects:

```stata
use "`path_in_stata'/LFS2024-25.sav.dta"
```

PBS previously offered an SPSS file, which the GLD team converted to Stata. PBS now offers Stata data directly. For the workshop download, the extracted filename is `LFS 2024-25.sav web.dta`.

Replace the input command with:

```stata
use "`path_in_stata'/LFS 2024-25.sav web.dta", clear
```

Despite `.sav` appearing within the name, this is a Stata file: its final extension is `.dta`. No SPSS conversion is needed. If PBS changes its download again, inspect the actual file rather than assuming this name will always apply. Matching filenames alone does not establish that two releases have identical contents. Inversely here the name changed but the underlying file is the same.

The expected initial error is a file-not-found error, usually `r(601)`. If you encounter something else, diagnose the reported error and liaise with the facilitator.

</details>

## 3. Resolve the Remaining Dependencies (10 Minutes)

Rerun the whole do-file after correcting the raw input command. It should now open the survey and stop at another file request.

### Pause: Raw Data Are Not the Only Input

What is the role of the missing file? Search the do-file for `use` and `using` to identify other external datasets. Where would you look for survey-specific supporting material in the GLD repository?

<details>
<summary>Reveal hint: look beyond the Programs folder</summary>

The country-survey documentation describes coding decisions and helper files. Explore **Support > B - Country Survey Details > PAK > LFS > utilities**.

</details>

<details>
<summary>Reveal solution: download the auxiliary datasets</summary>

Open the [Additional Data folder](https://github.com/worldbank/gld/tree/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS/utilities/Additional%20Data). These are GLD-team lookup files built from additional coding information, not extra respondent microdata.

Download the required files using GitHub's raw-download control and place them in the folder pointed to by `path_in_stata`. A downloaded HTML page with a `.dta` name is not a Stata dataset.

| File in the workshop bundle | Role in this do-file |
| --- | --- |
| `append_lfs_districts.dta` | Required input. Section 1.3 prepares the 2024 district-migration lookup from this file. |
| `PAK_country_code_2020.dta` | Required input for migration-country coding. The older year in its name does not make it the wrong dependency. |
| `PAK_training_code.dta` | Required input for vocational-training field labels. |
| `PAK_migration_code_2024.dta` | Used in Section 5, but generated and overwritten by Section 1.3 from `append_lfs_districts.dta`. A separate download is not required for a full run. |
| `PAK_migration_code_2020.dta` | Included in the workshop bundle; not read by this 2024 do-file. |

You may download all five supplied lookup files, but distinguish the inputs actually required by the program from a generated intermediate and a file used in other survey versions. The do-file rebuilds `PAK_migration_code_2024.dta` from `append_lfs_districts.dta`, even though a prepared copy of the 2024 lookup is already available. This is not strictly necessary or entirely logical; it is simply a quirk of the current workflow. Harmonization code is written and maintained by people, and it can retain redundant steps or historical decisions alongside the substantive work.

We are working to improve these details. After the workshop, the program will be updated as version `V01_M_V02_A` so that the 2024 lookup is used more directly. Finding and discussing such quirks is part of the value of open, reproducible code. Users are encouraged to contact the GLD team or [open an issue in the GLD repository](https://github.com/worldbank/gld/issues) when they find unnecessary dependencies, unclear steps, broken links, or possible errors.

For a single-folder layout, the required files after these repairs could look like this (the folder name is your choice):

```text
gld_workshop/
    PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do
    LFS 2024-25.sav web.dta
    append_lfs_districts.dta
    PAK_country_code_2020.dta
    PAK_training_code.dta
```

Rerun the whole program. It creates the 2024 migration lookup in `path_in_stata` and, on successful completion, the `_RECREATED.dta` output in `path_output`. Both locations must be writable. Its `save, replace` statements overwrite files with those names, so protect any existing copies you need to retain.

</details>

## 4. Verify the Output (5 Minutes)

Reaching the last line is necessary, but not sufficient evidence of reproduction. Open the file you created and use `assert` to compare key results with the expected values for this release. An assertion produces no output when its condition is true and stops with an error when it is false.

Run this block together, setting `path_output` to the folder where your harmonization saved the output:

```stata
local path_output "C:/your/path/gld_workshop"
use "`path_output'/PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED.dta", clear

quietly summarize weight, meanonly
local weight_n = r(N)
local weight_mean = r(mean)

assert `weight_n' == 325445
assert abs(`weight_mean' - 769.8314707787998) < 0.000001

quietly summarize lstatus, meanonly
local lstatus_mean = r(mean)

assert abs(`lstatus_mean' - 2.103672249062981) < 0.000001

assert missing(lstatus) if age < 9

display as result "All reproduction checks passed."
```

These checks cover the number of non-missing survey weights, the means of `weight` and `lstatus`, and the absence of labour-status values below age 9. If an assertion fails, inspect the input release, code version, and preceding Stata output before changing the harmonization.

### R and Python reproductions

The accompanying [R script](Docs/R-Python-Version/PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.R) and [Python script](Docs/R-Python-Version/PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.py) run the complete harmonization from the same PBS microdata and three required lookup inputs. They retain the Stata Recreator's coding decisions and save separately named outputs, `_RECREATED_R.dta` and `_RECREATED_PYTHON.dta`, preserving the Stata reference output.

Their public classification tables are supplied locally in `classification_universes`; execution does not fetch them from the network. See [running instructions](Docs/R-Python-Version/README.md).

## 5. Carry Forward (5 Minutes)

We have recovered a reproducible chain: **provider data + GLD code + auxiliary files + software dependencies -> harmonized output**. Open code makes this chain inspectable; access to microdata still follows the provider's terms. See the [GLD introduction](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/Introduction%20to%20the%20GLD.html) for the broader principles.

In [the next exercise](Block_3_Expanding_the_GLD.md), we retain the standard harmonization and create a separate research version. Keep your corrected do-file and a record of the inputs and their locations: the next step is to extend this chain, not start from scratch. You can continue in the same working folder; the links between handouts describe the workshop materials, not a required layout on your computer.
