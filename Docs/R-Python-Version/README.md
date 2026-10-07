# R and Python translations of the PAK 2024 GLD harmonization code

The R and Python versions are provided as a courtesy and were created from the Stata harmonization code with AI assistance. They are direct translations of the Stata code into R and Python rather than independent implementations of the harmonization methodology.

They have been checked internally, but we cannot verify their behaviour on other computers or offer the same assurance of reliable execution as for the Stata code. The Stata version remains the reference implementation.

Both scripts harmonize the original Pakistan LFS 2024-25 microdata independently; they do not require Stata or a Stata-produced harmonized dataset.

The project-specific `int_classif_universe` validation routines used in the Stata program are intentionally omitted from the R and Python translations. These routines are quality-control checks on ISIC and ISCO codes and are not required for the substantive harmonization steps.

## Inputs

Obtain the microdata directly from the [Pakistan Bureau of Statistics](https://www.pbs.gov.pk/labour-force-statistics). The workshop does not supply respondent microdata.

The scripts use the following input files:

```text
LFS2024-25.sav.dta
append_lfs_districts.dta
PAK_country_code_2020.dta
PAK_training_code.dta
```

The 2024 migration lookup is constructed in memory from `append_lfs_districts.dta`; no separate migration lookup needs to be created beforehand.

No `classification_universes` files are required.

## Software requirements

Python requires:

```text
numpy
pandas
pyreadstat
```

R requires:

```text
haven
```

These packages must already be installed in the environment in which the scripts are run. Once the required packages and input files are available, harmonization does not require a network connection.

## Directories

The R and Python scripts follow the same directory logic as the Stata harmonization program.

For most users, the input and output paths are constructed from:

```text
C:/Users/<username>/WBG/GLD - Current Contributors/582018_AQ/
```

with the corresponding Pakistan master-data and harmonized-data subfolders.

The scripts retain the special path definitions used in the Stata program for the relevant World Bank usernames.

If your files are stored elsewhere, edit the path definitions near the beginning of the script before running it.

## Execution

Run the complete script:

```powershell
python PAK_2024_LFS_V01_M_V01_A_GLD_direct_translation.py
Rscript PAK_2024_LFS_V01_M_V01_A_GLD_direct_translation.R
```

Each version reads the original input datasets, performs the harmonization steps in the same sequence as the Stata program, and writes a Stata `.dta` file to the harmonized-data output directory.

By default, the translated scripts currently save:

```text
PAK_2024_LFS_V01_M_V01_A_GLD.dta
```

If a different output filename is required, change the `OUT_FILE` setting near the beginning of the script.

The scripts do not modify the original respondent or lookup files.
