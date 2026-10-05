# R and Python versions of the PAK 2024 Recreator

The R and Python versions are provided as a courtesy and were created from the Stata Recreator with AI assistance. They have been checked internally, but we cannot verify their behaviour on other computers or offer the same assurance of reliable execution as for the Stata code. Thank you for your understanding.

Both scripts harmonize the original Pakistan LFS 2024-25 microdata independently; they do not require Stata or its output.

## Inputs and execution

Obtain the microdata directly from the [Pakistan Bureau of Statistics](https://www.pbs.gov.pk/labour-force-statistics). The workshop does not supply respondent microdata.

Place these inputs in one folder:

```text
LFS 2024-25.sav web.dta
append_lfs_districts.dta
PAK_country_code_2020.dta
PAK_training_code.dta
```

Keep the supplied `classification_universes` folder next to the R/Python scripts. The 2024 migration lookup is constructed in memory and does not need a separate download.

Python requires `numpy`, `pandas`, and `pyreadstat`; R requires `haven`. These packages must already be installed in your chosen environment. Once the packages, inputs, and classification tables are available, harmonization does not require a network connection.

Run from the folder containing the scripts:

```powershell
python PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.py
Rscript PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.R
```

By default, inputs and outputs are in that folder. You may use any folder layout; to specify another input folder and a separate output folder:

```powershell
python PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.py "C:/your/path/inputs" "C:/your/path/results"
Rscript PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.R "C:/your/path/inputs" "C:/your/path/results"
```

Run the whole script. Each version saves its own output:

| Version | Output |
| --- | --- |
| Python | `PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED_PYTHON.dta` |
| R | `PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED_R.dta` |

A rerun replaces only the corresponding language's output file. The scripts leave the original respondent and lookup inputs, and the Stata reference output, unchanged.
