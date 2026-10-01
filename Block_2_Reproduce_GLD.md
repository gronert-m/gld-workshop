# Block 2: Reproduce a GLD Harmonization

**Pakistan Labour Force Survey 2024-25 | About 20 minutes | Stata users**

The introductory session described GLD's approach: the harmonized dataset is accompanied by the code and survey-specific documentation needed to inspect, reproduce, and extend it. Here we put that approach to work. We will start with the published code and the original survey, diagnose two file-dependency problems, and produce a harmonized dataset.

The survey covers 2024-25; its GLD identifier uses the starting year, `PAK_2024_LFS`. We are reproducing the standard variables, not yet changing their definitions.

## 1. Obtain the Inputs (3 Minutes)

Use a **new working folder** for your attempt. Initially put only the downloaded do-file and extracted survey data there. The supplied workshop folder already contains the solutions, so running its adapted do-file immediately would bypass the diagnostic exercise. Leave the supplied files unchanged as a reference.

1. Open the [Pakistan LFS country-survey documentation](https://github.com/worldbank/gld/blob/main/Support/B%20-%20Country%20Survey%20Details/PAK/LFS/1.%20Introduction%20to%20Pakistan%20LFS.md#what-is-the-pak-lfs). Follow its data-access link to the [Pakistan Bureau of Statistics labour force statistics page](https://www.pbs.gov.pk/labour-force-statistics).
2. Download the **2024-25 Stata microdata**, supplied for this workshop as `LFS-2024-25-STATA.zip`, and extract it. Keep the archive as your original download. We work with the extracted dataset, not the ZIP archive.
3. Download the [GLD harmonization do-file](https://github.com/worldbank/gld/blob/main/GLD/PAK/PAK_2024_LFS/PAK_2024_LFS_V01_M_V01/Programs/PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do). Use GitHub's **Download raw file** control, or open **Raw** and download the text. Do not save the GitHub HTML page as a do-file.

Keep a record of your download date and, ideally, the GitHub commit used. The `main` branch and the provider's downloads can change. The steps below describe the version prepared for this workshop.

### Software Check

The harmonization was written for **Stata 18**. The workshop assumes an available installation and internet access for its supporting commands and classification checks. Before the timed diagnostic steps, run:

```stata
capture which labmask
if _rc {
    ssc install labutil2
}

capture which int_classif_universe
if _rc {
    net install GLD-isic-isco-universe-check, from("https://raw.githubusercontent.com/worldbank/gld/main/Support/Z%20-%20GLD%20Ecosystem%20Tools/ISIC%20ISCO%20universe%20check")
}

which labmask
which int_classif_universe
```

`labmask` attaches labels from lookup data. `int_classif_universe` checks industry and occupation codes against the relevant international classifications; see its [installation and usage guide](https://github.com/worldbank/gld/tree/main/Support/Z%20-%20GLD%20Ecosystem%20Tools/ISIC%20ISCO%20universe%20check). If installation or network access fails, resolve that with the facilitator before proceeding. Do not remove the validation checks to get the program to finish.

## 2. Set Paths and Run (4 Minutes)

Open your downloaded do-file. In **Section 1.2**, replace the directory-setup block with the following, changing the first path to your new working folder. This makes the workshop independent of the GLD team's internal directory structure and explicitly defines the output filename.

```stata
local path_in_stata "C:/your/path/recreate_attempt"
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

Despite `.sav` appearing within the name, this is a Stata file: its final extension is `.dta`. No SPSS conversion is needed. If PBS changes its download again, inspect the actual file rather than assuming this name will always apply. Matching filenames alone does not establish that two releases have identical contents.

The expected initial error is a file-not-found error, usually `r(601)`. If you encounter something else, diagnose the reported error rather than trying to force this explanation onto it.

</details>

## 3. Resolve the Remaining Dependencies (6 Minutes)

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

You may download all five supplied lookup files, but distinguish the inputs actually required by the program from a generated intermediate and a file used in other survey versions. Downloading the prepared 2024 lookup alone does not remove Section 1.3's dependency on `append_lfs_districts.dta`.

The minimal working folder after these repairs is:

```text
recreate_attempt/
    PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do
    LFS 2024-25.sav web.dta
    append_lfs_districts.dta
    PAK_country_code_2020.dta
    PAK_training_code.dta
```

Rerun the whole program. It creates the 2024 migration lookup and, on successful completion, the `_RECREATED.dta` output. Both locations must be writable. Its `save, replace` statements overwrite files with those names, which is why we use a separate working folder.

</details>

## 4. Verify the Output (5 Minutes)

Reaching the last line is necessary, but not sufficient evidence of reproduction. Open the file you just created, inspect its structure, and check identifiers and the labour-status universe.

Run this block together, adjusting the folder:

```stata
local path_output "C:/your/path/recreate_attempt"
use "`path_output'/PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED.dta", clear

describe
count
isid pid
assert countrycode == "PAK"
assert year == 2024
assert icls_v == "ICLS-19"
assert weight > 0 & !missing(weight)
assert inlist(lstatus, 1, 2, 3) if age >= 10 & !missing(age)
assert missing(lstatus) if age < 10
tab lstatus, missing
tab urban lstatus, row
```

For the workshop release, expect **325,445 observations** and a unique `pid`. Labour questions apply from age 10; this is a questionnaire universe, not a recommendation to use age 10 as the denominator for every labour-market indicator. Missing labour status for children outside that universe is expected. The tabulations above are unweighted diagnostics, not national estimates.

The final cleanup removes variables that are entirely missing, so not every name in the template's `keep` statement necessarily survives. Record any unexpected difference in counts, identifiers, or coding and investigate the input release and code version before changing substantive rules.

The supplied [adapted do-file](PAK_2024_LFS_V01_M_V01_A_GLD_ALL.do) and [reference output](PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED.dta) are available for comparison. The supplied do-file already fixes the raw filename and uses a facilitator-specific path: edit that path if you use it. Its abbreviated path block omits the version locals; retaining `vermast` and `veralt` as above preserves those metadata fields in your own run. This metadata difference does not itself imply different labour-market values.

### Missing Material or an Unexpected Error?

If a required file is absent from the repository, please [raise an issue](https://github.com/worldbank/gld/issues). Reports about broken links, changed provider downloads, unclear documentation, and possible coding problems are welcome too. Check existing issues first.

Include the survey and version, the code link or commit, the missing filename or failing command, the exact Stata error, your Stata version, and the steps needed to reproduce it. Do not attach respondent microdata, confidential records, or personal folder paths. A short error excerpt is usually more useful than a full log. Please be kind and patient with the team while we investigate.

### Carry Forward

We have recovered a reproducible chain: **provider data + GLD code + auxiliary files + software dependencies -> harmonized output**. Open code makes this chain inspectable; access to microdata still follows the provider's terms. See the [GLD introduction](https://worldbank.github.io/gld/Support/A%20-%20Guides%20and%20Documentation/GLD%20Manual%20Files/Introduction%20to%20the%20GLD.html) for the broader principles.

In [Exercise 2](../2%20-%20Expand/Block_3_Extending_the_GLD_revised.md), we retain the standard harmonization and create a separate research version. Keep your corrected do-file and a record of the inputs: the next step is to extend this chain, not start from scratch.
