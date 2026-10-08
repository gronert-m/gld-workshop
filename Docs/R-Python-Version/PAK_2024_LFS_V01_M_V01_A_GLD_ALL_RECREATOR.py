"""Direct pandas translation of PAK_2024_LFS_V01_M_V01_A_GLD.do.

The code follows the Stata harmonization program section by section using ordinary
pandas/NumPy statements. Project-specific int_classif_universe validation blocks
are intentionally skipped.
"""
from pathlib import Path
import getpass
import fnmatch
import warnings
import numpy as np
import pandas as pd
import pyreadstat

country = "PAK"
year = "2024"
survey = "LFS"
vermast = "V01"
veralt = "V01"

level_1 = f"{country}_{year}_{survey}"
level_2_mast = f"{level_1}_{vermast}_M"
level_2_harm = f"{level_1}_{vermast}_M_{veralt}_A_GLD"

path_in_stata = "[YOUR PATH TO THE FOLDER]"
path_in_other = path_in_stata
path_output = path_in_stata

# Set PAK_LFS_INPUT_DIR and optionally PAK_LFS_OUTPUT_DIR to override
# the original World Bank directory layout on another machine.
import os
path_in_stata = Path(os.environ.get("PAK_LFS_INPUT_DIR", str(path_in_stata)))
path_output = Path(os.environ.get("PAK_LFS_OUTPUT_DIR", str(path_output)))
path_output.mkdir(parents=True, exist_ok=True)

# The supplied Stata excerpt uses `out_file` at save time but does not define it.
# Set this to the same filename used by the full Stata program if it differs.
OUT_FILE = "PAK_2024_LFS_V01_M_V01_A_GLD.dta"

VARIABLE_LABELS, LABEL_DEFS, VALUE_LABELS = {}, {}, {}
warnings.filterwarnings("ignore", category=pd.errors.PerformanceWarning)

# 1. Assemble inputs without overwriting the migration lookup or raw files.
required_inputs = ["LFS2024-25.sav.dta", "append_lfs_districts.dta",
                   "PAK_country_code_2020.dta", "PAK_training_code.dta"]
missing_inputs = [name for name in required_inputs if not (path_in_stata / name).is_file()]
if missing_inputs:
    raise FileNotFoundError(f"Missing input datasets in {path_in_stata}: {missing_inputs}")
d=pyreadstat.read_dta(str(path_in_stata / 'LFS2024-25.sav.dta'), apply_value_formats=False)[0]
d.columns=d.columns.str.lower()
migration=pyreadstat.read_dta(str(path_in_stata / 'append_lfs_districts.dta'), apply_value_formats=False)[0]
migration=migration.rename(columns={'LFS24_Distcodes':'city_code','LFS24_Distnames':'city_name'})
migration=migration.drop(columns=['samecode','sametext'])
migration.columns=migration.columns.str.lower()
country_lookup=pyreadstat.read_dta(str(path_in_stata / 'PAK_country_code_2020.dta'), apply_value_formats=False)[0]
training=pyreadstat.read_dta(str(path_in_stata / 'PAK_training_code.dta'), apply_value_formats=False)[0]
country_lookup.columns = country_lookup.columns.str.lower()
training.columns = training.columns.str.lower()

# Source SHA256: d568ed498594b5454c48da52240dade734c9df49a733a9b59e6dbc651ac4b4d9

# <_countrycode_>
# Stata line 104
d["countrycode"] = 'PAK'
VARIABLE_LABELS["countrycode"] = "Country code"

# <_survname_>
# Stata line 110
d["survname"] = 'LFS'
VARIABLE_LABELS["survname"] = "Survey acronym"

# <_survey_>
# Stata line 116
d["survey"] = 'LFS'
VARIABLE_LABELS["survey"] = "Survey type"

# <_icls_v_>
# Stata line 122
d["icls_v"] = 'ICLS-19'
VARIABLE_LABELS["icls_v"] = "ICLS version underlying questionnaire questions"

# <_isced_version_>
# Stata line 128
d["isced_version"] = 'isced_2011'
VARIABLE_LABELS["isced_version"] = "Version of ISCED used for educat_isced"

# <_isco_version_>
# Stata line 134
d["isco_version"] = 'isco_2008'
VARIABLE_LABELS["isco_version"] = "Version of ISCO used"

# <_isic_version_>
# Stata line 140
d["isic_version"] = 'isic_4'
VARIABLE_LABELS["isic_version"] = "Version of ISIC used"

# <_year_>
# Stata line 146
d["year"] = 2024
VARIABLE_LABELS["year"] = "Year of survey"

# <_vermast_>
# Stata line 152
d["vermast"] = "V01"
VARIABLE_LABELS["vermast"] = "Version of master data"

# <_veralt_>
# Stata line 158
d["veralt"] = "V01"
VARIABLE_LABELS["veralt"] = "Version of the alt/harmonized data"

# <_harmonization_>
# Stata line 164
d["harmonization"] = 'GLD'
VARIABLE_LABELS["harmonization"] = "Type of harmonization"

# <_int_year_>
# Stata line 170
d["int_year"] = np.nan
VARIABLE_LABELS["int_year"] = "Year of the interview"

# <_int_month_>
# Stata line 176
d["int_month"] = np.nan
LABEL_DEFS["lblint_month"] = {1: 'January', 2: 'February', 3: 'March', 4: 'April', 5: 'May', 6: 'June', 7: 'July', 8: 'August', 9: 'September', 10: 'October', 11: 'November', 12: 'December'}
VALUE_LABELS["int_month"] = LABEL_DEFS["lblint_month"].copy()
VARIABLE_LABELS["int_month"] = "Month of the interview"

# <_hhid_>
# Stata line 192
d["hhno"] = d["hhno"].map(lambda v: "." if pd.isna(v) else format(v, "02.0f"))
# Stata line 193
d["hhid"] = (d['pcode'] if d['pcode'].dtype == object else d['pcode'].map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g'))) + (d['hhno'] if d['hhno'].dtype == object else d['hhno'].map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g')))
VARIABLE_LABELS["hhid"] = "Household ID"

# <_pid_>
# Stata line 199
d["sno_str"] = d['sno']
# Stata line 200
d["sno_str"] = d["sno_str"].map(lambda v: "." if pd.isna(v) else format(v, "02.0f"))
# Stata line 201 (the Stata source concatenates sno, not sno_str)
d["pid"] = (d['hhid'] if d['hhid'].dtype == object else d['hhid'].map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g'))) + (d['sno'] if d['sno'].dtype == object else d['sno'].map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g')))
VARIABLE_LABELS["pid"] = "Individual ID"
assert not d["pid"].duplicated().any() and not (d["pid"].isna() | d["pid"].eq("")).any()

# <_weight_>
# Stata line 208
d["weight"] = d['weights']
VARIABLE_LABELS["weight"] = "Survey sampling weight"

# <_weight_m_>
# Stata line 215
d["weight_m"] = np.nan
VARIABLE_LABELS["weight_m"] = "Survey sampling weight to obtain national estimates for each month"

# <_weight_q_>
# Stata line 221
d["weight_q"] = np.nan
VARIABLE_LABELS["weight_q"] = "Survey sampling weight to obtain national estimates for each quarter"

# <_psu_>
# Stata line 227
d["psu"] = d['pcode']
VARIABLE_LABELS["psu"] = "Primary sampling units"

# <_ssu_>
# Stata line 233
d["ssu"] = d['hhid']
VARIABLE_LABELS["ssu"] = "Secondary sampling units"

# <_strata_>
# Stata line 239
d["strata"] = d['pcode'].str.slice(0, 3)
# Stata line 240
d["strata"] = pd.to_numeric(d["strata"], errors="raise")
VARIABLE_LABELS["strata"] = "Strata"

# <_wave_>
# Stata line 246
d["wave"] = d['quarter']
VARIABLE_LABELS["wave"] = "Survey wave"

# <_panel_>
# Stata line 252
d["panel"] = ''
VARIABLE_LABELS["panel"] = "Panel individual belongs to"

# <_visit_no_>
# Stata line 258
d["visit_no"] = np.nan
VARIABLE_LABELS["visit_no"] = "Visit number in panel"

# <_urban_>
# Stata line 272
d["urban"] = d['region']
# Stata line 273
_source_urban = d["urban"].copy()
d.loc[(_source_urban == 1), "urban"] = 0
d.loc[(_source_urban == 2), "urban"] = 1
del _source_urban
VARIABLE_LABELS["urban"] = "Location is urban"
LABEL_DEFS["lblurban"] = {1: 'Urban', 0: 'Rural'}
VALUE_LABELS["urban"] = LABEL_DEFS["lblurban"].copy()

# <_subnatid1_>
# Stata line 288
d["subnatid1"] = ''
# Stata line 289
d.loc[d['province'] == 1, "subnatid1"] = '1 - Khyber/Pakhtoonkhua'
# Stata line 290
d.loc[d['province'] == 2, "subnatid1"] = '2 - Punjab'
# Stata line 291
d.loc[d['province'] == 3, "subnatid1"] = '3 - Sindh'
# Stata line 292
d.loc[d['province'] == 4, "subnatid1"] = '4 - Balochistan'
VARIABLE_LABELS["subnatid1"] = "Subnational ID at First Administrative Level"

# <_subnatid2_>
# Stata line 298
d["subnatid2"] = ''
VARIABLE_LABELS["subnatid2"] = "Subnational ID at Second Administrative Level"

# <_subnatid3_>
# Stata line 304
d["subnatid3"] = ''
VARIABLE_LABELS["subnatid3"] = "Subnational ID at Third Administrative Level"

# <_subnatidsurvey_>
# Stata line 317
d["subnatidsurvey"] = ''
# Stata line 318
d.loc[d['urban'] == 1, "subnatidsurvey"] = d['subnatid1'] + ' - Urban'
# Stata line 319
d.loc[d['urban'] == 0, "subnatidsurvey"] = d['subnatid1'] + ' - Rural'
VARIABLE_LABELS["subnatidsurvey"] = "Administrative level at which survey is representative"

# <_subnatid1_prev_>
# Stata line 330
d["subnatid1_prev"] = np.nan
VARIABLE_LABELS["subnatid1_prev"] = "Classification used for subnatid1 from previous survey"

# <_subnatid2_prev_>
# Stata line 336
d["subnatid2_prev"] = np.nan
VARIABLE_LABELS["subnatid2_prev"] = "Classification used for subnatid2 from previous survey"

# <_subnatid3_prev_>
# Stata line 342
d["subnatid3_prev"] = np.nan
VARIABLE_LABELS["subnatid3_prev"] = "Classification used for subnatid3 from previous survey"

# <_gaul_adm1_code_>
# Stata line 348
d["gaul_adm1_code"] = np.nan
VARIABLE_LABELS["gaul_adm1_code"] = "Global Administrative Unit Layers (GAUL) Admin 1 code"

# <_gaul_adm2_code_>
# Stata line 354
d["gaul_adm2_code"] = np.nan
VARIABLE_LABELS["gaul_adm2_code"] = "Global Administrative Unit Layers (GAUL) Admin 2 code"

# <_gaul_adm3_code_>
# Stata line 360
d["gaul_adm3_code"] = np.nan
VARIABLE_LABELS["gaul_adm3_code"] = "Global Administrative Unit Layers (GAUL) Admin 3 code"

# <_hsize_>
# Stata line 374
d["member_count"] = 1
d.loc[~(d['s4c3'] < 8), "member_count"] = np.nan
# Stata line 375
d.loc[d['member_count'].isna() | d['member_count'].eq(''), "member_count"] = 0
# Stata line 376
d["hsize"] = d['member_count'].groupby(d['hhid']).transform('sum')

# <_age_>
# Stata line 394
d["age"] = d['s4c6']
VARIABLE_LABELS["age"] = "Individual age"

# <_male_>
# Stata line 400
d["male"] = d['s4c5']
# Stata line 401
_source_male = d["male"].copy()
d.loc[(_source_male == 2), "male"] = 0
del _source_male
VARIABLE_LABELS["male"] = "Sex - Ind is male"
LABEL_DEFS["lblmale"] = {1: 'Male', 0: 'Female'}
VALUE_LABELS["male"] = LABEL_DEFS["lblmale"].copy()

# <_relationharm_>
# Stata line 409
d["relationharm"] = d['s4c3']
# Stata line 410
_source_relationharm = d["relationharm"].copy()
d.loc[(_source_relationharm == 4), "relationharm"] = 3
d.loc[(_source_relationharm == 5), "relationharm"] = 4
d.loc[(_source_relationharm == 6) | (_source_relationharm == 7), "relationharm"] = 5
d.loc[(_source_relationharm == 8) | (_source_relationharm == 9), "relationharm"] = 6
del _source_relationharm
VARIABLE_LABELS["relationharm"] = "Relationship to the head of household - Harmonized"
LABEL_DEFS["lblrelationharm"] = {1: 'Head of household', 2: 'Spouse', 3: 'Children', 4: 'Parents', 5: 'Other relatives', 6: 'Other and non-relatives'}
VALUE_LABELS["relationharm"] = LABEL_DEFS["lblrelationharm"].copy()
# Stata line 415
d["lowest_rel"] = d['s4c3'].groupby(d['hhid']).transform('min')
# Stata line 416
d["tot_heads"] = (d['s4c3'] == 1).groupby(d['hhid']).transform('sum')
assert bool(np.all((d["lowest_rel"] == 1))), "Source assertion failed at line 417"
assert bool(np.all((d["tot_heads"] == 1))), "Source assertion failed at line 418"

# <_relationcs_>
# Stata line 423
d["relationcs"] = d['s4c3']
VARIABLE_LABELS["relationcs"] = "Relationship to the head of household - Country original"

# <_marital_>
# Stata line 429
d["marital"] = d['s4c7']
# Stata line 430
_source_marital = d["marital"].copy()
d.loc[(_source_marital == 2), "marital"] = 1
d.loc[(_source_marital == 1), "marital"] = 2
d.loc[(_source_marital == 3), "marital"] = 5
del _source_marital
VARIABLE_LABELS["marital"] = "Marital status"
LABEL_DEFS["lblmarital"] = {1: 'Married', 2: 'Never Married', 3: 'Living together', 4: 'Divorced/Separated', 5: 'Widowed'}
VALUE_LABELS["marital"] = LABEL_DEFS["lblmarital"].copy()

# <_eye_dsablty_>
# Stata line 438
d["eye_dsablty"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["eye_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["eye_dsablty"] = "Disability related to eyesight"

# <_hear_dsablty_>
# Stata line 446
d["hear_dsablty"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["hear_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["hear_dsablty"] = "Disability related to hearing"

# <_walk_dsablty_>
# Stata line 454
d["walk_dsablty"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["walk_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["walk_dsablty"] = "Disability related to walking or climbing stairs"

# <_conc_dsord_>
# Stata line 462
d["conc_dsord"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["conc_dsord"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["conc_dsord"] = "Disability related to concentration or remembering"

# <_slfcre_dsablty_>
# Stata line 470
d["slfcre_dsablty"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["slfcre_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["slfcre_dsablty"] = "Disability related to selfcare"

# <_comm_dsablty_>
# Stata line 478
d["comm_dsablty"] = np.nan
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["comm_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["comm_dsablty"] = "Disability related to communicating"

# <_migrated_mod_age_>
# Stata line 495
d["migrated_mod_age"] = 10
VARIABLE_LABELS["migrated_mod_age"] = "Migration module application age"

# <_migrated_ref_time_>
# Stata line 501
d["migrated_ref_time"] = 99
VARIABLE_LABELS["migrated_ref_time"] = "Reference time applied to migration questions (in years)"

# <_migrated_binary_>
# Stata line 507
d["migrated_binary"] = np.where(d['s4c15'] == 1, 0, 1)
LABEL_DEFS["lblmigrated_binary"] = {0: 'No', 1: 'Yes'}
# Stata line 509
d.loc[d['age'] < d['migrated_mod_age'], "migrated_binary"] = np.nan
VALUE_LABELS["migrated_binary"] = LABEL_DEFS["lblmigrated_binary"].copy()
VARIABLE_LABELS["migrated_binary"] = "Individual has migrated"

# <_migrated_years_>
# Stata line 528
d["migrated_years"] = np.nan
# Stata line 529
d.loc[d['s4c15'] == 2, "migrated_years"] = 0.5
# Stata line 530
d.loc[d['s4c15'].notna() & d['s4c15'].between(3, 6), "migrated_years"] = d['s4c15'] - 2
# Stata line 531
d.loc[d['s4c15'] == 7, "migrated_years"] = 7.5
# Stata line 532
d.loc[d['s4c15'] == 8, "migrated_years"] = 11
# Stata line 533
d.loc[d['migrated_binary'] != 1, "migrated_years"] = np.nan
# Stata line 534
d.loc[d['age'] < d['migrated_mod_age'], "migrated_years"] = np.nan
VARIABLE_LABELS["migrated_years"] = "Years since latest migration"

# <_migrated_from_urban_>
# Stata line 540
d["migrated_from_urban"] = d['s4c17']
# Stata line 541
_source_migrated_from_urban = d["migrated_from_urban"].copy()
d.loc[(_source_migrated_from_urban == 0), "migrated_from_urban"] = np.nan
d.loc[(_source_migrated_from_urban == 1), "migrated_from_urban"] = 0
d.loc[(_source_migrated_from_urban == 2), "migrated_from_urban"] = 1
del _source_migrated_from_urban
# Stata line 542
d.loc[d['migrated_binary'] != 1, "migrated_from_urban"] = np.nan
# Stata line 543
d.loc[d['age'] < d['migrated_mod_age'], "migrated_from_urban"] = np.nan
LABEL_DEFS["lblmigrated_from_urban"] = {0: 'Rural', 1: 'Urban'}
VALUE_LABELS["migrated_from_urban"] = LABEL_DEFS["lblmigrated_from_urban"].copy()
VARIABLE_LABELS["migrated_from_urban"] = "Migrated from area"

# <_migrated_from_cat_>
# Stata line 557
d["helper_mfc_1"] = np.floor(d['s4c16'] / 100).map(lambda v: np.nan if pd.isna(v) else format(float(v), '.9g'))
d.loc[~(d['s4c16'] < 1000), "helper_mfc_1"] = np.nan
# Stata line 558
d["helper_mfc_2"] = d['pcode'].str.slice(0, 1)
# Stata line 560
d["migrated_from_cat"] = np.nan
# Stata line 562
d.loc[d['helper_mfc_1'] == d['helper_mfc_2'], "migrated_from_cat"] = 3
# Stata line 563
d.loc[(d['helper_mfc_1'] != d['helper_mfc_2']) & (d['migrated_binary'] == 1) & (d['s4c16'] < 1000), "migrated_from_cat"] = 4
# Stata line 564
d.loc[(d['s4c16'].isna() | (d['s4c16'] > 999)) & ~(d['s4c16'].isna() | d['s4c16'].eq('')), "migrated_from_cat"] = 5
# Stata line 566
d.loc[d['migrated_binary'] != 1, "migrated_from_cat"] = np.nan
# Stata line 567
d.loc[d['age'] < d['migrated_mod_age'], "migrated_from_cat"] = np.nan
LABEL_DEFS["lblmigrated_from_cat"] = {1: 'From same admin3 area', 2: 'From same admin2 area', 3: 'From same admin1 area', 4: 'From other admin1 area', 5: 'From other country'}
VALUE_LABELS["migrated_from_cat"] = LABEL_DEFS["lblmigrated_from_cat"].copy()
VARIABLE_LABELS["migrated_from_cat"] = "Category of migration area"
_drop_cols = [col for col in d.columns if any(fnmatch.fnmatchcase(col, pat) for pat in ['helper_mfc_*'])]
d = d.drop(columns=_drop_cols)
del _drop_cols

# <_migrated_from_code_>
# Stata line 576
d["city_code"] = d['s4c16']
# Stata line 577
_lookup = migration.copy()
if _lookup["city_code"].duplicated().any():
    raise ValueError("Nonunique lookup key: city_code")
_lookup = _lookup.drop(columns=[c for c in _lookup.columns if c in d.columns and c != "city_code"])
d = d.merge(_lookup.loc[_lookup["city_code"].notna()], on="city_code", how="left", validate="many_to_one", indicator=True, sort=False)
d["_merge"] = d["_merge"].map({"left_only": 1, "right_only": 2, "both": 3}).astype(float)
del _lookup
# Stata line 578
d.loc[d['_merge'] == 1, "city_code"] = np.nan
d = d.loc[~((d["_merge"] == 2))].reset_index(drop=True)
# Stata line 580
d["migrated_from_code"] = d['mapped_lfscode_24']
d.loc[~(d['migrated_binary'] == 1), "migrated_from_code"] = np.nan
# Stata line 581
d.loc[d['mapped_lfscode_24'].isna() | (d['mapped_lfscode_24'] > 999), "migrated_from_code"] = np.nan
# Stata line 582
d.loc[d['migrated_binary'] != 1, "migrated_from_code"] = np.nan
# Stata line 583
d.loc[d['age'] < d['migrated_mod_age'], "migrated_from_code"] = np.nan
_drop_cols = [col for col in d.columns if any(fnmatch.fnmatchcase(col, pat) for pat in ['_merge'])]
d = d.drop(columns=_drop_cols)
del _drop_cols
VARIABLE_LABELS["migrated_from_code"] = "Code of migration area as subnatid level of migrated_from_cat"

# <_migrated_from_country_>
# Stata line 590
_lookup = country_lookup.copy()
if _lookup["city_code"].duplicated().any():
    raise ValueError("Nonunique lookup key: city_code")
_lookup = _lookup.drop(columns=[c for c in _lookup.columns if c in d.columns and c != "city_code"])
d = d.merge(_lookup.loc[_lookup["city_code"].notna()], on="city_code", how="left", validate="many_to_one", indicator=True, sort=False)
d["_merge"] = d["_merge"].map({"left_only": 1, "right_only": 2, "both": 3}).astype(float)
del _lookup
d = d.loc[~((d["_merge"] == 2))].reset_index(drop=True)
_drop_cols = [col for col in d.columns if any(fnmatch.fnmatchcase(col, pat) for pat in ['_merge'])]
d = d.drop(columns=_drop_cols)
del _drop_cols
# Stata line 593
d["migrated_from_country"] = d['city_code']
d.loc[~((d['country'] == 1) & (d['migrated_binary'] == 1)), "migrated_from_country"] = np.nan
# Stata line 594
d["country_name"] = d['iso_code']
d.loc[~((d['country'] == 1) & (d['migrated_binary'] == 1)), "country_name"] = np.nan
# Stata line 595
_labels = d.loc[d["migrated_from_country"].notna() & d["country_name"].notna(), ["migrated_from_country", "country_name"]].drop_duplicates()
if _labels["migrated_from_country"].duplicated().any():
    raise ValueError("Conflicting labels for migrated_from_country")
VALUE_LABELS["migrated_from_country"] = {int(k): str(v) for k, v in _labels.itertuples(index=False, name=None)}
del _labels
# Stata line 596
d.loc[d['migrated_binary'] != 1, "migrated_from_country"] = np.nan
# Stata line 597
d.loc[d['age'] < d['migrated_mod_age'], "migrated_from_country"] = np.nan
VARIABLE_LABELS["migrated_from_country"] = "Code of migration country (ISO 3 Letter Code)"

# <_migrated_reason_>
# Stata line 603
d["migrated_reason"] = d['s4c18']
# Stata line 604
_source_migrated_reason = d["migrated_reason"].copy()
d.loc[_source_migrated_reason.between(1, 4) | (_source_migrated_reason == 6), "migrated_reason"] = 3
d.loc[(_source_migrated_reason == 5), "migrated_reason"] = 2
d.loc[_source_migrated_reason.between(8, 11), "migrated_reason"] = 1
d.loc[_source_migrated_reason.between(14, 16), "migrated_reason"] = 4
d.loc[(_source_migrated_reason == 7) | _source_migrated_reason.between(12, 13) | (_source_migrated_reason == 17), "migrated_reason"] = 5
del _source_migrated_reason
# Stata line 605
d.loc[d['migrated_binary'] != 1, "migrated_reason"] = np.nan
LABEL_DEFS["lblmigrated_reason"] = {1: 'Family reasons', 2: 'Educational reasons', 3: 'Employment', 4: 'Forced (political reasons, natural disaster, …)', 5: 'Other reasons'}
VALUE_LABELS["migrated_reason"] = LABEL_DEFS["lblmigrated_reason"].copy()
VARIABLE_LABELS["migrated_reason"] = "Reason for migrating"

# <_ed_mod_age_>
# Stata line 629
d["ed_mod_age"] = 5
VARIABLE_LABELS["ed_mod_age"] = "Education module application age"

# <_school_>
# Stata line 635
d["school"] = np.nan
# Stata line 636
d.loc[d['s4c10'] <= 3, "school"] = 0
# Stata line 637
d.loc[d['s4c10'].notna() & (d['s4c10'] > 3), "school"] = 1
VARIABLE_LABELS["school"] = "Attending school"
LABEL_DEFS["lblschool"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["school"] = LABEL_DEFS["lblschool"].copy()

# <_literacy_>
# Stata line 645
d["literacy"] = np.nan
# Stata line 646
d.loc[(d['s4c81'] == 1) & (d['s4c82'] == 1), "literacy"] = 1
# Stata line 647
d.loc[(d['literacy'] != 1) & ~(d['s4c81'].isna() | d['s4c81'].eq('')) & ~(d['s4c82'].isna() | d['s4c82'].eq('')), "literacy"] = 0
VARIABLE_LABELS["literacy"] = "Individual can read & write"
LABEL_DEFS["lblliteracy"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["literacy"] = LABEL_DEFS["lblliteracy"].copy()

# <_educy_>
# Stata line 655
d["educy"] = np.nan
# Stata line 657
d.loc[d['s4c9'] <= 3, "educy"] = 0
# Stata line 658
d.loc[d['s4c9'] == 4, "educy"] = 5
# Stata line 659
d.loc[d['s4c9'] == 5, "educy"] = 8
# Stata line 660
d.loc[d['s4c9'] == 6, "educy"] = 10
# Stata line 661
d.loc[d['s4c9'] == 7, "educy"] = 12
# Stata line 662
d.loc[d['s4c9'] == 8, "educy"] = 16
# Stata line 663
d.loc[d['s4c9'] == 9, "educy"] = 17
# Stata line 664
d.loc[d['s4c9'] == 10, "educy"] = 16
# Stata line 665
d.loc[d['s4c9'] == 11, "educy"] = 16
# Stata line 666
d.loc[d['s4c9'] == 12, "educy"] = 16
# Stata line 667
d.loc[d['s4c9'] == 13, "educy"] = 19
# Stata line 668
d.loc[d['s4c9'] == 14, "educy"] = 20
# Stata line 669
d.loc[d['s4c9'] == 15, "educy"] = 22
VARIABLE_LABELS["educy"] = "Years of education"

# <_educat7_>
# Stata line 675
d["educat7"] = d['s4c9']
# Stata line 676
_source_educat7 = d["educat7"].copy()
d.loc[(_source_educat7 == 3), "educat7"] = 2
d.loc[(_source_educat7 == 4), "educat7"] = 3
d.loc[_source_educat7.between(5, 6), "educat7"] = 4
d.loc[_source_educat7.between(8, 16), "educat7"] = 7
del _source_educat7
# Stata line 677
d.loc[(d['s4c9'] == 7) & (d['s4c10'] == 1), "educat7"] = 5
# Stata line 678
d.loc[(d['s4c9'] == 7) & (d['s4c10'].notna() & d['s4c10'].between(8, 15)), "educat7"] = 7
# Stata line 679
d.loc[d['age'] < d['ed_mod_age'], "educat7"] = np.nan
VARIABLE_LABELS["educat7"] = "Level of education 1"
LABEL_DEFS["lbleducat7"] = {1: 'No education', 2: 'Primary incomplete', 3: 'Primary complete', 4: 'Secondary incomplete', 5: 'Secondary complete', 6: 'Higher than secondary but not university', 7: 'University incomplete or complete'}
VALUE_LABELS["educat7"] = LABEL_DEFS["lbleducat7"].copy()

# <_educat5_>
# Stata line 687
d["educat5"] = d['educat7']
# Stata line 688
_source_educat5 = d["educat5"].copy()
d.loc[(_source_educat5 == 4), "educat5"] = 3
d.loc[(_source_educat5 == 5), "educat5"] = 4
d.loc[(_source_educat5 == 6) | (_source_educat5 == 7), "educat5"] = 5
del _source_educat5
VARIABLE_LABELS["educat5"] = "Level of education 2"
LABEL_DEFS["lbleducat5"] = {1: 'No education', 2: 'Primary incomplete', 3: 'Primary complete but secondary incomplete', 4: 'Secondary complete', 5: 'Some tertiary/post-secondary'}
VALUE_LABELS["educat5"] = LABEL_DEFS["lbleducat5"].copy()

# <_educat4_>
# Stata line 696
d["educat4"] = d['educat7']
# Stata line 697
_source_educat4 = d["educat4"].copy()
d.loc[(_source_educat4 == 2) | (_source_educat4 == 3) | (_source_educat4 == 4), "educat4"] = 2
d.loc[(_source_educat4 == 5), "educat4"] = 3
d.loc[(_source_educat4 == 6) | (_source_educat4 == 7), "educat4"] = 4
del _source_educat4
VARIABLE_LABELS["educat4"] = "Level of education 3"
LABEL_DEFS["lbleducat4"] = {1: 'No education', 2: 'Primary', 3: 'Secondary', 4: 'Post-secondary'}
VALUE_LABELS["educat4"] = LABEL_DEFS["lbleducat4"].copy()

# <_educat_orig_>
# Stata line 705
d["educat_orig"] = d['s4c9']
VARIABLE_LABELS["educat_orig"] = "Original survey education code"

# <_educat_isced_>
# Stata line 711
d["educat_isced"] = d['s4c9']
# Stata line 712
d.loc[~(d['s4c9'].notna() & d['s4c9'].between(1, 16)), "educat_isced"] = np.nan
# Stata line 713
_source_educat_isced = d["educat_isced"].copy()
d.loc[(_source_educat_isced == 1), "educat_isced"] = np.nan
d.loc[_source_educat_isced.between(2, 3), "educat_isced"] = 20
d.loc[(_source_educat_isced == 3), "educat_isced"] = 100
d.loc[_source_educat_isced.between(4, 6), "educat_isced"] = 244
d.loc[(_source_educat_isced == 7), "educat_isced"] = 344
d.loc[_source_educat_isced.between(8, 12), "educat_isced"] = 660
d.loc[_source_educat_isced.between(13, 14), "educat_isced"] = 760
d.loc[_source_educat_isced.between(15, 16), "educat_isced"] = 860
del _source_educat_isced
# Stata line 714
d.loc[d['age'] < d['ed_mod_age'], "educat_isced"] = np.nan
VARIABLE_LABELS["educat_isced"] = "ISCED standardised level of education"

# ----------6.1: Education cleanup------------------------------*

# <_% Correction min age_>
_age_mask = (d["age"] < d["ed_mod_age"]) & d["age"].notna()
for _name in ['school', 'literacy', 'educy', 'educat7', 'educat5', 'educat4', 'educat_orig', 'educat_isced']:
    d.loc[_age_mask, _name] = "" if (d[_name].dtype == object or pd.api.types.is_string_dtype(d[_name].dtype)) else np.nan
del _age_mask, _name

# <_vocational_>
# Stata line 751
d["vocational"] = d['s4c11']
# Stata line 752
_source_vocational = d["vocational"].copy()
d.loc[_source_vocational.between(1, 3), "vocational"] = 1
d.loc[(_source_vocational == 4), "vocational"] = 0
del _source_vocational
# Stata line 753
d.loc[~(d['vocational'].notna() & d['vocational'].between(0, 1)), "vocational"] = np.nan
LABEL_DEFS["lblvocational"] = {0: 'No', 1: 'Yes'}
# Source attaches undefined value label vocationallbl to vocational; no labels exported.
VARIABLE_LABELS["vocational"] = "Ever received vocational training"

# <_vocational_type_>
# Stata line 761
d["vocational_type"] = d['s4c11']
# Stata line 762
_source_vocational_type = d["vocational_type"].copy()
d.loc[(_source_vocational_type == 1), "vocational_type"] = 1
d.loc[(_source_vocational_type == 2), "vocational_type"] = 2
del _source_vocational_type
# Stata line 763
d.loc[~(d['vocational_type'].notna() & d['vocational_type'].between(1, 2)), "vocational_type"] = np.nan
LABEL_DEFS["lblvocational_type"] = {1: 'Inside Enterprise', 2: 'External'}
VALUE_LABELS["vocational_type"] = LABEL_DEFS["lblvocational_type"].copy()
VARIABLE_LABELS["vocational_type"] = "Type of vocational training"

# <_vocational_length_l_>
# Stata line 778
d["vocational_length_l"] = d['s4c13']
# Stata line 779
d["vocational_length_l"] = d['vocational_length_l'] / 4.2
VARIABLE_LABELS["vocational_length_l"] = "Length of training in months, lower limit"

# <_vocational_length_u_>
# Stata line 785
d["vocational_length_u"] = d['s4c13']
# Stata line 786
d["vocational_length_u"] = d['vocational_length_u'] / 4.2
VARIABLE_LABELS["vocational_length_u"] = "Length of training in months, upper limit"

# <_vocational_field_orig_>
# Stata line 792
d["code"] = d['s4c12']
# Stata line 793
_lookup = training.copy()
if _lookup["code"].duplicated().any():
    raise ValueError("Nonunique lookup key: code")
_lookup = _lookup.drop(columns=[c for c in _lookup.columns if c in d.columns and c != "code"])
d = d.merge(_lookup.loc[_lookup["code"].notna()], on="code", how="left", validate="many_to_one", indicator=True, sort=False)
d["_merge"] = d["_merge"].map({"left_only": 1, "right_only": 2, "both": 3}).astype(float)
del _lookup
d = d.loc[~((d["_merge"] == 2))].reset_index(drop=True)
# Stata line 795
d["vocational_field_orig"] = d['code']
# Stata line 796
_labels = d.loc[d["vocational_field_orig"].notna(), ["vocational_field_orig", "training_field"]].drop_duplicates()
if _labels["vocational_field_orig"].duplicated().any():
    raise ValueError("Conflicting labels for vocational_field_orig")
VALUE_LABELS["vocational_field_orig"] = {int(k): str(v) for k, v in _labels.itertuples(index=False, name=None)}
del _labels
# Stata line 797
d["vocational_field_str"] = d['vocational_field_orig'].map(VALUE_LABELS.get('vocational_field_orig', {})).fillna('')
# Stata line 798
d["vocational_field_str"] = d['code'].map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g')) + ' - ' + d['vocational_field_str']
# The Stata program drops the numeric original, then renames the string field.
d = d.drop(columns=['vocational_field_orig', 'code', '_merge'])
d = d.rename(columns={'vocational_field_str': 'vocational_field_orig'})
VALUE_LABELS.pop('vocational_field_orig', None)  # string field cannot carry numeric labels

# Stata line 801
d.loc[d['vocational_field_orig'] == '. - ', "vocational_field_orig"] = ''
VARIABLE_LABELS["vocational_field_orig"] = "Original field of training"

# <_vocational_financed_>
# Stata line 806
d["vocational_financed"] = np.nan
LABEL_DEFS["lblvocational_financed"] = {1: 'Employer', 2: 'Government', 3: 'Mixed Employer/Government', 4: 'Own funds', 5: 'Other'}
VARIABLE_LABELS["vocational_financed"] = "How training was financed"

# <_minlaborage_>
# Stata line 821
d["minlaborage"] = 10
VARIABLE_LABELS["minlaborage"] = "Labor module application age"

# ----------8.1: 7 day reference overall------------------------------*

# <_lstatus_>
# Stata line 830
d["lstatus"] = np.nan
# Stata line 834
d.loc[d['s5c1'] == 1, "lstatus"] = 1
# Stata line 839
d.loc[(d['s5c4'] == 1) & ((d['s5c6'] == 1) | (d['s5c7'] == 1)) & (d['lstatus'].isna() | d['lstatus'].eq('')), "lstatus"] = 1
# Stata line 842
d.loc[(d['s5c9'] == 4) & (d['lstatus'].isna() | d['lstatus'].eq('')), "lstatus"] = 1
# Stata line 845
d.loc[d['s5c9'].notna() & d['s5c9'].between(1, 3) & (d['s5c10'].notna() & d['s5c10'].between(1, 2)) & (d['lstatus'].isna() | d['lstatus'].eq('')), "lstatus"] = 1
# Stata line 848
d.loc[(d['s5c1'] == 2) & (d['s5c2'] == 2) & (d['s5c3'] == 2) & (d['s5c4'] == 2) & (d['s5c8'].notna() & d['s5c8'].between(1, 3)) & (d['s5c10'].notna() & d['s5c10'].between(1, 2)) & (d['lstatus'].isna() | d['lstatus'].eq('')), "lstatus"] = 1
# Stata line 853
d.loc[(d['s9c1'] == 1) & (d['s9c6'] == 1) & (d['lstatus'].isna() | d['lstatus'].eq('')), "lstatus"] = 2
# Stata line 861
d.loc[(d['lstatus'].isna() | d['lstatus'].eq('')) & (d['age'].isna() | (d['age'] >= d['minlaborage'])), "lstatus"] = 3
# Stata line 864
d.loc[d['age'] < d['minlaborage'], "lstatus"] = np.nan
VARIABLE_LABELS["lstatus"] = "Labor status 7 day recall"
LABEL_DEFS["lbllstatus"] = {1: 'Employed', 2: 'Unemployed', 3: 'Not in labor force'}
VALUE_LABELS["lstatus"] = LABEL_DEFS["lbllstatus"].copy()

# <_potential_lf_>
# Stata line 884
d["potential_lf"] = np.nan
# Stata line 885
d.loc[d['lstatus'] == 3, "potential_lf"] = 0
# Stata line 886
d.loc[(d['s9c1'] == 2) & (d['s9c6'] == 1) | (d['s9c1'] == 1) & (d['s9c6'] == 2), "potential_lf"] = 1
# Stata line 887
d.loc[(d['age'] < d['minlaborage']) & ~(d['age'].isna() | d['age'].eq('')), "potential_lf"] = np.nan
# Stata line 888
d.loc[d['lstatus'] != 3, "potential_lf"] = np.nan
VARIABLE_LABELS["potential_lf"] = "Potential labour force status"
LABEL_DEFS["lblpotential_lf"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["potential_lf"] = LABEL_DEFS["lblpotential_lf"].copy()

# <_underemployment_>
# Stata line 896
d["underemployment"] = np.nan
# Stata line 897
d.loc[d['s6c2'] == 1, "underemployment"] = 1
# Stata line 898
d.loc[d['s6c2'] == 2, "underemployment"] = 0
# Stata line 899
d.loc[d['age'] < d['minlaborage'], "underemployment"] = np.nan
# Stata line 900
d.loc[(d['age'] < d['minlaborage']) & ~(d['age'].isna() | d['age'].eq('')), "underemployment"] = np.nan
# Stata line 901
d.loc[d['lstatus'] != 1, "underemployment"] = np.nan
VARIABLE_LABELS["underemployment"] = "Underemployment status"
LABEL_DEFS["lblunderemployment"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["underemployment"] = LABEL_DEFS["lblunderemployment"].copy()

# <_nlfreason_>
# Stata line 909
d["nlfreason"] = np.nan
# Stata line 910
d["nlfreason_1"] = d['s9c9']
d.loc[~(d['lstatus'] == 3), "nlfreason_1"] = np.nan
# Stata line 911
_source_nlfreason_1 = d["nlfreason_1"].copy()
d.loc[(_source_nlfreason_1 == 7), "nlfreason_1"] = 1
d.loc[(_source_nlfreason_1 == 9), "nlfreason_1"] = 2
d.loc[_source_nlfreason_1.between(10, 11), "nlfreason_1"] = 3
d.loc[_source_nlfreason_1.between(1, 6) | _source_nlfreason_1.between(12, 13), "nlfreason_1"] = 5
d.loc[(_source_nlfreason_1 == 8), "nlfreason_1"] = 4
del _source_nlfreason_1
# Stata line 912
d["nlfreason_2"] = d['s9c5']
d.loc[~(d['lstatus'] == 3), "nlfreason_2"] = np.nan
# Stata line 913
_source_nlfreason_2 = d["nlfreason_2"].copy()
d.loc[(_source_nlfreason_2 == 9), "nlfreason_2"] = 1
d.loc[(_source_nlfreason_2 == 10), "nlfreason_2"] = 2
d.loc[(_source_nlfreason_2 == 12), "nlfreason_2"] = 4
d.loc[_source_nlfreason_2.between(1, 8) | (_source_nlfreason_2 == 11) | _source_nlfreason_2.between(13, 14), "nlfreason_2"] = 5
del _source_nlfreason_2
# Stata line 914
d["nlfreason"] = d['nlfreason_1']
# Stata line 915
d.loc[d['nlfreason'].isna() | d['nlfreason'].eq(''), "nlfreason"] = d['nlfreason_2']
# Stata line 916
d.loc[d['lstatus'] != 3, "nlfreason"] = np.nan
# Stata line 917
d.loc[(d['lstatus'] == 3) & d['nlfreason'].isna(), "nlfreason"] = 5
VARIABLE_LABELS["nlfreason"] = "Reason not in the labor force"
LABEL_DEFS["lblnlfreason"] = {1: 'Student', 2: 'Housekeeper', 3: 'Retired', 4: 'Disabled', 5: 'Other'}
VALUE_LABELS["nlfreason"] = LABEL_DEFS["lblnlfreason"].copy()

# <_unempldur_l_>
# Stata line 925
d["unempldur_l"] = np.nan
# Stata line 926
d.loc[d['lstatus'] == 2, "unempldur_l"] = d['s9c3']
# Stata line 927
_source_unempldur_l = d["unempldur_l"].copy()
d.loc[(_source_unempldur_l == 1), "unempldur_l"] = 0
d.loc[(_source_unempldur_l == 2), "unempldur_l"] = 1
d.loc[(_source_unempldur_l == 3), "unempldur_l"] = 3
d.loc[(_source_unempldur_l == 4), "unempldur_l"] = 6
d.loc[(_source_unempldur_l == 5), "unempldur_l"] = 12
del _source_unempldur_l
# Stata line 928
d.loc[d['lstatus'] == 1, "unempldur_l"] = np.nan
VARIABLE_LABELS["unempldur_l"] = "Unemployment duration (months) lower bracket"

# <_unempldur_u_>
# Stata line 934
d["unempldur_u"] = np.nan
# Stata line 935
d.loc[d['lstatus'] == 2, "unempldur_u"] = d['s9c3']
# Stata line 936
_source_unempldur_u = d["unempldur_u"].copy()
d.loc[(_source_unempldur_u == 1), "unempldur_u"] = 0
d.loc[(_source_unempldur_u == 2), "unempldur_u"] = 3
d.loc[(_source_unempldur_u == 3), "unempldur_u"] = 6
d.loc[(_source_unempldur_u == 4), "unempldur_u"] = 12
d.loc[(_source_unempldur_u == 5), "unempldur_u"] = np.nan
del _source_unempldur_u
# Stata line 937
d.loc[d['lstatus'] == 1, "unempldur_u"] = np.nan
VARIABLE_LABELS["unempldur_u"] = "Unemployment duration (months) upper bracket"

# ----------8.2: 7 day reference main job------------------------------*

# <_empstat_>
# Stata line 948
d["empstat"] = d['s5c11']
# Stata line 949
_source_empstat = d["empstat"].copy()
d.loc[(_source_empstat == 3) | (_source_empstat == 5), "empstat"] = 1
d.loc[(_source_empstat == 4), "empstat"] = 2
d.loc[(_source_empstat == 1), "empstat"] = 3
d.loc[(_source_empstat == 2), "empstat"] = 4
d.loc[(_source_empstat == 6), "empstat"] = 5
del _source_empstat
# Stata line 950
d.loc[~(d['s5c11'].notna() & d['s5c11'].between(1, 6)), "empstat"] = np.nan
# Stata line 951
d.loc[d['lstatus'] != 1, "empstat"] = np.nan
VARIABLE_LABELS["empstat"] = "Employment status during past week primary job 7 day recall"
LABEL_DEFS["lblempstat"] = {1: 'Paid employee', 2: 'Non-paid employee', 3: 'Employer', 4: 'Self-employed', 5: 'Other, workers not classifiable by status'}
VALUE_LABELS["empstat"] = LABEL_DEFS["lblempstat"].copy()

# <_ocusec_>
# Stata line 959
d["ocusec"] = d['s5c15']
# Stata line 960
_source_ocusec = d["ocusec"].copy()
d.loc[_source_ocusec.between(1, 3), "ocusec"] = 1
d.loc[(_source_ocusec == 4), "ocusec"] = 3
d.loc[_source_ocusec.between(5, 10), "ocusec"] = 2
d.loc[(_source_ocusec == 11), "ocusec"] = 4
del _source_ocusec
# Stata line 961
d.loc[d['lstatus'] != 1, "ocusec"] = np.nan
VARIABLE_LABELS["ocusec"] = "Sector of activity primary job 7 day recall"
LABEL_DEFS["lblocusec"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec"] = LABEL_DEFS["lblocusec"].copy()

# <_industry_orig_>
# Stata line 969
d["industry_orig"] = d['s5c13'].map(lambda v: '.' if pd.isna(v) else format(v, '04.0f'))
# Stata line 970
d.loc[d['lstatus'] != 1, "industry_orig"] = ''
# Stata line 971
d.loc[d['industry_orig'] == '.', "industry_orig"] = ''
VARIABLE_LABELS["industry_orig"] = "Original survey industry code, main job 7 day recall"

# <_industrycat_isic_>
# Stata line 977
d["industrycat_isic"] = d['industry_orig']
# Stata line 978
d.loc[d['lstatus'] != 1, "industrycat_isic"] = ''
# Stata line 979
d.loc[d['industrycat_isic'] == '.', "industrycat_isic"] = ''
# GLD int_classif_universe validation intentionally skipped.
VARIABLE_LABELS["industrycat_isic"] = "ISIC code of primary job 7 day recall"

# <_industrycat10_>
# Stata line 996
d["industrycat10"] = np.nan
# Stata line 997
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('0100', '0399'), "industrycat10"] = 1
# Stata line 998
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('0500', '0999'), "industrycat10"] = 2
# Stata line 999
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('1000', '3399'), "industrycat10"] = 3
# Stata line 1000
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('3500', '3900'), "industrycat10"] = 4
# Stata line 1001
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('4100', '4399'), "industrycat10"] = 5
# Stata line 1002
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('4500', '4799') | d['industrycat_isic'].notna() & d['industrycat_isic'].between('5500', '5699'), "industrycat10"] = 6
# Stata line 1003
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('4900', '5399') | d['industrycat_isic'].notna() & d['industrycat_isic'].between('5800', '6399'), "industrycat10"] = 7
# Stata line 1004
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('6400', '8299'), "industrycat10"] = 8
# Stata line 1005
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('8400', '8499'), "industrycat10"] = 9
# Stata line 1006
d.loc[d['industrycat_isic'].notna() & d['industrycat_isic'].between('8500', '9900'), "industrycat10"] = 10
VARIABLE_LABELS["industrycat10"] = "1 digit industry classification, primary job 7 day recall"
LABEL_DEFS["lblindustrycat10"] = {1: 'Agriculture', 2: 'Mining', 3: 'Manufacturing', 4: 'Public utilities', 5: 'Construction', 6: 'Commerce', 7: 'Transport and Comnunications', 8: 'Financial and Business Services', 9: 'Public Administration', 10: 'Other Services, Unspecified'}
VALUE_LABELS["industrycat10"] = LABEL_DEFS["lblindustrycat10"].copy()

# <_industrycat4_>
# Stata line 1015
d["industrycat4"] = d['industrycat10']
# Stata line 1016
_source_industrycat4 = d["industrycat4"].copy()
d.loc[(_source_industrycat4 == 1), "industrycat4"] = 1
d.loc[(_source_industrycat4 == 2) | (_source_industrycat4 == 3) | (_source_industrycat4 == 4) | (_source_industrycat4 == 5), "industrycat4"] = 2
d.loc[(_source_industrycat4 == 6) | (_source_industrycat4 == 7) | (_source_industrycat4 == 8) | (_source_industrycat4 == 9), "industrycat4"] = 3
d.loc[(_source_industrycat4 == 10), "industrycat4"] = 4
del _source_industrycat4
VARIABLE_LABELS["industrycat4"] = "Broad Economic Activities classification, primary job 7 day recall"
LABEL_DEFS["lblindustrycat4"] = {1: 'Agriculture', 2: 'Industry', 3: 'Services', 4: 'Other'}
VALUE_LABELS["industrycat4"] = LABEL_DEFS["lblindustrycat4"].copy()

# <_occup_orig_>
# Stata line 1024
d["occup_orig"] = d['s5c12'].map(lambda v: '.' if pd.isna(v) else format(v, '04.0f'))
# Stata line 1025
d.loc[d['lstatus'] != 1, "occup_orig"] = ''
# Stata line 1026
d.loc[d['industry_orig'] == '.', "occup_orig"] = ''
VARIABLE_LABELS["occup_orig"] = "Original occupation record primary job 7 day recall"

# <_occup_isco_>
# Stata line 1032
d["occup_isco"] = d['occup_orig']
# Stata line 1033
d.loc[d['lstatus'] != 1, "occup_isco"] = ''
# Stata line 1034
d.loc[d['occup_isco'] == '.', "occup_isco"] = ''
# Stata line 1037
d.loc[d['occup_isco'] == '4140', "occup_isco"] = '4100'
# GLD int_classif_universe validation intentionally skipped.
VARIABLE_LABELS["occup_isco"] = "ISCO code of primary job 7 day recall"

# <_occup_>
# Stata line 1053
d["occup"] = np.nan
# Stata line 1054
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('1000', '1999'), "occup"] = 1
# Stata line 1055
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('2000', '2999'), "occup"] = 2
# Stata line 1056
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('3000', '3999'), "occup"] = 3
# Stata line 1057
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('4000', '4999'), "occup"] = 4
# Stata line 1058
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('5000', '5999'), "occup"] = 5
# Stata line 1059
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('6000', '6999'), "occup"] = 6
# Stata line 1060
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('7000', '7999'), "occup"] = 7
# Stata line 1061
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('8000', '8999'), "occup"] = 8
# Stata line 1062
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('9000', '9999'), "occup"] = 9
# Stata line 1063
d.loc[d['occup_isco'].notna() & d['occup_isco'].between('0000', '0999'), "occup"] = 10
VARIABLE_LABELS["occup"] = "1 digit occupational classification, primary job 7 day recall"
LABEL_DEFS["lbloccup"] = {1: 'Managers', 2: 'Professionals', 3: 'Technicians', 4: 'Clerks', 5: 'Service and market sales workers', 6: 'Skilled agricultural', 7: 'Craft workers', 8: 'Machine operators', 9: 'Elementary occupations', 10: 'Armed forces', 99: 'Others'}
VALUE_LABELS["occup"] = LABEL_DEFS["lbloccup"].copy()

# <_occup_skill_>
# Stata line 1071
d["occup_skill"] = d['occup']
# Stata line 1072
d.loc[d['occup'].notna() & d['occup'].between(1, 3), "occup_skill"] = 3
# Stata line 1073
d.loc[d['occup'].notna() & d['occup'].between(4, 8), "occup_skill"] = 2
# Stata line 1074
d.loc[d['occup'] == 9, "occup_skill"] = 1
LABEL_DEFS["lblskill"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill"] = LABEL_DEFS["lblskill"].copy()
VARIABLE_LABELS["occup_skill"] = "Skill based on ISCO standard primary job 7 day recall"

# <_wage_no_compen_>
# Stata line 1082
d["last_week"] = d['s7c33']
# Stata line 1083
d["last_month"] = d['s7c43']
# Stata line 1084
d["last_year"] = d['s7c9']
# Stata line 1087
d.loc[d['last_week'] <= 0, "last_week"] = np.nan
# Stata line 1088
d.loc[d['last_month'] <= 0, "last_month"] = np.nan
# Stata line 1089
d.loc[d['last_year'] <= 0, "last_year"] = np.nan
# Stata line 1092
d.loc[~(d['last_week'].isna() | d['last_week'].eq('')) & ~(d['last_month'].isna() | d['last_month'].eq('')), "last_week"] = np.nan
# Stata line 1095
d["wage_no_compen"] = d[['last_week', 'last_month', 'last_year']].sum(axis=1, min_count=1)
# Stata line 1098
d.loc[d['empstat'] == 2, "wage_no_compen"] = np.nan
# Stata line 1099
d.loc[d['lstatus'] != 1, "wage_no_compen"] = np.nan
VARIABLE_LABELS["wage_no_compen"] = "Last wage payment primary job 7 day recall"
_drop_cols = [col for col in d.columns if any(fnmatch.fnmatchcase(col, pat) for pat in ['last_week', 'last_month', 'last_year'])]
d = d.drop(columns=_drop_cols)
del _drop_cols

# <_unitwage_>
# Stata line 1113
d["unitwage"] = np.nan
# Stata line 1114
d.loc[~(d['s7c33'].isna() | d['s7c33'].eq('')) & (d['s7c33'].isna() | (d['s7c33'] > 0)) & (d['lstatus'] == 1), "unitwage"] = 2
# Stata line 1115
d.loc[~(d['s7c43'].isna() | d['s7c43'].eq('')) & (d['s7c43'].isna() | (d['s7c43'] > 0)) & (d['lstatus'] == 1), "unitwage"] = 5
# Stata line 1116
d.loc[~(d['s7c9'].isna() | d['s7c9'].eq('')) & (d['s7c9'].isna() | (d['s7c9'] > 0)) & (d['lstatus'] == 1) & (d['s7c43'].isna() | d['s7c43'].eq('')) & (d['s7c33'].isna() | d['s7c33'].eq('')), "unitwage"] = 8
# Stata line 1118
d.loc[d['empstat'] == 2, "unitwage"] = np.nan
# Stata line 1119
d.loc[d['lstatus'] != 1, "unitwage"] = np.nan
VARIABLE_LABELS["unitwage"] = "Last wages' time unit primary job 7 day recall"
LABEL_DEFS["lblunitwage"] = {1: 'Daily', 2: 'Weekly', 3: 'Every two weeks', 4: 'Bimonthly', 5: 'Monthly', 6: 'Trimester', 7: 'Biannual', 8: 'Annually', 9: 'Hourly', 10: 'Other'}
VALUE_LABELS["unitwage"] = LABEL_DEFS["lblunitwage"].copy()

# <_whours_>
# Stata line 1130
d["whours"] = np.nan
# Stata line 1131
d.loc[d['lstatus'] == 1, "whours"] = d['s5c24']
# Stata line 1132
d.loc[(d['whours'] == 0) & (d['lstatus'] == 1), "whours"] = np.nan
VARIABLE_LABELS["whours"] = "Hours of work in last week primary job 7 day recall"

# <_wmonths_>
# Stata line 1138
d["wmonths"] = np.nan
# Stata line 1139
d.loc[d['lstatus'] != 1, "wmonths"] = np.nan
VARIABLE_LABELS["wmonths"] = "Months of work in past 12 months primary job 7 day recall"

# <_wage_total_>
# Stata line 1151
d["wage_total"] = np.nan
VARIABLE_LABELS["wage_total"] = "Annualized total wage primary job 7 day recall"

# <_contract_>
# Stata line 1157
d["contract"] = np.nan
# Stata line 1158
d.loc[d['lstatus'] == 1, "contract"] = d['s7c1']
# Stata line 1159
_source_contract = d["contract"].copy()
d.loc[_source_contract.between(1, 6), "contract"] = 1
d.loc[(_source_contract == 7), "contract"] = 0
del _source_contract
VARIABLE_LABELS["contract"] = "Employment has contract primary job 7 day recall"
LABEL_DEFS["lblcontract"] = {0: 'Without contract', 1: 'With contract'}
VALUE_LABELS["contract"] = LABEL_DEFS["lblcontract"].copy()

# <_healthins_>
# Stata line 1167
d["healthins"] = np.nan
VARIABLE_LABELS["healthins"] = "Employment has health insurance primary job 7 day recall"
LABEL_DEFS["lblhealthins"] = {0: 'Without health insurance', 1: 'With health insurance'}
VALUE_LABELS["healthins"] = LABEL_DEFS["lblhealthins"].copy()

# <_socialsec_>
# Stata line 1175
d["socialsec"] = 0
# Stata line 1176
d.loc[(d['s7c61'] == 1) | (d['s7c64'] == 4), "socialsec"] = 1
# Stata line 1177
d.loc[d['lstatus'] != 1, "socialsec"] = np.nan
VARIABLE_LABELS["socialsec"] = "Employment has social security insurance primary job 7 day recall"
LABEL_DEFS["lblsocialsec"] = {1: 'With social security', 0: 'Without social secturity'}
VALUE_LABELS["socialsec"] = LABEL_DEFS["lblsocialsec"].copy()

# <_union_>
# Stata line 1185
d["union"] = np.nan
# Stata line 1186
d.loc[d['s5c20'] == 1, "union"] = 1
# Stata line 1187
d.loc[(d['s5c20'] == 2) | (d['s5c20'] == 3), "union"] = 0
# Stata line 1188
d.loc[d['lstatus'] != 1, "union"] = np.nan
VARIABLE_LABELS["union"] = "Union membership at primary job 7 day recall"
LABEL_DEFS["lblunion"] = {0: 'Not union member', 1: 'Union member'}
VALUE_LABELS["union"] = LABEL_DEFS["lblunion"].copy()

# <_firmsize_l_>
# Stata line 1196
d["firmsize_l"] = d['s5c18']
# Stata line 1197
d.loc[d['lstatus'] != 1, "firmsize_l"] = np.nan
VARIABLE_LABELS["firmsize_l"] = "Firm size (lower bracket) primary job 7 day recall"

# <_firmsize_u_>
# Stata line 1203
d["firmsize_u"] = d['s5c18']
# Stata line 1204
d.loc[d['lstatus'] != 1, "firmsize_u"] = np.nan
VARIABLE_LABELS["firmsize_u"] = "Firm size (upper bracket) primary job 7 day recall"

# ----------8.3: 7 day reference secondary job------------------------------*

# <_empstat_2_>
# Stata line 1217
d["empstat_2"] = d['s5c26']
# Stata line 1218
_source_empstat_2 = d["empstat_2"].copy()
d.loc[(_source_empstat_2 == 3) | (_source_empstat_2 == 5), "empstat_2"] = 1
d.loc[(_source_empstat_2 == 4), "empstat_2"] = 2
d.loc[(_source_empstat_2 == 1), "empstat_2"] = 3
d.loc[(_source_empstat_2 == 2), "empstat_2"] = 4
d.loc[(_source_empstat_2 == 6), "empstat_2"] = 5
d.loc[(_source_empstat_2 == 0), "empstat_2"] = np.nan
del _source_empstat_2
# Stata line 1219
d.loc[d['s5c25'] != 1, "empstat_2"] = np.nan
# Stata line 1220
d.loc[d['lstatus'] != 1, "empstat_2"] = np.nan
VARIABLE_LABELS["empstat_2"] = "Employment status during past week secondary job 7 day recall"
VALUE_LABELS["empstat_2"] = LABEL_DEFS["lblempstat"].copy()

# <_ocusec_2_>
# Stata line 1227
d["ocusec_2"] = d['s5c30']
# Stata line 1228
_source_ocusec_2 = d["ocusec_2"].copy()
d.loc[_source_ocusec_2.between(1, 3), "ocusec_2"] = 1
d.loc[(_source_ocusec_2 == 4), "ocusec_2"] = 3
d.loc[_source_ocusec_2.between(5, 10), "ocusec_2"] = 2
d.loc[(_source_ocusec_2 == 11), "ocusec_2"] = 4
del _source_ocusec_2
# Stata line 1229
d.loc[d['s5c25'] != 1, "ocusec_2"] = np.nan
# Stata line 1230
d.loc[d['lstatus'] != 1, "ocusec_2"] = np.nan
VARIABLE_LABELS["ocusec_2"] = "Sector of activity secondary job 7 day recall"
VALUE_LABELS["ocusec_2"] = LABEL_DEFS["lblocusec"].copy()

# <_industry_orig_2_>
# Stata line 1237
d["industry_orig_2"] = d['s5c28'].map(lambda v: '.' if pd.isna(v) else format(v, '04.0f'))
# Stata line 1238
d.loc[d['lstatus'] != 1, "industry_orig_2"] = ''
# Stata line 1239
d.loc[d['industry_orig'] == '.', "industry_orig_2"] = ''
VARIABLE_LABELS["industry_orig_2"] = "Original survey industry code, secondary job 7 day recall"

# <_industrycat_isic_2_>
# Stata line 1246
d["industrycat_isic_2"] = d['industry_orig_2']
# Stata line 1247
d.loc[d['lstatus'] != 1, "industrycat_isic_2"] = ''
# Stata line 1248
d.loc[d['industrycat_isic_2'] == '.', "industrycat_isic_2"] = ''
# Stata line 1249
d.loc[d['empstat_2'].isna() | d['empstat_2'].eq(''), "industrycat_isic_2"] = ''
# Stata line 1250
d.loc[d['industry_orig_2'] == '320', "industrycat_isic_2"] = '0320'
# Stata line 1252
d.loc[d['industry_orig_2'] == '6121', "industrycat_isic_2"] = '6120'
# GLD int_classif_universe validation intentionally skipped.
VARIABLE_LABELS["industrycat_isic_2"] = "ISIC code of secondary job 7 day recall"

# <_industrycat10_2_>
# Stata line 1267
d["industrycat10_2"] = np.nan
# Stata line 1268
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('0100', '0399'), "industrycat10_2"] = 1
# Stata line 1269
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('0500', '0999'), "industrycat10_2"] = 2
# Stata line 1270
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('1000', '3399'), "industrycat10_2"] = 3
# Stata line 1271
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('3500', '3900'), "industrycat10_2"] = 4
# Stata line 1272
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('4100', '4399'), "industrycat10_2"] = 5
# Stata line 1273
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('4500', '4799') | d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('5500', '5699'), "industrycat10_2"] = 6
# Stata line 1274
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('4900', '5399') | d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('5800', '6399'), "industrycat10_2"] = 7
# Stata line 1275
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('6400', '8299'), "industrycat10_2"] = 8
# Stata line 1276
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('8400', '8499'), "industrycat10_2"] = 9
# Stata line 1277
d.loc[d['industrycat_isic_2'].notna() & d['industrycat_isic_2'].between('8500', '9900'), "industrycat10_2"] = 10
VARIABLE_LABELS["industrycat10_2"] = "1 digit industry classification, secondary job 7 day recall"
VALUE_LABELS["industrycat10_2"] = LABEL_DEFS["lblindustrycat10"].copy()

# <_industrycat4_2_>
# Stata line 1284
d["industrycat4_2"] = d['industrycat10_2']
# Stata line 1285
_source_industrycat4_2 = d["industrycat4_2"].copy()
d.loc[(_source_industrycat4_2 == 1), "industrycat4_2"] = 1
d.loc[(_source_industrycat4_2 == 2) | (_source_industrycat4_2 == 3) | (_source_industrycat4_2 == 4) | (_source_industrycat4_2 == 5), "industrycat4_2"] = 2
d.loc[(_source_industrycat4_2 == 6) | (_source_industrycat4_2 == 7) | (_source_industrycat4_2 == 8) | (_source_industrycat4_2 == 9), "industrycat4_2"] = 3
d.loc[(_source_industrycat4_2 == 10), "industrycat4_2"] = 4
del _source_industrycat4_2
VARIABLE_LABELS["industrycat4_2"] = "Broad Economic Activities classification, secondary job 7 day recall"
VALUE_LABELS["industrycat4_2"] = LABEL_DEFS["lblindustrycat4"].copy()

# <_occup_orig_2_>
# Stata line 1292
d["occup_orig_2"] = d['s5c27'].map(lambda v: '.' if pd.isna(v) else format(v, '04.0f'))
# Stata line 1293
d.loc[d['lstatus'] != 1, "occup_orig_2"] = ''
# Stata line 1294
d.loc[d['industry_orig'] == '.', "occup_orig_2"] = ''
VARIABLE_LABELS["occup_orig_2"] = "Original occupation record secondary job 7 day recall"

# <_occup_isco_2_>
# Stata line 1300
d["occup_isco_2"] = d['occup_orig_2']
# Stata line 1301
d.loc[d['lstatus'] != 1, "occup_isco_2"] = ''
# Stata line 1302
d.loc[d['occup_isco_2'] == '.', "occup_isco_2"] = ''
# Stata line 1305
d.loc[d['occup_isco_2'] == '4140', "occup_isco_2"] = '4100'
# Stata line 1306
d.loc[d['occup_isco_2'] == '2333', "occup_isco_2"] = '2300'
# Stata line 1307
d.loc[d['occup_isco_2'] == '9516', "occup_isco_2"] = '9500'
# GLD int_classif_universe validation intentionally skipped.
VARIABLE_LABELS["occup_isco_2"] = "ISCO code of secondary job 7 day recall"

# <_occup_2_>
# Stata line 1322
d["occup_2"] = np.nan
# Stata line 1323
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('1000', '1999'), "occup_2"] = 1
# Stata line 1324
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('2000', '2999'), "occup_2"] = 2
# Stata line 1325
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('3000', '3999'), "occup_2"] = 3
# Stata line 1326
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('4000', '4999'), "occup_2"] = 4
# Stata line 1327
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('5000', '5999'), "occup_2"] = 5
# Stata line 1328
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('6000', '6999'), "occup_2"] = 6
# Stata line 1329
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('7000', '7999'), "occup_2"] = 7
# Stata line 1330
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('8000', '8999'), "occup_2"] = 8
# Stata line 1331
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('9000', '9999'), "occup_2"] = 9
# Stata line 1332
d.loc[d['occup_isco_2'].notna() & d['occup_isco_2'].between('0000', '0999'), "occup_2"] = 10
VARIABLE_LABELS["occup_2"] = "1 digit occupational classification secondary job 7 day recall"
VALUE_LABELS["occup_2"] = LABEL_DEFS["lbloccup"].copy()

# <_occup_skill_2_>
# Stata line 1339
d["occup_skill_2"] = np.nan
# Stata line 1340
d.loc[d['occup_2'].notna() & d['occup_2'].between(1, 3), "occup_skill_2"] = 3
# Stata line 1341
d.loc[d['occup_2'].notna() & d['occup_2'].between(4, 8), "occup_skill_2"] = 2
# Stata line 1342
d.loc[d['occup_2'] == 9, "occup_skill_2"] = 1
LABEL_DEFS["lblskill2"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_2"] = LABEL_DEFS["lblskill2"].copy()
VARIABLE_LABELS["occup_skill_2"] = "Skill based on ISCO standard secondary job 7 day recall"

# <_wage_no_compen_2_>
# Stata line 1350
d["wage_no_compen_2"] = np.nan
VARIABLE_LABELS["wage_no_compen_2"] = "Last wage payment secondary job 7 day recall"

# <_unitwage_2_>
# Stata line 1356
d["unitwage_2"] = np.nan
VARIABLE_LABELS["unitwage_2"] = "Last wages' time unit secondary job 7 day recall"
VALUE_LABELS["unitwage_2"] = LABEL_DEFS["lblunitwage"].copy()

# <_whours_2_>
# Stata line 1363
d["whours_2"] = d['s5c35']
# Stata line 1364
d.loc[d['s5c25'] != 1, "whours_2"] = np.nan
VARIABLE_LABELS["whours_2"] = "Hours of work in last week secondary job 7 day recall"

# <_wmonths_2_>
# Stata line 1370
d["wmonths_2"] = np.nan
VARIABLE_LABELS["wmonths_2"] = "Months of work in past 12 months secondary job 7 day recall"

# <_wage_total_2_>
# Stata line 1376
d["wage_total_2"] = np.nan
VARIABLE_LABELS["wage_total_2"] = "Annualized total wage secondary job 7 day recall"

# <_firmsize_l_2_>
# Stata line 1382
d["firmsize_l_2"] = d['s5c33']
# Stata line 1383
d.loc[(d['s5c25'] != 1) | (d['s5c33'] == 0), "firmsize_l_2"] = np.nan
VARIABLE_LABELS["firmsize_l_2"] = "Firm size (lower bracket) secondary job 7 day recall"

# <_firmsize_u_2_>
# Stata line 1389
d["firmsize_u_2"] = d['s5c33']
# Stata line 1390
d.loc[(d['s5c25'] != 1) | (d['s5c33'] == 0), "firmsize_l_2"] = np.nan
VARIABLE_LABELS["firmsize_u_2"] = "Firm size (upper bracket) secondary job 7 day recall"

# ----------8.4: 7 day reference additional jobs------------------------------*

# <_t_hours_others_>
# Stata line 1399
d["t_hours_others"] = np.nan
VARIABLE_LABELS["t_hours_others"] = "Annualized hours worked in all but primary and secondary jobs 7 day recall"

# <_t_wage_nocompen_others_>
# Stata line 1405
d["t_wage_nocompen_others"] = np.nan
VARIABLE_LABELS["t_wage_nocompen_others"] = "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_others_>
# Stata line 1411
d["t_wage_others"] = np.nan
VARIABLE_LABELS["t_wage_others"] = "Annualized wage in all but primary and secondary jobs (12-mon ref period)"

# ----------8.5: 7 day reference total summary------------------------------*

# <_t_hours_total_>
# Stata line 1420
d["t_hours_total"] = np.nan
VARIABLE_LABELS["t_hours_total"] = "Annualized hours worked in all jobs 7 day recall"

# <_t_wage_nocompen_total_>
# Stata line 1426
d["t_wage_nocompen_total"] = np.nan
VARIABLE_LABELS["t_wage_nocompen_total"] = "Annualized wage in all jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_total_>
# Stata line 1432
d["t_wage_total"] = np.nan
VARIABLE_LABELS["t_wage_total"] = "Annualized total wage for all jobs 7 day recall"

# ----------8.6: 12 month reference overall------------------------------*

# <_lstatus_year_>
# Stata line 1442
d["lstatus_year"] = np.nan
# Stata line 1443
d.loc[(d['age'] < d['minlaborage']) & ~(d['age'].isna() | d['age'].eq('')), "lstatus_year"] = np.nan
VARIABLE_LABELS["lstatus_year"] = "Labor status during last year"
LABEL_DEFS["lbllstatus_year"] = {1: 'Employed', 2: 'Unemployed', 3: 'Non-LF'}
VALUE_LABELS["lstatus_year"] = LABEL_DEFS["lbllstatus_year"].copy()

# <_potential_lf_year_>
# Stata line 1450
d["potential_lf_year"] = np.nan
# Stata line 1451
d.loc[(d['age'] < d['minlaborage']) & ~(d['age'].isna() | d['age'].eq('')), "potential_lf_year"] = np.nan
# Stata line 1452
d.loc[d['lstatus_year'] != 3, "potential_lf_year"] = np.nan
VARIABLE_LABELS["potential_lf_year"] = "Potential labour force status"
LABEL_DEFS["lblpotential_lf_year"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["potential_lf_year"] = LABEL_DEFS["lblpotential_lf_year"].copy()

# <_underemployment_year_>
# Stata line 1460
d["underemployment_year"] = np.nan
# Stata line 1461
d.loc[(d['age'] < d['minlaborage']) & ~(d['age'].isna() | d['age'].eq('')), "underemployment_year"] = np.nan
# Stata line 1462
d.loc[d['lstatus_year'] == 1, "underemployment_year"] = np.nan
VARIABLE_LABELS["underemployment_year"] = "Underemployment status"
LABEL_DEFS["lblunderemployment_year"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["underemployment_year"] = LABEL_DEFS["lblunderemployment_year"].copy()

# <_nlfreason_year_>
# Stata line 1470
d["nlfreason_year"] = np.nan
VARIABLE_LABELS["nlfreason_year"] = "Reason not in the labor force"
LABEL_DEFS["lblnlfreason_year"] = {1: 'Student', 2: 'Housekeeper', 3: 'Retired', 4: 'Disabled', 5: 'Other'}
VALUE_LABELS["nlfreason_year"] = LABEL_DEFS["lblnlfreason_year"].copy()

# <_unempldur_l_year_>
# Stata line 1478
d["unempldur_l_year"] = np.nan
VARIABLE_LABELS["unempldur_l_year"] = "Unemployment duration (months) lower bracket"

# <_unempldur_u_year_>
# Stata line 1484
d["unempldur_u_year"] = np.nan
VARIABLE_LABELS["unempldur_u_year"] = "Unemployment duration (months) upper bracket"

# ----------8.7: 12 month reference main job------------------------------*

# <_empstat_year_>
# Stata line 1495
d["empstat_year"] = np.nan
VARIABLE_LABELS["empstat_year"] = "Employment status during past week primary job 12 month recall"
LABEL_DEFS["lblempstat_year"] = {1: 'Paid employee', 2: 'Non-paid employee', 3: 'Employer', 4: 'Self-employed', 5: 'Other, workers not classifiable by status'}
VALUE_LABELS["empstat_year"] = LABEL_DEFS["lblempstat_year"].copy()

# <_ocusec_year_>
# Stata line 1502
d["ocusec_year"] = np.nan
VARIABLE_LABELS["ocusec_year"] = "Sector of activity primary job 12 month recall"
LABEL_DEFS["lblocusec_year"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec_year"] = LABEL_DEFS["lblocusec_year"].copy()

# <_industry_orig_year_>
# Stata line 1509
d["industry_orig_year"] = np.nan
VARIABLE_LABELS["industry_orig_year"] = "Original industry record main job 12 month recall"

# <_industrycat_isic_year_>
# Stata line 1515
d["industrycat_isic_year"] = np.nan
VARIABLE_LABELS["industrycat_isic_year"] = "ISIC code of primary job 12 month recall"

# <_industrycat10_year_>
# Stata line 1531
d["industrycat10_year"] = np.nan
VARIABLE_LABELS["industrycat10_year"] = "1 digit industry classification, primary job 12 month recall"
LABEL_DEFS["lblindustrycat10_year"] = {1: 'Agriculture', 2: 'Mining', 3: 'Manufacturing', 4: 'Public utilities', 5: 'Construction', 6: 'Commerce', 7: 'Transport and Comnunications', 8: 'Financial and Business Services', 9: 'Public Administration', 10: 'Other Services, Unspecified'}
VALUE_LABELS["industrycat10_year"] = LABEL_DEFS["lblindustrycat10_year"].copy()

# <_industrycat4_year_>
# Stata line 1539
d["industrycat4_year"] = d['industrycat10_year']
# Stata line 1540
_source_industrycat4_year = d["industrycat4_year"].copy()
d.loc[(_source_industrycat4_year == 1), "industrycat4_year"] = 1
d.loc[(_source_industrycat4_year == 2) | (_source_industrycat4_year == 3) | (_source_industrycat4_year == 4) | (_source_industrycat4_year == 5), "industrycat4_year"] = 2
d.loc[(_source_industrycat4_year == 6) | (_source_industrycat4_year == 7) | (_source_industrycat4_year == 8) | (_source_industrycat4_year == 9), "industrycat4_year"] = 3
d.loc[(_source_industrycat4_year == 10), "industrycat4_year"] = 4
del _source_industrycat4_year
VARIABLE_LABELS["industrycat4_year"] = "Broad Economic Activities classification, primary job 12 month recall"
LABEL_DEFS["lblindustrycat4_year"] = {1: 'Agriculture', 2: 'Industry', 3: 'Services', 4: 'Other'}
VALUE_LABELS["industrycat4_year"] = LABEL_DEFS["lblindustrycat4_year"].copy()

# <_occup_orig_year_>
# Stata line 1548
d["occup_orig_year"] = np.nan
VARIABLE_LABELS["occup_orig_year"] = "Original occupation record primary job 12 month recall"

# <_occup_isco_year_>
# Stata line 1554
d["occup_isco_year"] = ''
VARIABLE_LABELS["occup_isco_year"] = "ISCO code of primary job 12 month recall"

# <_occup_year_>
# Stata line 1571
d["occup_year"] = np.nan
VARIABLE_LABELS["occup_year"] = "1 digit occupational classification, primary job 12 month recall"
LABEL_DEFS["lbloccup_year"] = {1: 'Managers', 2: 'Professionals', 3: 'Technicians', 4: 'Clerks', 5: 'Service and market sales workers', 6: 'Skilled agricultural', 7: 'Craft workers', 8: 'Machine operators', 9: 'Elementary occupations', 10: 'Armed forces', 99: 'Others'}
VALUE_LABELS["occup_year"] = LABEL_DEFS["lbloccup_year"].copy()

# <_occup_skill_year_>
# Stata line 1579
d["occup_skill_year"] = np.nan
# Stata line 1580
d.loc[d['occup_year'].notna() & d['occup_year'].between(1, 3), "occup_skill_year"] = 3
# Stata line 1581
d.loc[d['occup_year'].notna() & d['occup_year'].between(4, 8), "occup_skill_year"] = 2
# Stata line 1582
d.loc[d['occup_year'] == 9, "occup_skill_year"] = 1
LABEL_DEFS["lblskillyear"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_year"] = LABEL_DEFS["lblskillyear"].copy()
VARIABLE_LABELS["occup_skill_year"] = "Skill based on ISCO standard primary job 12 month recall"

# <_wage_no_compen_year_> --- this var has the same name as other and when quoted in the keep and order codes is repeated.
# Stata line 1590
d["wage_no_compen_year"] = np.nan
VARIABLE_LABELS["wage_no_compen_year"] = "Last wage payment primary job 12 month recall"

# <_unitwage_year_>
# Stata line 1596
d["unitwage_year"] = np.nan
VARIABLE_LABELS["unitwage_year"] = "Last wages' time unit primary job 12 month recall"
LABEL_DEFS["lblunitwage_year"] = {1: 'Daily', 2: 'Weekly', 3: 'Every two weeks', 4: 'Bimonthly', 5: 'Monthly', 6: 'Trimester', 7: 'Biannual', 8: 'Annually', 9: 'Hourly', 10: 'Other'}
VALUE_LABELS["unitwage_year"] = LABEL_DEFS["lblunitwage_year"].copy()

# <_whours_year_>
# Stata line 1604
d["whours_year"] = np.nan
VARIABLE_LABELS["whours_year"] = "Hours of work in last week primary job 12 month recall"

# <_wmonths_year_>
# Stata line 1610
d["wmonths_year"] = np.nan
VARIABLE_LABELS["wmonths_year"] = "Months of work in past 12 months primary job 12 month recall"

# <_wage_total_year_>
# Stata line 1616
d["wage_total_year"] = np.nan
VARIABLE_LABELS["wage_total_year"] = "Annualized total wage primary job 12 month recall"

# <_contract_year_>
# Stata line 1622
d["contract_year"] = np.nan
VARIABLE_LABELS["contract_year"] = "Employment has contract primary job 12 month recall"
LABEL_DEFS["lblcontract_year"] = {0: 'Without contract', 1: 'With contract'}
VALUE_LABELS["contract_year"] = LABEL_DEFS["lblcontract_year"].copy()

# <_healthins_year_>
# Stata line 1630
d["healthins_year"] = np.nan
VARIABLE_LABELS["healthins_year"] = "Employment has health insurance primary job 12 month recall"
LABEL_DEFS["lblhealthins_year"] = {0: 'Without health insurance', 1: 'With health insurance'}
VALUE_LABELS["healthins_year"] = LABEL_DEFS["lblhealthins_year"].copy()

# <_socialsec_year_>
# Stata line 1638
d["socialsec_year"] = np.nan
VARIABLE_LABELS["socialsec_year"] = "Employment has social security insurance primary job 7 day recall"
LABEL_DEFS["lblsocialsec_year"] = {1: 'With social security', 0: 'Without social secturity'}
VALUE_LABELS["socialsec_year"] = LABEL_DEFS["lblsocialsec_year"].copy()

# <_union_year_>
# Stata line 1646
d["union_year"] = np.nan
VARIABLE_LABELS["union_year"] = "Union membership at primary job 12 month recall"
LABEL_DEFS["lblunion_year"] = {0: 'Not union member', 1: 'Union member'}
VALUE_LABELS["union_year"] = LABEL_DEFS["lblunion_year"].copy()

# <_firmsize_l_year_>
# Stata line 1654
d["firmsize_l_year"] = np.nan
VARIABLE_LABELS["firmsize_l_year"] = "Firm size (lower bracket) primary job 12 month recall"

# <_firmsize_u_year_>
# Stata line 1660
d["firmsize_u_year"] = np.nan
VARIABLE_LABELS["firmsize_u_year"] = "Firm size (upper bracket) primary job 12 month recall"

# ----------8.8: 12 month reference secondary job------------------------------*

# <_empstat_2_year_>
# Stata line 1672
d["empstat_2_year"] = np.nan
VARIABLE_LABELS["empstat_2_year"] = "Employment status during past week secondary job 12 month recall"
VALUE_LABELS["empstat_2_year"] = LABEL_DEFS["lblempstat_year"].copy()

# <_ocusec_2_year_>
# Stata line 1679
d["ocusec_2_year"] = np.nan
VARIABLE_LABELS["ocusec_2_year"] = "Sector of activity secondary job 12 month recall"
LABEL_DEFS["lblocusec_2_year"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec_2_year"] = LABEL_DEFS["lblocusec_2_year"].copy()

# <_industry_orig_2_year_>
# Stata line 1688
d["industry_orig_2_year"] = np.nan
VARIABLE_LABELS["industry_orig_2_year"] = "Original survey industry code, secondary job 12 month recall"

# <_industrycat_isic_2_year_>
# Stata line 1695
d["industrycat_isic_2_year"] = np.nan
VARIABLE_LABELS["industrycat_isic_2_year"] = "ISIC code of secondary job 12 month recall"

# <_industrycat10_2_year_>
# Stata line 1701
d["industrycat10_2_year"] = np.nan
VARIABLE_LABELS["industrycat10_2_year"] = "1 digit industry classification, secondary job 12 month recall"
VALUE_LABELS["industrycat10_2_year"] = LABEL_DEFS["lblindustrycat10_year"].copy()

# <_industrycat4_2_year_>
# Stata line 1708
d["industrycat4_2_year"] = d['industrycat10_2_year']
# Stata line 1709
_source_industrycat4_2_year = d["industrycat4_2_year"].copy()
d.loc[(_source_industrycat4_2_year == 1), "industrycat4_2_year"] = 1
d.loc[(_source_industrycat4_2_year == 2) | (_source_industrycat4_2_year == 3) | (_source_industrycat4_2_year == 4) | (_source_industrycat4_2_year == 5), "industrycat4_2_year"] = 2
d.loc[(_source_industrycat4_2_year == 6) | (_source_industrycat4_2_year == 7) | (_source_industrycat4_2_year == 8) | (_source_industrycat4_2_year == 9), "industrycat4_2_year"] = 3
d.loc[(_source_industrycat4_2_year == 10), "industrycat4_2_year"] = 4
del _source_industrycat4_2_year
VARIABLE_LABELS["industrycat4_2_year"] = "Broad Economic Activities classification, secondary job 12 month recall"
VALUE_LABELS["industrycat4_2_year"] = LABEL_DEFS["lblindustrycat4_year"].copy()

# <_occup_orig_2_year_>
# Stata line 1716
d["occup_orig_2_year"] = np.nan
VARIABLE_LABELS["occup_orig_2_year"] = "Original occupation record secondary job 12 month recall"

# <_occup_isco_2_year_>
# Stata line 1722
d["occup_isco_2_year"] = ''
VARIABLE_LABELS["occup_isco_2_year"] = "ISCO code of secondary job 12 month recall"

# <_occup_2_year_>
# Stata line 1728
d["occup_2_year"] = np.nan
VARIABLE_LABELS["occup_2_year"] = "1 digit occupational classification, secondary job 12 month recall"
VALUE_LABELS["occup_2_year"] = LABEL_DEFS["lbloccup_year"].copy()

# <_occup_skill_2_year_>
# Stata line 1735
d["occup_skill_2_year"] = np.nan
# Stata line 1736
d.loc[d['occup_2_year'].notna() & d['occup_2_year'].between(1, 3), "occup_skill_2_year"] = 3
# Stata line 1737
d.loc[d['occup_2_year'].notna() & d['occup_2_year'].between(4, 8), "occup_skill_2_year"] = 2
# Stata line 1738
d.loc[d['occup_2_year'] == 9, "occup_skill_2_year"] = 1
LABEL_DEFS["lblskilly2"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_2_year"] = LABEL_DEFS["lblskilly2"].copy()
VARIABLE_LABELS["occup_skill_2_year"] = "Skill based on ISCO standard secondary job 12 month recall"

# <_wage_no_compen_2_year_>
# Stata line 1746
d["wage_no_compen_2_year"] = np.nan
VARIABLE_LABELS["wage_no_compen_2_year"] = "Last wage payment secondary job 12 month recall"

# <_unitwage_2_year_>
# Stata line 1752
d["unitwage_2_year"] = np.nan
VARIABLE_LABELS["unitwage_2_year"] = "Last wages' time unit secondary job 12 month recall"
VALUE_LABELS["unitwage_2_year"] = LABEL_DEFS["lblunitwage_year"].copy()

# <_whours_2_year_>
# Stata line 1759
d["whours_2_year"] = np.nan
VARIABLE_LABELS["whours_2_year"] = "Hours of work in last week secondary job 12 month recall"

# <_wmonths_2_year_>
# Stata line 1765
d["wmonths_2_year"] = np.nan
VARIABLE_LABELS["wmonths_2_year"] = "Months of work in past 12 months secondary job 12 month recall"

# <_wage_total_2_year_>
# Stata line 1771
d["wage_total_2_year"] = np.nan
VARIABLE_LABELS["wage_total_2_year"] = "Annualized total wage secondary job 12 month recall"

# <_firmsize_l_2_year_>
# Stata line 1776
d["firmsize_l_2_year"] = np.nan
VARIABLE_LABELS["firmsize_l_2_year"] = "Firm size (lower bracket) secondary job 12 month recall"

# <_firmsize_u_2_year_>
# Stata line 1782
d["firmsize_u_2_year"] = np.nan
VARIABLE_LABELS["firmsize_u_2_year"] = "Firm size (upper bracket) secondary job 12 month recall"

# ----------8.9: 12 month reference additional jobs------------------------------*

# <_t_hours_others_year_>
# Stata line 1793
d["t_hours_others_year"] = np.nan
VARIABLE_LABELS["t_hours_others_year"] = "Annualized hours worked in all but primary and secondary jobs 12 month recall"

# <_t_wage_nocompen_others_year_>
# Stata line 1798
d["t_wage_nocompen_others_year"] = np.nan
VARIABLE_LABELS["t_wage_nocompen_others_year"] = "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_others_year_>
# Stata line 1803
d["t_wage_others_year"] = np.nan
VARIABLE_LABELS["t_wage_others_year"] = "Annualized wage in all but primary and secondary jobs 12 month recall"

# ----------8.10: 12 month total summary------------------------------*

# <_t_hours_total_year_>
# Stata line 1812
d["t_hours_total_year"] = np.nan
VARIABLE_LABELS["t_hours_total_year"] = "Annualized hours worked in all jobs 12 month month recall"

# <_t_wage_nocompen_total_year_>
# Stata line 1818
d["t_wage_nocompen_total_year"] = np.nan
VARIABLE_LABELS["t_wage_nocompen_total_year"] = "Annualized wage in all jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_total_year_>
# Stata line 1824
d["t_wage_total_year"] = np.nan
VARIABLE_LABELS["t_wage_total_year"] = "Annualized total wage for all jobs 12 month recall"

# ----------8.11: Overall across reference periods------------------------------*

# <_njobs_>
# Stata line 1833
d["njobs"] = np.nan
# Stata line 1834
d.loc[d['s5c25'] == 2, "njobs"] = 1
# Stata line 1835
d.loc[(d['s5c25'] == 1) & (d['s5c36'] == 2), "njobs"] = 2
# Stata line 1836
d.loc[(d['s5c25'] == 1) & (d['s5c36'] == 1), "njobs"] = 3
# Stata line 1837
d.loc[d['lstatus'] != 1, "njobs"] = np.nan
VARIABLE_LABELS["njobs"] = "Total number of jobs"

# <_t_hours_annual_>
# Stata line 1843
d["t_hours_annual"] = np.nan
VARIABLE_LABELS["t_hours_annual"] = "Total hours worked in all jobs in the previous 12 months"

# <_linc_nc_>
# Stata line 1849
d["linc_nc"] = np.nan
VARIABLE_LABELS["linc_nc"] = "Total annual wage income in all jobs, excl. bonuses, etc."

# <_laborincome_>
# Stata line 1855
d["laborincome"] = d['t_wage_total_year']
VARIABLE_LABELS["laborincome"] = "Total annual individual labor income in all jobs, incl. bonuses, etc."

# ----------8.13: Labour cleanup------------------------------*

# <_% Correction min age_>
_age_mask = (d["age"] < d["minlaborage"]) & d["age"].notna()
for _name in ['minlaborage', 'lstatus', 'nlfreason', 'unempldur_l', 'unempldur_u', 'empstat', 'ocusec', 'industry_orig', 'industrycat_isic', 'industrycat10', 'industrycat4', 'occup_orig', 'occup_isco', 'occup_skill', 'occup', 'wage_no_compen', 'unitwage', 'whours', 'wmonths', 'wage_total', 'contract', 'healthins', 'socialsec', 'union', 'firmsize_l', 'firmsize_u', 'empstat_2', 'ocusec_2', 'industry_orig_2', 'industrycat_isic_2', 'industrycat10_2', 'industrycat4_2', 'occup_orig_2', 'occup_isco_2', 'occup_skill_2', 'occup_2', 'wage_no_compen_2', 'unitwage_2', 'whours_2', 'wmonths_2', 'wage_total_2', 'firmsize_l_2', 'firmsize_u_2', 't_hours_others', 't_wage_nocompen_others', 't_wage_others', 't_hours_total', 't_wage_nocompen_total', 't_wage_total', 'lstatus_year', 'nlfreason_year', 'unempldur_l_year', 'unempldur_u_year', 'empstat_year', 'ocusec_year', 'industry_orig_year', 'industrycat_isic_year', 'industrycat10_year', 'industrycat4_year', 'occup_orig_year', 'occup_isco_year', 'occup_skill_year', 'occup_year', 'unitwage_year', 'whours_year', 'wmonths_year', 'wage_total_year', 'contract_year', 'healthins_year', 'socialsec_year', 'union_year', 'firmsize_l_year', 'firmsize_u_year', 'empstat_2_year', 'ocusec_2_year', 'industry_orig_2_year', 'industrycat_isic_2_year', 'industrycat10_2_year', 'industrycat4_2_year', 'occup_orig_2_year', 'occup_isco_2_year', 'occup_skill_2_year', 'occup_2_year', 'wage_no_compen_2_year', 'unitwage_2_year', 'whours_2_year', 'wmonths_2_year', 'wage_total_2_year', 'firmsize_l_2_year', 'firmsize_u_2_year', 't_hours_others_year', 't_wage_nocompen_others_year', 't_wage_others_year', 't_hours_total_year', 't_wage_nocompen_total_year', 't_wage_total_year', 'njobs', 't_hours_annual', 'linc_nc', 'laborincome']:
    d.loc[_age_mask, _name] = "" if (d[_name].dtype == object or pd.api.types.is_string_dtype(d[_name].dtype)) else np.nan
del _age_mask, _name

# <_% KEEP VARIABLES - ALL_>
# Stata line 1891
d = d[['countrycode', 'survname', 'survey', 'icls_v', 'isced_version', 'isco_version', 'isic_version', 'year', 'vermast', 'veralt', 'harmonization', 'int_year', 'int_month', 'hhid', 'pid', 'weight', 'weight_m', 'weight_q', 'psu', 'ssu', 'strata', 'wave', 'panel', 'visit_no', 'urban', 'subnatid1', 'subnatid2', 'subnatid3', 'subnatidsurvey', 'subnatid1_prev', 'subnatid2_prev', 'subnatid3_prev', 'gaul_adm1_code', 'gaul_adm2_code', 'gaul_adm3_code', 'hsize', 'age', 'male', 'relationharm', 'relationcs', 'marital', 'eye_dsablty', 'hear_dsablty', 'walk_dsablty', 'conc_dsord', 'slfcre_dsablty', 'comm_dsablty', 'migrated_mod_age', 'migrated_ref_time', 'migrated_binary', 'migrated_years', 'migrated_from_urban', 'migrated_from_cat', 'migrated_from_code', 'migrated_from_country', 'migrated_reason', 'ed_mod_age', 'school', 'literacy', 'educy', 'educat7', 'educat5', 'educat4', 'educat_orig', 'educat_isced', 'vocational', 'vocational_type', 'vocational_length_l', 'vocational_length_u', 'vocational_field_orig', 'vocational_financed', 'minlaborage', 'lstatus', 'potential_lf', 'underemployment', 'nlfreason', 'unempldur_l', 'unempldur_u', 'empstat', 'ocusec', 'industry_orig', 'industrycat_isic', 'industrycat10', 'industrycat4', 'occup_orig', 'occup_isco', 'occup_skill', 'occup', 'wage_no_compen', 'unitwage', 'whours', 'wmonths', 'wage_total', 'contract', 'healthins', 'socialsec', 'union', 'firmsize_l', 'firmsize_u', 'empstat_2', 'ocusec_2', 'industry_orig_2', 'industrycat_isic_2', 'industrycat10_2', 'industrycat4_2', 'occup_orig_2', 'occup_isco_2', 'occup_skill_2', 'occup_2', 'wage_no_compen_2', 'unitwage_2', 'whours_2', 'wmonths_2', 'wage_total_2', 'firmsize_l_2', 'firmsize_u_2', 't_hours_others', 't_wage_nocompen_others', 't_wage_others', 't_hours_total', 't_wage_nocompen_total', 't_wage_total', 'lstatus_year', 'potential_lf_year', 'underemployment_year', 'nlfreason_year', 'unempldur_l_year', 'unempldur_u_year', 'empstat_year', 'ocusec_year', 'industry_orig_year', 'industrycat_isic_year', 'industrycat10_year', 'industrycat4_year', 'occup_orig_year', 'occup_isco_year', 'occup_skill_year', 'occup_year', 'wage_no_compen_year', 'unitwage_year', 'whours_year', 'wmonths_year', 'wage_total_year', 'contract_year', 'healthins_year', 'socialsec_year', 'union_year', 'firmsize_l_year', 'firmsize_u_year', 'empstat_2_year', 'ocusec_2_year', 'industry_orig_2_year', 'industrycat_isic_2_year', 'industrycat10_2_year', 'industrycat4_2_year', 'occup_orig_2_year', 'occup_isco_2_year', 'occup_skill_2_year', 'occup_2_year', 'wage_no_compen_2_year', 'unitwage_2_year', 'whours_2_year', 'wmonths_2_year', 'wage_total_2_year', 'firmsize_l_2_year', 'firmsize_u_2_year', 't_hours_others_year', 't_wage_nocompen_others_year', 't_wage_others_year', 't_hours_total_year', 't_wage_nocompen_total_year', 't_wage_total_year', 'njobs', 't_hours_annual', 'linc_nc', 'laborincome']]

# <_% ORDER VARIABLES_>
# Stata line 1897
d = d[['countrycode', 'survname', 'survey', 'icls_v', 'isced_version', 'isco_version', 'isic_version', 'year', 'vermast', 'veralt', 'harmonization', 'int_year', 'int_month', 'hhid', 'pid', 'weight', 'weight_m', 'weight_q', 'psu', 'ssu', 'strata', 'wave', 'panel', 'visit_no', 'urban', 'subnatid1', 'subnatid2', 'subnatid3', 'subnatidsurvey', 'subnatid1_prev', 'subnatid2_prev', 'subnatid3_prev', 'gaul_adm1_code', 'gaul_adm2_code', 'gaul_adm3_code', 'hsize', 'age', 'male', 'relationharm', 'relationcs', 'marital', 'eye_dsablty', 'hear_dsablty', 'walk_dsablty', 'conc_dsord', 'slfcre_dsablty', 'comm_dsablty', 'migrated_mod_age', 'migrated_ref_time', 'migrated_binary', 'migrated_years', 'migrated_from_urban', 'migrated_from_cat', 'migrated_from_code', 'migrated_from_country', 'migrated_reason', 'ed_mod_age', 'school', 'literacy', 'educy', 'educat7', 'educat5', 'educat4', 'educat_orig', 'educat_isced', 'vocational', 'vocational_type', 'vocational_length_l', 'vocational_length_u', 'vocational_field_orig', 'vocational_financed', 'minlaborage', 'lstatus', 'potential_lf', 'underemployment', 'nlfreason', 'unempldur_l', 'unempldur_u', 'empstat', 'ocusec', 'industry_orig', 'industrycat_isic', 'industrycat10', 'industrycat4', 'occup_orig', 'occup_isco', 'occup_skill', 'occup', 'wage_no_compen', 'unitwage', 'whours', 'wmonths', 'wage_total', 'contract', 'healthins', 'socialsec', 'union', 'firmsize_l', 'firmsize_u', 'empstat_2', 'ocusec_2', 'industry_orig_2', 'industrycat_isic_2', 'industrycat10_2', 'industrycat4_2', 'occup_orig_2', 'occup_isco_2', 'occup_skill_2', 'occup_2', 'wage_no_compen_2', 'unitwage_2', 'whours_2', 'wmonths_2', 'wage_total_2', 'firmsize_l_2', 'firmsize_u_2', 't_hours_others', 't_wage_nocompen_others', 't_wage_others', 't_hours_total', 't_wage_nocompen_total', 't_wage_total', 'lstatus_year', 'potential_lf_year', 'underemployment_year', 'nlfreason_year', 'unempldur_l_year', 'unempldur_u_year', 'empstat_year', 'ocusec_year', 'industry_orig_year', 'industrycat_isic_year', 'industrycat10_year', 'industrycat4_year', 'occup_orig_year', 'occup_isco_year', 'occup_skill_year', 'occup_year', 'wage_no_compen_year', 'unitwage_year', 'whours_year', 'wmonths_year', 'wage_total_year', 'contract_year', 'healthins_year', 'socialsec_year', 'union_year', 'firmsize_l_year', 'firmsize_u_year', 'empstat_2_year', 'ocusec_2_year', 'industry_orig_2_year', 'industrycat_isic_2_year', 'industrycat10_2_year', 'industrycat4_2_year', 'occup_orig_2_year', 'occup_isco_2_year', 'occup_skill_2_year', 'occup_2_year', 'wage_no_compen_2_year', 'unitwage_2_year', 'whours_2_year', 'wmonths_2_year', 'wage_total_2_year', 'firmsize_l_2_year', 'firmsize_u_2_year', 't_hours_others_year', 't_wage_nocompen_others_year', 't_wage_others_year', 't_hours_total_year', 't_wage_nocompen_total_year', 't_wage_total_year', 'njobs', 't_hours_annual', 'linc_nc', 'laborincome']]

# <_% DROP UNUSED LABELS_>

# <_% DELETE MISSING VARIABLES_>

# <_% COMPRESS_>

# <_% SAVE_>

# 9. Drop variables that are wholly missing, matching the Stata cleanup step.
d = d[[name for name in d.columns if not (d[name].isna() | (d[name].eq("") if d[name].dtype == object else False)).all()]]
# Store numeric values losslessly in a portable Stata 14+ file. File storage
# widths/label identifiers can differ, while values and label text are preserved.
for name in d:
    if d[name].dtype == object: d[name]=d[name].fillna('')
filename = path_output / OUT_FILE
pyreadstat.write_dta(d,str(filename),version=15,
    column_labels={k:v for k,v in VARIABLE_LABELS.items() if k in d},
    variable_value_labels={k:v for k,v in VALUE_LABELS.items() if k in d})
print(f'Saved {len(d):,} records and {len(d.columns)} variables: {filename.name}')
