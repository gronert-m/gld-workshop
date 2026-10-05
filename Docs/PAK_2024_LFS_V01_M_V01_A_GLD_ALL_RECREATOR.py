"""Native Python reproduction of the workshop PAK 2024 Stata Recreator.
Run: python PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.py [input_directory] [output_directory]
Requires numpy, pandas, pyreadstat. Download respondent microdata directly from PBS.
Inputs are read-only. Output has _RECREATED_PYTHON.dta suffix. No Stata installation
or reference output is needed. The section numbers and source-line comments follow
the do-file. Stata's missing comparisons, float rounding and existing coding quirks
are reproduced intentionally; this script does not revise substantive decisions.
"""
from pathlib import Path
import sys
import fnmatch
import operator
import warnings
import numpy as np
import pandas as pd
import pyreadstat

HERE = Path(__file__).resolve().parent
INPUT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else HERE
OUTPUT = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else INPUT
OUTPUT.mkdir(parents=True, exist_ok=True)
VARIABLE_LABELS, LABEL_DEFS, VALUE_LABELS, TYPES = {}, {}, {}, {}
warnings.filterwarnings('ignore', category=pd.errors.PerformanceWarning)

def read_dta(path):
    data, _ = pyreadstat.read_dta(str(path), apply_value_formats=False)
    return data

def smissing(x):
    if isinstance(x, str): return x == ''
    if isinstance(x, pd.Series) and (x.dtype == object or pd.api.types.is_string_dtype(x.dtype)):
        return x.isna() | x.eq('')
    return pd.isna(x)

def scmp(a, b, op):
    # Stata numeric missing is greater than every finite number, and . == . .
    def ordered(x):
        if isinstance(x, str): return x
        if isinstance(x, pd.Series) and (x.dtype == object or pd.api.types.is_string_dtype(x.dtype)):
            return x.fillna('')
        if np.isscalar(x): return np.inf if pd.isna(x) else x
        return x.fillna(np.inf) if isinstance(x, pd.Series) else np.where(pd.isna(x), np.inf, x)
    return {'==':operator.eq,'!=':operator.ne,'<':operator.lt,'>':operator.gt,
            '<=':operator.le,'>=':operator.ge}[op](ordered(a), ordered(b))

def sinrange(x, lo, hi):
    return (~smissing(x)) & scmp(x, lo, '>=') & scmp(x, hi, '<=')

def sinlist(x, *values):
    result = scmp(x, values[0], '==')
    for value in values[1:]: result = result | scmp(x, value, '==')
    return result

def sadd(a, b): return a + b

def scond(test, yes, no):
    return pd.Series(np.where(test, yes, no), index=d.index)

def sstring(x, fmt=None):
    values = pd.Series(x, index=d.index) if np.isscalar(x) else x
    if fmt:
        width=int(fmt[1:fmt.index('.')])
        return values.map(lambda v: '.' if pd.isna(v) else f'{v:0{width}.0f}')
    return values.map(lambda v: '.' if pd.isna(v) else format(float(v), '.9g'))

def ssubstr(x, start, length): return x.str.slice(start-1, start-1+length)

def rounded(x, typ):
    if typ == 'string': return pd.Series(x, index=d.index).fillna('').astype(str)
    values=pd.Series(x, index=d.index, dtype='float64')
    if typ in ('byte','int','long'):
        limits={'byte':(-127,100),'int':(-32767,32740),'long':(-2147483647,2147483620)}
        lo,hi=limits[typ]
        values=np.trunc(values)
        return values.where(values.between(lo,hi) | values.isna())
    if typ != 'double': return values.astype('float32').astype('float64')
    return values

def gen(name, values, typ='float', where=True):
    if name in d: raise ValueError('Already defined: '+name)
    if isinstance(values,str) or (isinstance(values,pd.Series) and values.dtype==object): typ='string'
    TYPES[name]=typ
    d[name]=rounded(values,typ)
    if not np.isscalar(where) or not where:
        d.loc[~pd.Series(where,index=d.index).astype(bool),name]='' if typ=='string' else np.nan

def replace(name, values, where=True):
    mask=pd.Series(where,index=d.index).astype(bool)
    values=rounded(values,TYPES.get(name,'string' if d[name].dtype==object else 'double'))
    d.loc[mask,name]=values.loc[mask]

def recode(name, rules):
    original=d[name].copy();done=pd.Series(False,index=d.index)
    for ranges,value in rules:
        selected=pd.Series(False,index=d.index)
        for lo,hi in ranges: selected=selected | sinrange(original,lo,hi)
        selected=selected & ~done
        replace(name,value,selected);done=done | selected

def drop_vars(patterns):
    global d
    names=[name for name in d for pattern in patterns if fnmatch.fnmatchcase(name,pattern)]
    d=d.drop(columns=list(dict.fromkeys(names)))
    for name in names:
        VARIABLE_LABELS.pop(name,None); VALUE_LABELS.pop(name,None); TYPES.pop(name,None)

def merge_lookup(key, lookup):
    global d
    other=lookup.copy()
    if other[key].duplicated().any():raise ValueError('Nonunique lookup key: '+key)
    # Stata keeps master values for overlapping non-key columns.
    other=other.drop(columns=[v for v in other if v in d and v!=key])
    d=d.merge(other,on=key,how='left',validate='many_to_one',indicator=True,sort=False)
    d['_merge']=d['_merge'].map({'left_only':1,'right_only':2,'both':3}).astype(float)

def labmask(name, text):
    valid=d.loc[~smissing(d[name]),[name,text]].drop_duplicates()
    if valid[name].duplicated().any():raise ValueError('Conflicting labels for '+name)
    VALUE_LABELS[name]={int(k):str(v) for k,v in valid.itertuples(index=False,name=None)}

def decode(name):
    return d[name].map(VALUE_LABELS.get(name,{})).fillna('')

def age_blank(names, threshold):
    mask=(d['age'] < d[threshold]) & ~smissing(d['age'])
    for name in names:
        replace(name,'' if TYPES[name]=='string' else np.nan,mask)

def universe_check(name, universe):
    table=pd.read_csv(HERE/'classification_universes'/f'{universe.lower()}_codes.csv',dtype=str,encoding='utf-8')
    table.columns=table.columns.str.lower()
    version='isic_4' if universe=='ISIC' else 'isco_2008'
    valid=set(table.loc[table.version.eq(version),'code'])
    bad=sorted(set(d.loc[~smissing(d[name]),name])-valid)
    if bad:raise ValueError(f'Invalid {universe} codes in {name}: {bad}')
    print(f'{name}: classification check passed')

# 1. Assemble inputs without overwriting the migration lookup or raw files.
d=read_dta(INPUT/'LFS 2024-25.sav web.dta')
d.columns=d.columns.str.lower()
migration=read_dta(INPUT/'append_lfs_districts.dta')
migration=migration.rename(columns={'LFS24_Distcodes':'city_code','LFS24_Distnames':'city_name'})
migration=migration.drop(columns=['samecode','sametext'])
migration.columns=migration.columns.str.lower()
country=read_dta(INPUT/'PAK_country_code_2020.dta')
training=read_dta(INPUT/'PAK_training_code.dta')

# Source SHA256: d568ed498594b5454c48da52240dade734c9df49a733a9b59e6dbc651ac4b4d9

# <_countrycode_>
# Stata line 104
gen("countrycode", "PAK", typ="string")
VARIABLE_LABELS["countrycode"] = "Country code"

# <_survname_>
# Stata line 110
gen("survname", "LFS", typ="float")
VARIABLE_LABELS["survname"] = "Survey acronym"

# <_survey_>
# Stata line 116
gen("survey", "LFS", typ="float")
VARIABLE_LABELS["survey"] = "Survey type"

# <_icls_v_>
# Stata line 122
gen("icls_v", "ICLS-19", typ="float")
VARIABLE_LABELS["icls_v"] = "ICLS version underlying questionnaire questions"

# <_isced_version_>
# Stata line 128
gen("isced_version", "isced_2011", typ="float")
VARIABLE_LABELS["isced_version"] = "Version of ISCED used for educat_isced"

# <_isco_version_>
# Stata line 134
gen("isco_version", "isco_2008", typ="float")
VARIABLE_LABELS["isco_version"] = "Version of ISCO used"

# <_isic_version_>
# Stata line 140
gen("isic_version", "isic_4", typ="float")
VARIABLE_LABELS["isic_version"] = "Version of ISIC used"

# <_year_>
# Stata line 146
gen("year", 2024, typ="int")
VARIABLE_LABELS["year"] = "Year of survey"

# <_vermast_>
# Stata line 152
gen("vermast", "", typ="float")
VARIABLE_LABELS["vermast"] = "Version of master data"

# <_veralt_>
# Stata line 158
gen("veralt", "", typ="float")
VARIABLE_LABELS["veralt"] = "Version of the alt/harmonized data"

# <_harmonization_>
# Stata line 164
gen("harmonization", "GLD", typ="float")
VARIABLE_LABELS["harmonization"] = "Type of harmonization"

# <_int_year_>
# Stata line 170
gen("int_year", np.nan, typ="float")
VARIABLE_LABELS["int_year"] = "Year of the interview"

# <_int_month_>
# Stata line 176
gen("int_month", np.nan, typ="float")
LABEL_DEFS["lblint_month"] = {1: 'January', 2: 'February', 3: 'March', 4: 'April', 5: 'May', 6: 'June', 7: 'July', 8: 'August', 9: 'September', 10: 'October', 11: 'November', 12: 'December'}
VALUE_LABELS["int_month"] = LABEL_DEFS["lblint_month"].copy()
VARIABLE_LABELS["int_month"] = "Month of the interview"

# <_hhid_>
# Stata line 192
d["hhno"] = sstring(d["hhno"], "%02.0f")
# Stata line 193
gen("hhid", (d["pcode"] if d["pcode"].dtype == object else sstring(d["pcode"])) + (d["hhno"] if d["hhno"].dtype == object else sstring(d["hhno"])), typ="string")
VARIABLE_LABELS["hhid"] = "Household ID"

# <_pid_>
# Stata line 199
gen("sno_str", d["sno"], typ="float")
# Stata line 200
d["sno_str"] = sstring(d["sno_str"], "%02.0f")
# Stata line 201
gen("pid", (d["hhid"] if d["hhid"].dtype == object else sstring(d["hhid"])) + (d["sno"] if d["sno"].dtype == object else sstring(d["sno"])), typ="string")
VARIABLE_LABELS["pid"] = "Individual ID"
assert not d["pid"].duplicated().any() and not smissing(d["pid"]).any()

# <_weight_>
# Stata line 208
gen("weight", d["weights"], typ="float")
VARIABLE_LABELS["weight"] = "Survey sampling weight"

# <_weight_m_>
# Stata line 215
gen("weight_m", np.nan, typ="float")
VARIABLE_LABELS["weight_m"] = "Survey sampling weight to obtain national estimates for each month"

# <_weight_q_>
# Stata line 221
gen("weight_q", np.nan, typ="float")
VARIABLE_LABELS["weight_q"] = "Survey sampling weight to obtain national estimates for each quarter"

# <_psu_>
# Stata line 227
gen("psu", d["pcode"], typ="float")
VARIABLE_LABELS["psu"] = "Primary sampling units"

# <_ssu_>
# Stata line 233
gen("ssu", d["hhid"], typ="float")
VARIABLE_LABELS["ssu"] = "Secondary sampling units"

# <_strata_>
# Stata line 239
gen("strata", ssubstr(d["pcode"], 1, 3), typ="float")
# Stata line 240
d["strata"] = pd.to_numeric(d["strata"], errors="raise")
VARIABLE_LABELS["strata"] = "Strata"

# <_wave_>
# Stata line 246
gen("wave", d["quarter"], typ="float")
VARIABLE_LABELS["wave"] = "Survey wave"

# <_panel_>
# Stata line 252
gen("panel", "", typ="float")
VARIABLE_LABELS["panel"] = "Panel individual belongs to"

# <_visit_no_>
# Stata line 258
gen("visit_no", np.nan, typ="float")
VARIABLE_LABELS["visit_no"] = "Visit number in panel"

# <_urban_>
# Stata line 272
gen("urban", d["region"], typ="byte")
# Stata line 273
recode("urban", [([(1, 1)], 0), ([(2, 2)], 1)])
VARIABLE_LABELS["urban"] = "Location is urban"
LABEL_DEFS["lblurban"] = {1: 'Urban', 0: 'Rural'}
VALUE_LABELS["urban"] = LABEL_DEFS["lblurban"].copy()

# <_subnatid1_>
# Stata line 288
gen("subnatid1", "", typ="float")
# Stata line 289
replace("subnatid1", "1 - Khyber/Pakhtoonkhua", where=scmp(d["province"], 1, "=="))
# Stata line 290
replace("subnatid1", "2 - Punjab", where=scmp(d["province"], 2, "=="))
# Stata line 291
replace("subnatid1", "3 - Sindh", where=scmp(d["province"], 3, "=="))
# Stata line 292
replace("subnatid1", "4 - Balochistan", where=scmp(d["province"], 4, "=="))
VARIABLE_LABELS["subnatid1"] = "Subnational ID at First Administrative Level"

# <_subnatid2_>
# Stata line 298
gen("subnatid2", "", typ="string")
VARIABLE_LABELS["subnatid2"] = "Subnational ID at Second Administrative Level"

# <_subnatid3_>
# Stata line 304
gen("subnatid3", "", typ="string")
VARIABLE_LABELS["subnatid3"] = "Subnational ID at Third Administrative Level"

# <_subnatidsurvey_>
# Stata line 317
gen("subnatidsurvey", "", typ="float")
# Stata line 318
replace("subnatidsurvey", sadd(d["subnatid1"], " - Urban"), where=scmp(d["urban"], 1, "=="))
# Stata line 319
replace("subnatidsurvey", sadd(d["subnatid1"], " - Rural"), where=scmp(d["urban"], 0, "=="))
VARIABLE_LABELS["subnatidsurvey"] = "Administrative level at which survey is representative"

# <_subnatid1_prev_>
# Stata line 330
gen("subnatid1_prev", np.nan, typ="float")
VARIABLE_LABELS["subnatid1_prev"] = "Classification used for subnatid1 from previous survey"

# <_subnatid2_prev_>
# Stata line 336
gen("subnatid2_prev", np.nan, typ="float")
VARIABLE_LABELS["subnatid2_prev"] = "Classification used for subnatid2 from previous survey"

# <_subnatid3_prev_>
# Stata line 342
gen("subnatid3_prev", np.nan, typ="float")
VARIABLE_LABELS["subnatid3_prev"] = "Classification used for subnatid3 from previous survey"

# <_gaul_adm1_code_>
# Stata line 348
gen("gaul_adm1_code", np.nan, typ="float")
VARIABLE_LABELS["gaul_adm1_code"] = "Global Administrative Unit Layers (GAUL) Admin 1 code"

# <_gaul_adm2_code_>
# Stata line 354
gen("gaul_adm2_code", np.nan, typ="float")
VARIABLE_LABELS["gaul_adm2_code"] = "Global Administrative Unit Layers (GAUL) Admin 2 code"

# <_gaul_adm3_code_>
# Stata line 360
gen("gaul_adm3_code", np.nan, typ="float")
VARIABLE_LABELS["gaul_adm3_code"] = "Global Administrative Unit Layers (GAUL) Admin 3 code"

# <_hsize_>
# Stata line 374
gen("member_count", 1, typ="float", where=scmp(d["s4c3"], 8, "<"))
# Stata line 375
replace("member_count", 0, where=smissing(d["member_count"]))
# Stata line 376
gen("hsize", d["member_count"].groupby(d["hhid"]).transform("sum"), typ="byte")

# <_age_>
# Stata line 394
gen("age", d["s4c6"], typ="float")
VARIABLE_LABELS["age"] = "Individual age"

# <_male_>
# Stata line 400
gen("male", d["s4c5"], typ="float")
# Stata line 401
recode("male", [([(2, 2)], 0)])
VARIABLE_LABELS["male"] = "Sex - Ind is male"
LABEL_DEFS["lblmale"] = {1: 'Male', 0: 'Female'}
VALUE_LABELS["male"] = LABEL_DEFS["lblmale"].copy()

# <_relationharm_>
# Stata line 409
gen("relationharm", d["s4c3"], typ="float")
# Stata line 410
recode("relationharm", [([(4, 4)], 3), ([(5, 5)], 4), ([(6, 6), (7, 7)], 5), ([(8, 8), (9, 9)], 6)])
VARIABLE_LABELS["relationharm"] = "Relationship to the head of household - Harmonized"
LABEL_DEFS["lblrelationharm"] = {1: 'Head of household', 2: 'Spouse', 3: 'Children', 4: 'Parents', 5: 'Other relatives', 6: 'Other and non-relatives'}
VALUE_LABELS["relationharm"] = LABEL_DEFS["lblrelationharm"].copy()
# Stata line 415
gen("lowest_rel", d["s4c3"].groupby(d["hhid"]).transform("min"), typ="float")
# Stata line 416
gen("tot_heads", scmp(d["s4c3"], 1, "==").groupby(d["hhid"]).transform("sum"), typ="float")
assert bool(np.all(scmp(d["lowest_rel"], 1, "=="))), "Source assertion failed at line 417"
assert bool(np.all(scmp(d["tot_heads"], 1, "=="))), "Source assertion failed at line 418"

# <_relationcs_>
# Stata line 423
gen("relationcs", d["s4c3"], typ="float")
VARIABLE_LABELS["relationcs"] = "Relationship to the head of household - Country original"

# <_marital_>
# Stata line 429
gen("marital", d["s4c7"], typ="byte")
# Stata line 430
recode("marital", [([(2, 2)], 1), ([(1, 1)], 2), ([(3, 3)], 5)])
VARIABLE_LABELS["marital"] = "Marital status"
LABEL_DEFS["lblmarital"] = {1: 'Married', 2: 'Never Married', 3: 'Living together', 4: 'Divorced/Separated', 5: 'Widowed'}
VALUE_LABELS["marital"] = LABEL_DEFS["lblmarital"].copy()

# <_eye_dsablty_>
# Stata line 438
gen("eye_dsablty", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["eye_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["eye_dsablty"] = "Disability related to eyesight"

# <_hear_dsablty_>
# Stata line 446
gen("hear_dsablty", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["hear_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["hear_dsablty"] = "Disability related to hearing"

# <_walk_dsablty_>
# Stata line 454
gen("walk_dsablty", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["walk_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["walk_dsablty"] = "Disability related to walking or climbing stairs"

# <_conc_dsord_>
# Stata line 462
gen("conc_dsord", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["conc_dsord"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["conc_dsord"] = "Disability related to concentration or remembering"

# <_slfcre_dsablty_>
# Stata line 470
gen("slfcre_dsablty", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["slfcre_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["slfcre_dsablty"] = "Disability related to selfcare"

# <_comm_dsablty_>
# Stata line 478
gen("comm_dsablty", np.nan, typ="float")
LABEL_DEFS["dsablty"] = {1: 'No – no difficulty', 2: 'Yes – some difficulty', 3: 'Yes – a lot of difficulty', 4: 'Cannot do at all'}
VALUE_LABELS["comm_dsablty"] = LABEL_DEFS["dsablty"].copy()
VARIABLE_LABELS["comm_dsablty"] = "Disability related to communicating"

# <_migrated_mod_age_>
# Stata line 495
gen("migrated_mod_age", 10, typ="float")
VARIABLE_LABELS["migrated_mod_age"] = "Migration module application age"

# <_migrated_ref_time_>
# Stata line 501
gen("migrated_ref_time", 99, typ="float")
VARIABLE_LABELS["migrated_ref_time"] = "Reference time applied to migration questions (in years)"

# <_migrated_binary_>
# Stata line 507
gen("migrated_binary", scond(scmp(d["s4c15"], 1, "=="), 0, 1), typ="float")
LABEL_DEFS["lblmigrated_binary"] = {0: 'No', 1: 'Yes'}
# Stata line 509
replace("migrated_binary", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
VALUE_LABELS["migrated_binary"] = LABEL_DEFS["lblmigrated_binary"].copy()
VARIABLE_LABELS["migrated_binary"] = "Individual has migrated"

# <_migrated_years_>
# Stata line 528
gen("migrated_years", np.nan, typ="float")
# Stata line 529
replace("migrated_years", 0.5, where=scmp(d["s4c15"], 2, "=="))
# Stata line 530
replace("migrated_years", (d["s4c15"] - 2), where=sinrange(d["s4c15"], 3, 6))
# Stata line 531
replace("migrated_years", 7.5, where=scmp(d["s4c15"], 7, "=="))
# Stata line 532
replace("migrated_years", 11, where=scmp(d["s4c15"], 8, "=="))
# Stata line 533
replace("migrated_years", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
# Stata line 534
replace("migrated_years", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
VARIABLE_LABELS["migrated_years"] = "Years since latest migration"

# <_migrated_from_urban_>
# Stata line 540
gen("migrated_from_urban", d["s4c17"], typ="float")
# Stata line 541
recode("migrated_from_urban", [([(0, 0)], np.nan), ([(1, 1)], 0), ([(2, 2)], 1)])
# Stata line 542
replace("migrated_from_urban", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
# Stata line 543
replace("migrated_from_urban", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
LABEL_DEFS["lblmigrated_from_urban"] = {0: 'Rural', 1: 'Urban'}
VALUE_LABELS["migrated_from_urban"] = LABEL_DEFS["lblmigrated_from_urban"].copy()
VARIABLE_LABELS["migrated_from_urban"] = "Migrated from area"

# <_migrated_from_cat_>
# Stata line 557
gen("helper_mfc_1", sstring(np.floor((d["s4c16"] / 100))), typ="float", where=scmp(d["s4c16"], 1000, "<"))
# Stata line 558
gen("helper_mfc_2", ssubstr(d["pcode"], 1, 1), typ="float")
# Stata line 560
gen("migrated_from_cat", np.nan, typ="float")
# Stata line 562
replace("migrated_from_cat", 3, where=scmp(d["helper_mfc_1"], d["helper_mfc_2"], "=="))
# Stata line 563
replace("migrated_from_cat", 4, where=((scmp(d["helper_mfc_1"], d["helper_mfc_2"], "!=") & scmp(d["migrated_binary"], 1, "==")) & scmp(d["s4c16"], 1000, "<")))
# Stata line 564
replace("migrated_from_cat", 5, where=(scmp(d["s4c16"], 999, ">") & (~smissing(d["s4c16"]))))
# Stata line 566
replace("migrated_from_cat", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
# Stata line 567
replace("migrated_from_cat", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
LABEL_DEFS["lblmigrated_from_cat"] = {1: 'From same admin3 area', 2: 'From same admin2 area', 3: 'From same admin1 area', 4: 'From other admin1 area', 5: 'From other country'}
VALUE_LABELS["migrated_from_cat"] = LABEL_DEFS["lblmigrated_from_cat"].copy()
VARIABLE_LABELS["migrated_from_cat"] = "Category of migration area"
drop_vars(['helper_mfc_*'])

# <_migrated_from_code_>
# Stata line 576
gen("city_code", d["s4c16"], typ="float")
# Stata line 577
merge_lookup("city_code", migration)
# Stata line 578
replace("city_code", np.nan, where=scmp(d["_merge"], 1, "=="))
d = d.loc[~(scmp(d["_merge"], 2, "=="))].reset_index(drop=True)
# Stata line 580
gen("migrated_from_code", d["mapped_lfscode_24"], typ="float", where=scmp(d["migrated_binary"], 1, "=="))
# Stata line 581
replace("migrated_from_code", np.nan, where=scmp(d["mapped_lfscode_24"], 999, ">"))
# Stata line 582
replace("migrated_from_code", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
# Stata line 583
replace("migrated_from_code", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
drop_vars(['_merge'])
VARIABLE_LABELS["migrated_from_code"] = "Code of migration area as subnatid level of migrated_from_cat"

# <_migrated_from_country_>
# Stata line 590
merge_lookup("city_code", country)
d = d.loc[~(scmp(d["_merge"], 2, "=="))].reset_index(drop=True)
drop_vars(['_merge'])
# Stata line 593
gen("migrated_from_country", d["city_code"], typ="float", where=(scmp(d["country"], 1, "==") & scmp(d["migrated_binary"], 1, "==")))
# Stata line 594
gen("country_name", d["iso_code"], typ="float", where=(scmp(d["country"], 1, "==") & scmp(d["migrated_binary"], 1, "==")))
# Stata line 595
labmask("migrated_from_country", "country_name")
# Stata line 596
replace("migrated_from_country", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
# Stata line 597
replace("migrated_from_country", np.nan, where=scmp(d["age"], d["migrated_mod_age"], "<"))
VARIABLE_LABELS["migrated_from_country"] = "Code of migration country (ISO 3 Letter Code)"

# <_migrated_reason_>
# Stata line 603
gen("migrated_reason", d["s4c18"], typ="float")
# Stata line 604
recode("migrated_reason", [([(1, 4), (6, 6)], 3), ([(5, 5)], 2), ([(8, 11)], 1), ([(14, 16)], 4), ([(7, 7), (12, 13), (17, 17)], 5)])
# Stata line 605
replace("migrated_reason", np.nan, where=scmp(d["migrated_binary"], 1, "!="))
LABEL_DEFS["lblmigrated_reason"] = {1: 'Family reasons', 2: 'Educational reasons', 3: 'Employment', 4: 'Forced (political reasons, natural disaster, …)', 5: 'Other reasons'}
VALUE_LABELS["migrated_reason"] = LABEL_DEFS["lblmigrated_reason"].copy()
VARIABLE_LABELS["migrated_reason"] = "Reason for migrating"

# <_ed_mod_age_>
# Stata line 629
gen("ed_mod_age", 5, typ="byte")
VARIABLE_LABELS["ed_mod_age"] = "Education module application age"

# <_school_>
# Stata line 635
gen("school", np.nan, typ="byte")
# Stata line 636
replace("school", 0, where=scmp(d["s4c10"], 3, "<="))
# Stata line 637
replace("school", 1, where=(scmp(d["s4c10"], 3, ">") & scmp(d["s4c10"], np.nan, "!=")))
VARIABLE_LABELS["school"] = "Attending school"
LABEL_DEFS["lblschool"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["school"] = LABEL_DEFS["lblschool"].copy()

# <_literacy_>
# Stata line 645
gen("literacy", np.nan, typ="byte")
# Stata line 646
replace("literacy", 1, where=(scmp(d["s4c81"], 1, "==") & scmp(d["s4c82"], 1, "==")))
# Stata line 647
replace("literacy", 0, where=((scmp(d["literacy"], 1, "!=") & (~smissing(d["s4c81"]))) & (~smissing(d["s4c82"]))))
VARIABLE_LABELS["literacy"] = "Individual can read & write"
LABEL_DEFS["lblliteracy"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["literacy"] = LABEL_DEFS["lblliteracy"].copy()

# <_educy_>
# Stata line 655
gen("educy", np.nan, typ="byte")
# Stata line 657
replace("educy", 0, where=scmp(d["s4c9"], 3, "<="))
# Stata line 658
replace("educy", 5, where=scmp(d["s4c9"], 4, "=="))
# Stata line 659
replace("educy", 8, where=scmp(d["s4c9"], 5, "=="))
# Stata line 660
replace("educy", 10, where=scmp(d["s4c9"], 6, "=="))
# Stata line 661
replace("educy", 12, where=scmp(d["s4c9"], 7, "=="))
# Stata line 662
replace("educy", 16, where=scmp(d["s4c9"], 8, "=="))
# Stata line 663
replace("educy", 17, where=scmp(d["s4c9"], 9, "=="))
# Stata line 664
replace("educy", 16, where=scmp(d["s4c9"], 10, "=="))
# Stata line 665
replace("educy", 16, where=scmp(d["s4c9"], 11, "=="))
# Stata line 666
replace("educy", 16, where=scmp(d["s4c9"], 12, "=="))
# Stata line 667
replace("educy", 19, where=scmp(d["s4c9"], 13, "=="))
# Stata line 668
replace("educy", 20, where=scmp(d["s4c9"], 14, "=="))
# Stata line 669
replace("educy", 22, where=scmp(d["s4c9"], 15, "=="))
VARIABLE_LABELS["educy"] = "Years of education"

# <_educat7_>
# Stata line 675
gen("educat7", d["s4c9"], typ="byte")
# Stata line 676
recode("educat7", [([(3, 3)], 2), ([(4, 4)], 3), ([(5, 6)], 4), ([(8, 16)], 7)])
# Stata line 677
replace("educat7", 5, where=(scmp(d["s4c9"], 7, "==") & scmp(d["s4c10"], 1, "==")))
# Stata line 678
replace("educat7", 7, where=(scmp(d["s4c9"], 7, "==") & sinrange(d["s4c10"], 8, 15)))
# Stata line 679
replace("educat7", np.nan, where=scmp(d["age"], d["ed_mod_age"], "<"))
VARIABLE_LABELS["educat7"] = "Level of education 1"
LABEL_DEFS["lbleducat7"] = {1: 'No education', 2: 'Primary incomplete', 3: 'Primary complete', 4: 'Secondary incomplete', 5: 'Secondary complete', 6: 'Higher than secondary but not university', 7: 'University incomplete or complete'}
VALUE_LABELS["educat7"] = LABEL_DEFS["lbleducat7"].copy()

# <_educat5_>
# Stata line 687
gen("educat5", d["educat7"], typ="byte")
# Stata line 688
recode("educat5", [([(4, 4)], 3), ([(5, 5)], 4), ([(6, 6), (7, 7)], 5)])
VARIABLE_LABELS["educat5"] = "Level of education 2"
LABEL_DEFS["lbleducat5"] = {1: 'No education', 2: 'Primary incomplete', 3: 'Primary complete but secondary incomplete', 4: 'Secondary complete', 5: 'Some tertiary/post-secondary'}
VALUE_LABELS["educat5"] = LABEL_DEFS["lbleducat5"].copy()

# <_educat4_>
# Stata line 696
gen("educat4", d["educat7"], typ="byte")
# Stata line 697
recode("educat4", [([(2, 2), (3, 3), (4, 4)], 2), ([(5, 5)], 3), ([(6, 6), (7, 7)], 4)])
VARIABLE_LABELS["educat4"] = "Level of education 3"
LABEL_DEFS["lbleducat4"] = {1: 'No education', 2: 'Primary', 3: 'Secondary', 4: 'Post-secondary'}
VALUE_LABELS["educat4"] = LABEL_DEFS["lbleducat4"].copy()

# <_educat_orig_>
# Stata line 705
gen("educat_orig", d["s4c9"], typ="float")
VARIABLE_LABELS["educat_orig"] = "Original survey education code"

# <_educat_isced_>
# Stata line 711
gen("educat_isced", d["s4c9"], typ="float")
# Stata line 712
replace("educat_isced", np.nan, where=(~sinrange(d["s4c9"], 1, 16)))
# Stata line 713
recode("educat_isced", [([(1, 1)], np.nan), ([(2, 3)], 20), ([(3, 3)], 100), ([(4, 6)], 244), ([(7, 7)], 344), ([(8, 12)], 660), ([(13, 14)], 760), ([(1516, 1516)], 860)])
# Stata line 714
replace("educat_isced", np.nan, where=scmp(d["age"], d["ed_mod_age"], "<"))
VARIABLE_LABELS["educat_isced"] = "ISCED standardised level of education"

# ----------6.1: Education cleanup------------------------------*

# <_% Correction min age_>
age_blank(['school', 'literacy', 'educy', 'educat7', 'educat5', 'educat4', 'educat_orig', 'educat_isced'], "ed_mod_age")

# <_vocational_>
# Stata line 751
gen("vocational", d["s4c11"], typ="float")
# Stata line 752
recode("vocational", [([(1, 3)], 1), ([(4, 4)], 0)])
# Stata line 753
replace("vocational", np.nan, where=(~sinrange(d["vocational"], 0, 1)))
LABEL_DEFS["lblvocational"] = {0: 'No', 1: 'Yes'}
# Source attaches undefined value label vocationallbl to vocational; no labels exported.
VARIABLE_LABELS["vocational"] = "Ever received vocational training"

# <_vocational_type_>
# Stata line 761
gen("vocational_type", d["s4c11"], typ="float")
# Stata line 762
recode("vocational_type", [([(1, 1)], 1), ([(2, 2)], 2)])
# Stata line 763
replace("vocational_type", np.nan, where=(~sinrange(d["vocational_type"], 1, 2)))
LABEL_DEFS["lblvocational_type"] = {1: 'Inside Enterprise', 2: 'External'}
VALUE_LABELS["vocational_type"] = LABEL_DEFS["lblvocational_type"].copy()
VARIABLE_LABELS["vocational_type"] = "Type of vocational training"

# <_vocational_length_l_>
# Stata line 778
gen("vocational_length_l", d["s4c13"], typ="float")
# Stata line 779
replace("vocational_length_l", (d["vocational_length_l"] / 4.2))
VARIABLE_LABELS["vocational_length_l"] = "Length of training in months, lower limit"

# <_vocational_length_u_>
# Stata line 785
gen("vocational_length_u", d["s4c13"], typ="float")
# Stata line 786
replace("vocational_length_u", (d["vocational_length_u"] / 4.2))
VARIABLE_LABELS["vocational_length_u"] = "Length of training in months, upper limit"

# <_vocational_field_orig_>
# Stata line 792
gen("code", d["s4c12"], typ="float")
# Stata line 793
merge_lookup("code", training)
d = d.loc[~(scmp(d["_merge"], 2, "=="))].reset_index(drop=True)
# Stata line 795
gen("vocational_field_orig", d["code"], typ="float")
# Stata line 796
labmask("vocational_field_orig", "training_field")
# Stata line 797
gen("vocational_field_str", decode("vocational_field_orig"), typ="string")
# Stata line 798
replace("vocational_field_str", sadd(sadd(sstring(d["code"]), " - "), d["vocational_field_str"]))
drop_vars(['vocational_field_orig', 'code', '_merge'])
d = d.rename(columns={"vocational_field_str": "vocational_field_orig"}); TYPES["vocational_field_orig"] = TYPES.pop("vocational_field_str")
# Stata line 801
replace("vocational_field_orig", "", where=scmp(d["vocational_field_orig"], ". - ", "=="))
VARIABLE_LABELS["vocational_field_orig"] = "Original field of training"

# <_vocational_financed_>
# Stata line 806
gen("vocational_financed", np.nan, typ="float")
LABEL_DEFS["lblvocational_financed"] = {1: 'Employer', 2: 'Government', 3: 'Mixed Employer/Government', 4: 'Own funds', 5: 'Other'}
VARIABLE_LABELS["vocational_financed"] = "How training was financed"

# <_minlaborage_>
# Stata line 821
gen("minlaborage", 10, typ="byte")
VARIABLE_LABELS["minlaborage"] = "Labor module application age"

# ----------8.1: 7 day reference overall------------------------------*

# <_lstatus_>
# Stata line 830
gen("lstatus", np.nan, typ="byte")
# Stata line 834
replace("lstatus", 1, where=scmp(d["s5c1"], 1, "=="))
# Stata line 839
replace("lstatus", 1, where=((scmp(d["s5c4"], 1, "==") & (scmp(d["s5c6"], 1, "==") | scmp(d["s5c7"], 1, "=="))) & smissing(d["lstatus"])))
# Stata line 842
replace("lstatus", 1, where=(scmp(d["s5c9"], 4, "==") & smissing(d["lstatus"])))
# Stata line 845
replace("lstatus", 1, where=((sinrange(d["s5c9"], 1, 3) & sinrange(d["s5c10"], 1, 2)) & smissing(d["lstatus"])))
# Stata line 848
replace("lstatus", 1, where=((((((scmp(d["s5c1"], 2, "==") & scmp(d["s5c2"], 2, "==")) & scmp(d["s5c3"], 2, "==")) & scmp(d["s5c4"], 2, "==")) & sinrange(d["s5c8"], 1, 3)) & sinrange(d["s5c10"], 1, 2)) & smissing(d["lstatus"])))
# Stata line 853
replace("lstatus", 2, where=((scmp(d["s9c1"], 1, "==") & scmp(d["s9c6"], 1, "==")) & smissing(d["lstatus"])))
# Stata line 861
replace("lstatus", 3, where=(smissing(d["lstatus"]) & scmp(d["age"], d["minlaborage"], ">=")))
# Stata line 864
replace("lstatus", np.nan, where=scmp(d["age"], d["minlaborage"], "<"))
VARIABLE_LABELS["lstatus"] = "Labor status 7 day recall"
LABEL_DEFS["lbllstatus"] = {1: 'Employed', 2: 'Unemployed', 3: 'Not in labor force'}
VALUE_LABELS["lstatus"] = LABEL_DEFS["lbllstatus"].copy()

# <_potential_lf_>
# Stata line 884
gen("potential_lf", np.nan, typ="byte")
# Stata line 885
replace("potential_lf", 0, where=scmp(d["lstatus"], 3, "=="))
# Stata line 886
replace("potential_lf", 1, where=((scmp(d["s9c1"], 2, "==") & scmp(d["s9c6"], 1, "==")) | (scmp(d["s9c1"], 1, "==") & scmp(d["s9c6"], 2, "=="))))
# Stata line 887
replace("potential_lf", np.nan, where=(scmp(d["age"], d["minlaborage"], "<") & (~smissing(d["age"]))))
# Stata line 888
replace("potential_lf", np.nan, where=scmp(d["lstatus"], 3, "!="))
VARIABLE_LABELS["potential_lf"] = "Potential labour force status"
LABEL_DEFS["lblpotential_lf"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["potential_lf"] = LABEL_DEFS["lblpotential_lf"].copy()

# <_underemployment_>
# Stata line 896
gen("underemployment", np.nan, typ="byte")
# Stata line 897
replace("underemployment", 1, where=scmp(d["s6c2"], 1, "=="))
# Stata line 898
replace("underemployment", 0, where=scmp(d["s6c2"], 2, "=="))
# Stata line 899
replace("underemployment", np.nan, where=scmp(d["age"], d["minlaborage"], "<"))
# Stata line 900
replace("underemployment", np.nan, where=(scmp(d["age"], d["minlaborage"], "<") & (~smissing(d["age"]))))
# Stata line 901
replace("underemployment", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["underemployment"] = "Underemployment status"
LABEL_DEFS["lblunderemployment"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["underemployment"] = LABEL_DEFS["lblunderemployment"].copy()

# <_nlfreason_>
# Stata line 909
gen("nlfreason", np.nan, typ="byte")
# Stata line 910
gen("nlfreason_1", d["s9c9"], typ="float", where=scmp(d["lstatus"], 3, "=="))
# Stata line 911
recode("nlfreason_1", [([(7, 7)], 1), ([(9, 9)], 2), ([(10, 11)], 3), ([(1, 6), (12, 13)], 5), ([(8, 8)], 4)])
# Stata line 912
gen("nlfreason_2", d["s9c5"], typ="float", where=scmp(d["lstatus"], 3, "=="))
# Stata line 913
recode("nlfreason_2", [([(9, 9)], 1), ([(10, 10)], 2), ([(12, 12)], 4), ([(1, 8), (11, 11), (13, 14)], 5)])
# Stata line 914
replace("nlfreason", d["nlfreason_1"])
# Stata line 915
replace("nlfreason", d["nlfreason_2"], where=smissing(d["nlfreason"]))
# Stata line 916
replace("nlfreason", np.nan, where=scmp(d["lstatus"], 3, "!="))
# Stata line 917
replace("nlfreason", 5, where=(scmp(d["lstatus"], 3, "==") & scmp(d["nlfreason"], np.nan, "==")))
VARIABLE_LABELS["nlfreason"] = "Reason not in the labor force"
LABEL_DEFS["lblnlfreason"] = {1: 'Student', 2: 'Housekeeper', 3: 'Retired', 4: 'Disabled', 5: 'Other'}
VALUE_LABELS["nlfreason"] = LABEL_DEFS["lblnlfreason"].copy()

# <_unempldur_l_>
# Stata line 925
gen("unempldur_l", np.nan, typ="byte")
# Stata line 926
replace("unempldur_l", d["s9c3"], where=scmp(d["lstatus"], 2, "=="))
# Stata line 927
recode("unempldur_l", [([(1, 1)], 0), ([(2, 2)], 1), ([(3, 3)], 3), ([(4, 4)], 6), ([(5, 5)], 12)])
# Stata line 928
replace("unempldur_l", np.nan, where=scmp(d["lstatus"], 1, "=="))
VARIABLE_LABELS["unempldur_l"] = "Unemployment duration (months) lower bracket"

# <_unempldur_u_>
# Stata line 934
gen("unempldur_u", np.nan, typ="byte")
# Stata line 935
replace("unempldur_u", d["s9c3"], where=scmp(d["lstatus"], 2, "=="))
# Stata line 936
recode("unempldur_u", [([(1, 1)], 0), ([(2, 2)], 3), ([(3, 3)], 6), ([(4, 4)], 12), ([(5, 5)], np.nan)])
# Stata line 937
replace("unempldur_u", np.nan, where=scmp(d["lstatus"], 1, "=="))
VARIABLE_LABELS["unempldur_u"] = "Unemployment duration (months) upper bracket"

# ----------8.2: 7 day reference main job------------------------------*

# <_empstat_>
# Stata line 948
gen("empstat", d["s5c11"], typ="byte")
# Stata line 949
recode("empstat", [([(3, 3), (5, 5)], 1), ([(4, 4)], 2), ([(1, 1)], 3), ([(2, 2)], 4), ([(6, 6)], 5)])
# Stata line 950
replace("empstat", np.nan, where=(~sinrange(d["s5c11"], 1, 6)))
# Stata line 951
replace("empstat", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["empstat"] = "Employment status during past week primary job 7 day recall"
LABEL_DEFS["lblempstat"] = {1: 'Paid employee', 2: 'Non-paid employee', 3: 'Employer', 4: 'Self-employed', 5: 'Other, workers not classifiable by status'}
VALUE_LABELS["empstat"] = LABEL_DEFS["lblempstat"].copy()

# <_ocusec_>
# Stata line 959
gen("ocusec", d["s5c15"], typ="byte")
# Stata line 960
recode("ocusec", [([(1, 3)], 1), ([(4, 4)], 3), ([(5, 10)], 2), ([(11, 11)], 4)])
# Stata line 961
replace("ocusec", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["ocusec"] = "Sector of activity primary job 7 day recall"
LABEL_DEFS["lblocusec"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec"] = LABEL_DEFS["lblocusec"].copy()

# <_industry_orig_>
# Stata line 969
gen("industry_orig", sstring(d["s5c13"], "%04.0f"), typ="float")
# Stata line 970
replace("industry_orig", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 971
replace("industry_orig", "", where=scmp(d["industry_orig"], ".", "=="))
VARIABLE_LABELS["industry_orig"] = "Original survey industry code, main job 7 day recall"

# <_industrycat_isic_>
# Stata line 977
gen("industrycat_isic", d["industry_orig"], typ="float")
# Stata line 978
replace("industrycat_isic", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 979
replace("industrycat_isic", "", where=scmp(d["industrycat_isic"], ".", "=="))
universe_check("industrycat_isic", "ISIC")
VARIABLE_LABELS["industrycat_isic"] = "ISIC code of primary job 7 day recall"

# <_industrycat10_>
# Stata line 996
gen("industrycat10", np.nan, typ="byte")
# Stata line 997
replace("industrycat10", 1, where=sinrange(d["industrycat_isic"], "0100", "0399"))
# Stata line 998
replace("industrycat10", 2, where=sinrange(d["industrycat_isic"], "0500", "0999"))
# Stata line 999
replace("industrycat10", 3, where=sinrange(d["industrycat_isic"], "1000", "3399"))
# Stata line 1000
replace("industrycat10", 4, where=sinrange(d["industrycat_isic"], "3500", "3900"))
# Stata line 1001
replace("industrycat10", 5, where=sinrange(d["industrycat_isic"], "4100", "4399"))
# Stata line 1002
replace("industrycat10", 6, where=(sinrange(d["industrycat_isic"], "4500", "4799") | sinrange(d["industrycat_isic"], "5500", "5699")))
# Stata line 1003
replace("industrycat10", 7, where=(sinrange(d["industrycat_isic"], "4900", "5399") | sinrange(d["industrycat_isic"], "5800", "6399")))
# Stata line 1004
replace("industrycat10", 8, where=sinrange(d["industrycat_isic"], "6400", "8299"))
# Stata line 1005
replace("industrycat10", 9, where=sinrange(d["industrycat_isic"], "8400", "8499"))
# Stata line 1006
replace("industrycat10", 10, where=sinrange(d["industrycat_isic"], "8500", "9900"))
VARIABLE_LABELS["industrycat10"] = "1 digit industry classification, primary job 7 day recall"
LABEL_DEFS["lblindustrycat10"] = {1: 'Agriculture', 2: 'Mining', 3: 'Manufacturing', 4: 'Public utilities', 5: 'Construction', 6: 'Commerce', 7: 'Transport and Comnunications', 8: 'Financial and Business Services', 9: 'Public Administration', 10: 'Other Services, Unspecified'}
VALUE_LABELS["industrycat10"] = LABEL_DEFS["lblindustrycat10"].copy()

# <_industrycat4_>
# Stata line 1015
gen("industrycat4", d["industrycat10"], typ="byte")
# Stata line 1016
recode("industrycat4", [([(1, 1)], 1), ([(2, 2), (3, 3), (4, 4), (5, 5)], 2), ([(6, 6), (7, 7), (8, 8), (9, 9)], 3), ([(10, 10)], 4)])
VARIABLE_LABELS["industrycat4"] = "Broad Economic Activities classification, primary job 7 day recall"
LABEL_DEFS["lblindustrycat4"] = {1: 'Agriculture', 2: 'Industry', 3: 'Services', 4: 'Other'}
VALUE_LABELS["industrycat4"] = LABEL_DEFS["lblindustrycat4"].copy()

# <_occup_orig_>
# Stata line 1024
gen("occup_orig", sstring(d["s5c12"], "%04.0f"), typ="float")
# Stata line 1025
replace("occup_orig", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1026
replace("occup_orig", "", where=scmp(d["industry_orig"], ".", "=="))
VARIABLE_LABELS["occup_orig"] = "Original occupation record primary job 7 day recall"

# <_occup_isco_>
# Stata line 1032
gen("occup_isco", d["occup_orig"], typ="float")
# Stata line 1033
replace("occup_isco", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1034
replace("occup_isco", "", where=scmp(d["occup_isco"], ".", "=="))
# Stata line 1037
replace("occup_isco", "4100", where=scmp(d["occup_isco"], "4140", "=="))
universe_check("occup_isco", "ISCO")
VARIABLE_LABELS["occup_isco"] = "ISCO code of primary job 7 day recall"

# <_occup_>
# Stata line 1053
gen("occup", np.nan, typ="byte")
# Stata line 1054
replace("occup", 1, where=sinrange(d["occup_isco"], "1000", "1999"))
# Stata line 1055
replace("occup", 2, where=sinrange(d["occup_isco"], "2000", "2999"))
# Stata line 1056
replace("occup", 3, where=sinrange(d["occup_isco"], "3000", "3999"))
# Stata line 1057
replace("occup", 4, where=sinrange(d["occup_isco"], "4000", "4999"))
# Stata line 1058
replace("occup", 5, where=sinrange(d["occup_isco"], "5000", "5999"))
# Stata line 1059
replace("occup", 6, where=sinrange(d["occup_isco"], "6000", "6999"))
# Stata line 1060
replace("occup", 7, where=sinrange(d["occup_isco"], "7000", "7999"))
# Stata line 1061
replace("occup", 8, where=sinrange(d["occup_isco"], "8000", "8999"))
# Stata line 1062
replace("occup", 9, where=sinrange(d["occup_isco"], "9000", "9999"))
# Stata line 1063
replace("occup", 10, where=sinrange(d["occup_isco"], "0000", "0999"))
VARIABLE_LABELS["occup"] = "1 digit occupational classification, primary job 7 day recall"
LABEL_DEFS["lbloccup"] = {1: 'Managers', 2: 'Professionals', 3: 'Technicians', 4: 'Clerks', 5: 'Service and market sales workers', 6: 'Skilled agricultural', 7: 'Craft workers', 8: 'Machine operators', 9: 'Elementary occupations', 10: 'Armed forces', 99: 'Others'}
VALUE_LABELS["occup"] = LABEL_DEFS["lbloccup"].copy()

# <_occup_skill_>
# Stata line 1071
gen("occup_skill", d["occup"], typ="float")
# Stata line 1072
replace("occup_skill", 3, where=sinrange(d["occup"], 1, 3))
# Stata line 1073
replace("occup_skill", 2, where=sinrange(d["occup"], 4, 8))
# Stata line 1074
replace("occup_skill", 1, where=scmp(d["occup"], 9, "=="))
LABEL_DEFS["lblskill"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill"] = LABEL_DEFS["lblskill"].copy()
VARIABLE_LABELS["occup_skill"] = "Skill based on ISCO standard primary job 7 day recall"

# <_wage_no_compen_>
# Stata line 1082
gen("last_week", d["s7c33"], typ="float")
# Stata line 1083
gen("last_month", d["s7c43"], typ="float")
# Stata line 1084
gen("last_year", d["s7c9"], typ="float")
# Stata line 1087
replace("last_week", np.nan, where=scmp(d["last_week"], 0, "<="))
# Stata line 1088
replace("last_month", np.nan, where=scmp(d["last_month"], 0, "<="))
# Stata line 1089
replace("last_year", np.nan, where=scmp(d["last_year"], 0, "<="))
# Stata line 1092
replace("last_week", np.nan, where=((~smissing(d["last_week"])) & (~smissing(d["last_month"]))))
# Stata line 1095
gen("wage_no_compen", d[['last_week', 'last_month', 'last_year']].sum(axis=1, min_count=1), typ="double")
# Stata line 1098
replace("wage_no_compen", np.nan, where=scmp(d["empstat"], 2, "=="))
# Stata line 1099
replace("wage_no_compen", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["wage_no_compen"] = "Last wage payment primary job 7 day recall"
drop_vars(['last_week', 'last_month', 'last_year'])

# <_unitwage_>
# Stata line 1113
gen("unitwage", np.nan, typ="byte")
# Stata line 1114
replace("unitwage", 2, where=(((~smissing(d["s7c33"])) & scmp(d["s7c33"], 0, ">")) & scmp(d["lstatus"], 1, "==")))
# Stata line 1115
replace("unitwage", 5, where=(((~smissing(d["s7c43"])) & scmp(d["s7c43"], 0, ">")) & scmp(d["lstatus"], 1, "==")))
# Stata line 1116
replace("unitwage", 8, where=(((((~smissing(d["s7c9"])) & scmp(d["s7c9"], 0, ">")) & scmp(d["lstatus"], 1, "==")) & smissing(d["s7c43"])) & smissing(d["s7c33"])))
# Stata line 1118
replace("unitwage", np.nan, where=scmp(d["empstat"], 2, "=="))
# Stata line 1119
replace("unitwage", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["unitwage"] = "Last wages' time unit primary job 7 day recall"
LABEL_DEFS["lblunitwage"] = {1: 'Daily', 2: 'Weekly', 3: 'Every two weeks', 4: 'Bimonthly', 5: 'Monthly', 6: 'Trimester', 7: 'Biannual', 8: 'Annually', 9: 'Hourly', 10: 'Other'}
VALUE_LABELS["unitwage"] = LABEL_DEFS["lblunitwage"].copy()

# <_whours_>
# Stata line 1130
gen("whours", np.nan, typ="float")
# Stata line 1131
replace("whours", d["s5c24"], where=scmp(d["lstatus"], 1, "=="))
# Stata line 1132
replace("whours", np.nan, where=(scmp(d["whours"], 0, "==") & scmp(d["lstatus"], 1, "==")))
VARIABLE_LABELS["whours"] = "Hours of work in last week primary job 7 day recall"

# <_wmonths_>
# Stata line 1138
gen("wmonths", np.nan, typ="float")
# Stata line 1139
replace("wmonths", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["wmonths"] = "Months of work in past 12 months primary job 7 day recall"

# <_wage_total_>
# Stata line 1151
gen("wage_total", np.nan, typ="float")
VARIABLE_LABELS["wage_total"] = "Annualized total wage primary job 7 day recall"

# <_contract_>
# Stata line 1157
gen("contract", np.nan, typ="byte")
# Stata line 1158
replace("contract", d["s7c1"], where=scmp(d["lstatus"], 1, "=="))
# Stata line 1159
recode("contract", [([(1, 6)], 1), ([(7, 7)], 0)])
VARIABLE_LABELS["contract"] = "Employment has contract primary job 7 day recall"
LABEL_DEFS["lblcontract"] = {0: 'Without contract', 1: 'With contract'}
VALUE_LABELS["contract"] = LABEL_DEFS["lblcontract"].copy()

# <_healthins_>
# Stata line 1167
gen("healthins", np.nan, typ="byte")
VARIABLE_LABELS["healthins"] = "Employment has health insurance primary job 7 day recall"
LABEL_DEFS["lblhealthins"] = {0: 'Without health insurance', 1: 'With health insurance'}
VALUE_LABELS["healthins"] = LABEL_DEFS["lblhealthins"].copy()

# <_socialsec_>
# Stata line 1175
gen("socialsec", 0, typ="byte")
# Stata line 1176
replace("socialsec", 1, where=(scmp(d["s7c61"], 1, "==") | scmp(d["s7c64"], 4, "==")))
# Stata line 1177
replace("socialsec", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["socialsec"] = "Employment has social security insurance primary job 7 day recall"
LABEL_DEFS["lblsocialsec"] = {1: 'With social security', 0: 'Without social secturity'}
VALUE_LABELS["socialsec"] = LABEL_DEFS["lblsocialsec"].copy()

# <_union_>
# Stata line 1185
gen("union", np.nan, typ="byte")
# Stata line 1186
replace("union", 1, where=scmp(d["s5c20"], 1, "=="))
# Stata line 1187
replace("union", 0, where=(scmp(d["s5c20"], 2, "==") | scmp(d["s5c20"], 3, "==")))
# Stata line 1188
replace("union", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["union"] = "Union membership at primary job 7 day recall"
LABEL_DEFS["lblunion"] = {0: 'Not union member', 1: 'Union member'}
VALUE_LABELS["union"] = LABEL_DEFS["lblunion"].copy()

# <_firmsize_l_>
# Stata line 1196
gen("firmsize_l", d["s5c18"], typ="float")
# Stata line 1197
replace("firmsize_l", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["firmsize_l"] = "Firm size (lower bracket) primary job 7 day recall"

# <_firmsize_u_>
# Stata line 1203
gen("firmsize_u", d["s5c18"], typ="float")
# Stata line 1204
replace("firmsize_u", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["firmsize_u"] = "Firm size (upper bracket) primary job 7 day recall"

# ----------8.3: 7 day reference secondary job------------------------------*

# <_empstat_2_>
# Stata line 1217
gen("empstat_2", d["s5c26"], typ="byte")
# Stata line 1218
recode("empstat_2", [([(3, 3), (5, 5)], 1), ([(4, 4)], 2), ([(1, 1)], 3), ([(2, 2)], 4), ([(6, 6)], 5), ([(0, 0)], np.nan)])
# Stata line 1219
replace("empstat_2", np.nan, where=scmp(d["s5c25"], 1, "!="))
# Stata line 1220
replace("empstat_2", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["empstat_2"] = "Employment status during past week secondary job 7 day recall"
VALUE_LABELS["empstat_2"] = LABEL_DEFS["lblempstat"].copy()

# <_ocusec_2_>
# Stata line 1227
gen("ocusec_2", d["s5c30"], typ="byte")
# Stata line 1228
recode("ocusec_2", [([(1, 3)], 1), ([(4, 4)], 3), ([(5, 10)], 2), ([(11, 11)], 4)])
# Stata line 1229
replace("ocusec_2", np.nan, where=scmp(d["s5c25"], 1, "!="))
# Stata line 1230
replace("ocusec_2", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["ocusec_2"] = "Sector of activity secondary job 7 day recall"
VALUE_LABELS["ocusec_2"] = LABEL_DEFS["lblocusec"].copy()

# <_industry_orig_2_>
# Stata line 1237
gen("industry_orig_2", sstring(d["s5c28"], "%04.0f"), typ="float")
# Stata line 1238
replace("industry_orig_2", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1239
replace("industry_orig_2", "", where=scmp(d["industry_orig"], ".", "=="))
VARIABLE_LABELS["industry_orig_2"] = "Original survey industry code, secondary job 7 day recall"

# <_industrycat_isic_2_>
# Stata line 1246
gen("industrycat_isic_2", d["industry_orig_2"], typ="float")
# Stata line 1247
replace("industrycat_isic_2", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1248
replace("industrycat_isic_2", "", where=scmp(d["industrycat_isic_2"], ".", "=="))
# Stata line 1249
replace("industrycat_isic_2", "", where=smissing(d["empstat_2"]))
# Stata line 1250
replace("industrycat_isic_2", "0320", where=scmp(d["industry_orig_2"], "320", "=="))
# Stata line 1252
replace("industrycat_isic_2", "6120", where=scmp(d["industry_orig_2"], "6121", "=="))
universe_check("industrycat_isic_2", "ISIC")
VARIABLE_LABELS["industrycat_isic_2"] = "ISIC code of secondary job 7 day recall"

# <_industrycat10_2_>
# Stata line 1267
gen("industrycat10_2", np.nan, typ="byte")
# Stata line 1268
replace("industrycat10_2", 1, where=sinrange(d["industrycat_isic_2"], "0100", "0399"))
# Stata line 1269
replace("industrycat10_2", 2, where=sinrange(d["industrycat_isic_2"], "0500", "0999"))
# Stata line 1270
replace("industrycat10_2", 3, where=sinrange(d["industrycat_isic_2"], "1000", "3399"))
# Stata line 1271
replace("industrycat10_2", 4, where=sinrange(d["industrycat_isic_2"], "3500", "3900"))
# Stata line 1272
replace("industrycat10_2", 5, where=sinrange(d["industrycat_isic_2"], "4100", "4399"))
# Stata line 1273
replace("industrycat10_2", 6, where=(sinrange(d["industrycat_isic_2"], "4500", "4799") | sinrange(d["industrycat_isic_2"], "5500", "5699")))
# Stata line 1274
replace("industrycat10_2", 7, where=(sinrange(d["industrycat_isic_2"], "4900", "5399") | sinrange(d["industrycat_isic_2"], "5800", "6399")))
# Stata line 1275
replace("industrycat10_2", 8, where=sinrange(d["industrycat_isic_2"], "6400", "8299"))
# Stata line 1276
replace("industrycat10_2", 9, where=sinrange(d["industrycat_isic_2"], "8400", "8499"))
# Stata line 1277
replace("industrycat10_2", 10, where=sinrange(d["industrycat_isic_2"], "8500", "9900"))
VARIABLE_LABELS["industrycat10_2"] = "1 digit industry classification, secondary job 7 day recall"
VALUE_LABELS["industrycat10_2"] = LABEL_DEFS["lblindustrycat10"].copy()

# <_industrycat4_2_>
# Stata line 1284
gen("industrycat4_2", d["industrycat10_2"], typ="byte")
# Stata line 1285
recode("industrycat4_2", [([(1, 1)], 1), ([(2, 2), (3, 3), (4, 4), (5, 5)], 2), ([(6, 6), (7, 7), (8, 8), (9, 9)], 3), ([(10, 10)], 4)])
VARIABLE_LABELS["industrycat4_2"] = "Broad Economic Activities classification, secondary job 7 day recall"
VALUE_LABELS["industrycat4_2"] = LABEL_DEFS["lblindustrycat4"].copy()

# <_occup_orig_2_>
# Stata line 1292
gen("occup_orig_2", sstring(d["s5c27"], "%04.0f"), typ="float")
# Stata line 1293
replace("occup_orig_2", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1294
replace("occup_orig_2", "", where=scmp(d["industry_orig"], ".", "=="))
VARIABLE_LABELS["occup_orig_2"] = "Original occupation record secondary job 7 day recall"

# <_occup_isco_2_>
# Stata line 1300
gen("occup_isco_2", d["occup_orig_2"], typ="float")
# Stata line 1301
replace("occup_isco_2", "", where=scmp(d["lstatus"], 1, "!="))
# Stata line 1302
replace("occup_isco_2", "", where=scmp(d["occup_isco_2"], ".", "=="))
# Stata line 1305
replace("occup_isco_2", "4100", where=scmp(d["occup_isco_2"], "4140", "=="))
# Stata line 1306
replace("occup_isco_2", "2300", where=scmp(d["occup_isco_2"], "2333", "=="))
# Stata line 1307
replace("occup_isco_2", "9500", where=scmp(d["occup_isco_2"], "9516", "=="))
universe_check("occup_isco_2", "ISCO")
VARIABLE_LABELS["occup_isco_2"] = "ISCO code of secondary job 7 day recall"

# <_occup_2_>
# Stata line 1322
gen("occup_2", np.nan, typ="byte")
# Stata line 1323
replace("occup_2", 1, where=sinrange(d["occup_isco_2"], "1000", "1999"))
# Stata line 1324
replace("occup_2", 2, where=sinrange(d["occup_isco_2"], "2000", "2999"))
# Stata line 1325
replace("occup_2", 3, where=sinrange(d["occup_isco_2"], "3000", "3999"))
# Stata line 1326
replace("occup_2", 4, where=sinrange(d["occup_isco_2"], "4000", "4999"))
# Stata line 1327
replace("occup_2", 5, where=sinrange(d["occup_isco_2"], "5000", "5999"))
# Stata line 1328
replace("occup_2", 6, where=sinrange(d["occup_isco_2"], "6000", "6999"))
# Stata line 1329
replace("occup_2", 7, where=sinrange(d["occup_isco_2"], "7000", "7999"))
# Stata line 1330
replace("occup_2", 8, where=sinrange(d["occup_isco_2"], "8000", "8999"))
# Stata line 1331
replace("occup_2", 9, where=sinrange(d["occup_isco_2"], "9000", "9999"))
# Stata line 1332
replace("occup_2", 10, where=sinrange(d["occup_isco_2"], "0000", "0999"))
VARIABLE_LABELS["occup_2"] = "1 digit occupational classification secondary job 7 day recall"
VALUE_LABELS["occup_2"] = LABEL_DEFS["lbloccup"].copy()

# <_occup_skill_2_>
# Stata line 1339
gen("occup_skill_2", np.nan, typ="float")
# Stata line 1340
replace("occup_skill_2", 3, where=sinrange(d["occup_2"], 1, 3))
# Stata line 1341
replace("occup_skill_2", 2, where=sinrange(d["occup_2"], 4, 8))
# Stata line 1342
replace("occup_skill_2", 1, where=scmp(d["occup_2"], 9, "=="))
LABEL_DEFS["lblskill2"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_2"] = LABEL_DEFS["lblskill2"].copy()
VARIABLE_LABELS["occup_skill_2"] = "Skill based on ISCO standard secondary job 7 day recall"

# <_wage_no_compen_2_>
# Stata line 1350
gen("wage_no_compen_2", np.nan, typ="double")
VARIABLE_LABELS["wage_no_compen_2"] = "Last wage payment secondary job 7 day recall"

# <_unitwage_2_>
# Stata line 1356
gen("unitwage_2", np.nan, typ="byte")
VARIABLE_LABELS["unitwage_2"] = "Last wages' time unit secondary job 7 day recall"
VALUE_LABELS["unitwage_2"] = LABEL_DEFS["lblunitwage"].copy()

# <_whours_2_>
# Stata line 1363
gen("whours_2", d["s5c35"], typ="float")
# Stata line 1364
replace("whours_2", np.nan, where=scmp(d["s5c25"], 1, "!="))
VARIABLE_LABELS["whours_2"] = "Hours of work in last week secondary job 7 day recall"

# <_wmonths_2_>
# Stata line 1370
gen("wmonths_2", np.nan, typ="float")
VARIABLE_LABELS["wmonths_2"] = "Months of work in past 12 months secondary job 7 day recall"

# <_wage_total_2_>
# Stata line 1376
gen("wage_total_2", np.nan, typ="float")
VARIABLE_LABELS["wage_total_2"] = "Annualized total wage secondary job 7 day recall"

# <_firmsize_l_2_>
# Stata line 1382
gen("firmsize_l_2", d["s5c33"], typ="float")
# Stata line 1383
replace("firmsize_l_2", np.nan, where=(scmp(d["s5c25"], 1, "!=") | scmp(d["s5c33"], 0, "==")))
VARIABLE_LABELS["firmsize_l_2"] = "Firm size (lower bracket) secondary job 7 day recall"

# <_firmsize_u_2_>
# Stata line 1389
gen("firmsize_u_2", d["s5c33"], typ="float")
# Stata line 1390
replace("firmsize_l_2", np.nan, where=(scmp(d["s5c25"], 1, "!=") | scmp(d["s5c33"], 0, "==")))
VARIABLE_LABELS["firmsize_u_2"] = "Firm size (upper bracket) secondary job 7 day recall"

# ----------8.4: 7 day reference additional jobs------------------------------*

# <_t_hours_others_>
# Stata line 1399
gen("t_hours_others", np.nan, typ="float")
VARIABLE_LABELS["t_hours_others"] = "Annualized hours worked in all but primary and secondary jobs 7 day recall"

# <_t_wage_nocompen_others_>
# Stata line 1405
gen("t_wage_nocompen_others", np.nan, typ="float")
VARIABLE_LABELS["t_wage_nocompen_others"] = "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_others_>
# Stata line 1411
gen("t_wage_others", np.nan, typ="float")
VARIABLE_LABELS["t_wage_others"] = "Annualized wage in all but primary and secondary jobs (12-mon ref period)"

# ----------8.5: 7 day reference total summary------------------------------*

# <_t_hours_total_>
# Stata line 1420
gen("t_hours_total", np.nan, typ="float")
VARIABLE_LABELS["t_hours_total"] = "Annualized hours worked in all jobs 7 day recall"

# <_t_wage_nocompen_total_>
# Stata line 1426
gen("t_wage_nocompen_total", np.nan, typ="float")
VARIABLE_LABELS["t_wage_nocompen_total"] = "Annualized wage in all jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_total_>
# Stata line 1432
gen("t_wage_total", np.nan, typ="float")
VARIABLE_LABELS["t_wage_total"] = "Annualized total wage for all jobs 7 day recall"

# ----------8.6: 12 month reference overall------------------------------*

# <_lstatus_year_>
# Stata line 1442
gen("lstatus_year", np.nan, typ="byte")
# Stata line 1443
replace("lstatus_year", np.nan, where=(scmp(d["age"], d["minlaborage"], "<") & (~smissing(d["age"]))))
VARIABLE_LABELS["lstatus_year"] = "Labor status during last year"
LABEL_DEFS["lbllstatus_year"] = {1: 'Employed', 2: 'Unemployed', 3: 'Non-LF'}
VALUE_LABELS["lstatus_year"] = LABEL_DEFS["lbllstatus_year"].copy()

# <_potential_lf_year_>
# Stata line 1450
gen("potential_lf_year", np.nan, typ="byte")
# Stata line 1451
replace("potential_lf_year", np.nan, where=(scmp(d["age"], d["minlaborage"], "<") & (~smissing(d["age"]))))
# Stata line 1452
replace("potential_lf_year", np.nan, where=scmp(d["lstatus_year"], 3, "!="))
VARIABLE_LABELS["potential_lf_year"] = "Potential labour force status"
LABEL_DEFS["lblpotential_lf_year"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["potential_lf_year"] = LABEL_DEFS["lblpotential_lf_year"].copy()

# <_underemployment_year_>
# Stata line 1460
gen("underemployment_year", np.nan, typ="byte")
# Stata line 1461
replace("underemployment_year", np.nan, where=(scmp(d["age"], d["minlaborage"], "<") & (~smissing(d["age"]))))
# Stata line 1462
replace("underemployment_year", np.nan, where=scmp(d["lstatus_year"], 1, "=="))
VARIABLE_LABELS["underemployment_year"] = "Underemployment status"
LABEL_DEFS["lblunderemployment_year"] = {0: 'No', 1: 'Yes'}
VALUE_LABELS["underemployment_year"] = LABEL_DEFS["lblunderemployment_year"].copy()

# <_nlfreason_year_>
# Stata line 1470
gen("nlfreason_year", np.nan, typ="byte")
VARIABLE_LABELS["nlfreason_year"] = "Reason not in the labor force"
LABEL_DEFS["lblnlfreason_year"] = {1: 'Student', 2: 'Housekeeper', 3: 'Retired', 4: 'Disabled', 5: 'Other'}
VALUE_LABELS["nlfreason_year"] = LABEL_DEFS["lblnlfreason_year"].copy()

# <_unempldur_l_year_>
# Stata line 1478
gen("unempldur_l_year", np.nan, typ="byte")
VARIABLE_LABELS["unempldur_l_year"] = "Unemployment duration (months) lower bracket"

# <_unempldur_u_year_>
# Stata line 1484
gen("unempldur_u_year", np.nan, typ="byte")
VARIABLE_LABELS["unempldur_u_year"] = "Unemployment duration (months) upper bracket"

# ----------8.7: 12 month reference main job------------------------------*

# <_empstat_year_>
# Stata line 1495
gen("empstat_year", np.nan, typ="byte")
VARIABLE_LABELS["empstat_year"] = "Employment status during past week primary job 12 month recall"
LABEL_DEFS["lblempstat_year"] = {1: 'Paid employee', 2: 'Non-paid employee', 3: 'Employer', 4: 'Self-employed', 5: 'Other, workers not classifiable by status'}
VALUE_LABELS["empstat_year"] = LABEL_DEFS["lblempstat_year"].copy()

# <_ocusec_year_>
# Stata line 1502
gen("ocusec_year", np.nan, typ="byte")
VARIABLE_LABELS["ocusec_year"] = "Sector of activity primary job 12 month recall"
LABEL_DEFS["lblocusec_year"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec_year"] = LABEL_DEFS["lblocusec_year"].copy()

# <_industry_orig_year_>
# Stata line 1509
gen("industry_orig_year", np.nan, typ="float")
VARIABLE_LABELS["industry_orig_year"] = "Original industry record main job 12 month recall"

# <_industrycat_isic_year_>
# Stata line 1515
gen("industrycat_isic_year", np.nan, typ="float")
VARIABLE_LABELS["industrycat_isic_year"] = "ISIC code of primary job 12 month recall"

# <_industrycat10_year_>
# Stata line 1531
gen("industrycat10_year", np.nan, typ="byte")
VARIABLE_LABELS["industrycat10_year"] = "1 digit industry classification, primary job 12 month recall"
LABEL_DEFS["lblindustrycat10_year"] = {1: 'Agriculture', 2: 'Mining', 3: 'Manufacturing', 4: 'Public utilities', 5: 'Construction', 6: 'Commerce', 7: 'Transport and Comnunications', 8: 'Financial and Business Services', 9: 'Public Administration', 10: 'Other Services, Unspecified'}
VALUE_LABELS["industrycat10_year"] = LABEL_DEFS["lblindustrycat10_year"].copy()

# <_industrycat4_year_>
# Stata line 1539
gen("industrycat4_year", d["industrycat10_year"], typ="byte")
# Stata line 1540
recode("industrycat4_year", [([(1, 1)], 1), ([(2, 2), (3, 3), (4, 4), (5, 5)], 2), ([(6, 6), (7, 7), (8, 8), (9, 9)], 3), ([(10, 10)], 4)])
VARIABLE_LABELS["industrycat4_year"] = "Broad Economic Activities classification, primary job 12 month recall"
LABEL_DEFS["lblindustrycat4_year"] = {1: 'Agriculture', 2: 'Industry', 3: 'Services', 4: 'Other'}
VALUE_LABELS["industrycat4_year"] = LABEL_DEFS["lblindustrycat4_year"].copy()

# <_occup_orig_year_>
# Stata line 1548
gen("occup_orig_year", np.nan, typ="float")
VARIABLE_LABELS["occup_orig_year"] = "Original occupation record primary job 12 month recall"

# <_occup_isco_year_>
# Stata line 1554
gen("occup_isco_year", "", typ="float")
VARIABLE_LABELS["occup_isco_year"] = "ISCO code of primary job 12 month recall"

# <_occup_year_>
# Stata line 1571
gen("occup_year", np.nan, typ="byte")
VARIABLE_LABELS["occup_year"] = "1 digit occupational classification, primary job 12 month recall"
LABEL_DEFS["lbloccup_year"] = {1: 'Managers', 2: 'Professionals', 3: 'Technicians', 4: 'Clerks', 5: 'Service and market sales workers', 6: 'Skilled agricultural', 7: 'Craft workers', 8: 'Machine operators', 9: 'Elementary occupations', 10: 'Armed forces', 99: 'Others'}
VALUE_LABELS["occup_year"] = LABEL_DEFS["lbloccup_year"].copy()

# <_occup_skill_year_>
# Stata line 1579
gen("occup_skill_year", np.nan, typ="float")
# Stata line 1580
replace("occup_skill_year", 3, where=sinrange(d["occup_year"], 1, 3))
# Stata line 1581
replace("occup_skill_year", 2, where=sinrange(d["occup_year"], 4, 8))
# Stata line 1582
replace("occup_skill_year", 1, where=scmp(d["occup_year"], 9, "=="))
LABEL_DEFS["lblskillyear"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_year"] = LABEL_DEFS["lblskillyear"].copy()
VARIABLE_LABELS["occup_skill_year"] = "Skill based on ISCO standard primary job 12 month recall"

# <_wage_no_compen_year_> --- this var has the same name as other and when quoted in the keep and order codes is repeated.
# Stata line 1590
gen("wage_no_compen_year", np.nan, typ="double")
VARIABLE_LABELS["wage_no_compen_year"] = "Last wage payment primary job 12 month recall"

# <_unitwage_year_>
# Stata line 1596
gen("unitwage_year", np.nan, typ="byte")
VARIABLE_LABELS["unitwage_year"] = "Last wages' time unit primary job 12 month recall"
LABEL_DEFS["lblunitwage_year"] = {1: 'Daily', 2: 'Weekly', 3: 'Every two weeks', 4: 'Bimonthly', 5: 'Monthly', 6: 'Trimester', 7: 'Biannual', 8: 'Annually', 9: 'Hourly', 10: 'Other'}
VALUE_LABELS["unitwage_year"] = LABEL_DEFS["lblunitwage_year"].copy()

# <_whours_year_>
# Stata line 1604
gen("whours_year", np.nan, typ="float")
VARIABLE_LABELS["whours_year"] = "Hours of work in last week primary job 12 month recall"

# <_wmonths_year_>
# Stata line 1610
gen("wmonths_year", np.nan, typ="float")
VARIABLE_LABELS["wmonths_year"] = "Months of work in past 12 months primary job 12 month recall"

# <_wage_total_year_>
# Stata line 1616
gen("wage_total_year", np.nan, typ="float")
VARIABLE_LABELS["wage_total_year"] = "Annualized total wage primary job 12 month recall"

# <_contract_year_>
# Stata line 1622
gen("contract_year", np.nan, typ="byte")
VARIABLE_LABELS["contract_year"] = "Employment has contract primary job 12 month recall"
LABEL_DEFS["lblcontract_year"] = {0: 'Without contract', 1: 'With contract'}
VALUE_LABELS["contract_year"] = LABEL_DEFS["lblcontract_year"].copy()

# <_healthins_year_>
# Stata line 1630
gen("healthins_year", np.nan, typ="byte")
VARIABLE_LABELS["healthins_year"] = "Employment has health insurance primary job 12 month recall"
LABEL_DEFS["lblhealthins_year"] = {0: 'Without health insurance', 1: 'With health insurance'}
VALUE_LABELS["healthins_year"] = LABEL_DEFS["lblhealthins_year"].copy()

# <_socialsec_year_>
# Stata line 1638
gen("socialsec_year", np.nan, typ="byte")
VARIABLE_LABELS["socialsec_year"] = "Employment has social security insurance primary job 7 day recall"
LABEL_DEFS["lblsocialsec_year"] = {1: 'With social security', 0: 'Without social secturity'}
VALUE_LABELS["socialsec_year"] = LABEL_DEFS["lblsocialsec_year"].copy()

# <_union_year_>
# Stata line 1646
gen("union_year", np.nan, typ="byte")
VARIABLE_LABELS["union_year"] = "Union membership at primary job 12 month recall"
LABEL_DEFS["lblunion_year"] = {0: 'Not union member', 1: 'Union member'}
VALUE_LABELS["union_year"] = LABEL_DEFS["lblunion_year"].copy()

# <_firmsize_l_year_>
# Stata line 1654
gen("firmsize_l_year", np.nan, typ="float")
VARIABLE_LABELS["firmsize_l_year"] = "Firm size (lower bracket) primary job 12 month recall"

# <_firmsize_u_year_>
# Stata line 1660
gen("firmsize_u_year", np.nan, typ="float")
VARIABLE_LABELS["firmsize_u_year"] = "Firm size (upper bracket) primary job 12 month recall"

# ----------8.8: 12 month reference secondary job------------------------------*

# <_empstat_2_year_>
# Stata line 1672
gen("empstat_2_year", np.nan, typ="byte")
VARIABLE_LABELS["empstat_2_year"] = "Employment status during past week secondary job 12 month recall"
VALUE_LABELS["empstat_2_year"] = LABEL_DEFS["lblempstat_year"].copy()

# <_ocusec_2_year_>
# Stata line 1679
gen("ocusec_2_year", np.nan, typ="byte")
VARIABLE_LABELS["ocusec_2_year"] = "Sector of activity secondary job 12 month recall"
LABEL_DEFS["lblocusec_2_year"] = {1: 'Public Sector, Central Government, Army', 2: 'Private, NGO', 3: 'State owned', 4: 'Public or State-owned, but cannot distinguish'}
VALUE_LABELS["ocusec_2_year"] = LABEL_DEFS["lblocusec_2_year"].copy()

# <_industry_orig_2_year_>
# Stata line 1688
gen("industry_orig_2_year", np.nan, typ="float")
VARIABLE_LABELS["industry_orig_2_year"] = "Original survey industry code, secondary job 12 month recall"

# <_industrycat_isic_2_year_>
# Stata line 1695
gen("industrycat_isic_2_year", np.nan, typ="float")
VARIABLE_LABELS["industrycat_isic_2_year"] = "ISIC code of secondary job 12 month recall"

# <_industrycat10_2_year_>
# Stata line 1701
gen("industrycat10_2_year", np.nan, typ="byte")
VARIABLE_LABELS["industrycat10_2_year"] = "1 digit industry classification, secondary job 12 month recall"
VALUE_LABELS["industrycat10_2_year"] = LABEL_DEFS["lblindustrycat10_year"].copy()

# <_industrycat4_2_year_>
# Stata line 1708
gen("industrycat4_2_year", d["industrycat10_2_year"], typ="byte")
# Stata line 1709
recode("industrycat4_2_year", [([(1, 1)], 1), ([(2, 2), (3, 3), (4, 4), (5, 5)], 2), ([(6, 6), (7, 7), (8, 8), (9, 9)], 3), ([(10, 10)], 4)])
VARIABLE_LABELS["industrycat4_2_year"] = "Broad Economic Activities classification, secondary job 12 month recall"
VALUE_LABELS["industrycat4_2_year"] = LABEL_DEFS["lblindustrycat4_year"].copy()

# <_occup_orig_2_year_>
# Stata line 1716
gen("occup_orig_2_year", np.nan, typ="float")
VARIABLE_LABELS["occup_orig_2_year"] = "Original occupation record secondary job 12 month recall"

# <_occup_isco_2_year_>
# Stata line 1722
gen("occup_isco_2_year", "", typ="float")
VARIABLE_LABELS["occup_isco_2_year"] = "ISCO code of secondary job 12 month recall"

# <_occup_2_year_>
# Stata line 1728
gen("occup_2_year", np.nan, typ="byte")
VARIABLE_LABELS["occup_2_year"] = "1 digit occupational classification, secondary job 12 month recall"
VALUE_LABELS["occup_2_year"] = LABEL_DEFS["lbloccup_year"].copy()

# <_occup_skill_2_year_>
# Stata line 1735
gen("occup_skill_2_year", np.nan, typ="float")
# Stata line 1736
replace("occup_skill_2_year", 3, where=sinrange(d["occup_2_year"], 1, 3))
# Stata line 1737
replace("occup_skill_2_year", 2, where=sinrange(d["occup_2_year"], 4, 8))
# Stata line 1738
replace("occup_skill_2_year", 1, where=scmp(d["occup_2_year"], 9, "=="))
LABEL_DEFS["lblskilly2"] = {1: 'Low skill', 2: 'Medium skill', 3: 'High skill'}
VALUE_LABELS["occup_skill_2_year"] = LABEL_DEFS["lblskilly2"].copy()
VARIABLE_LABELS["occup_skill_2_year"] = "Skill based on ISCO standard secondary job 12 month recall"

# <_wage_no_compen_2_year_>
# Stata line 1746
gen("wage_no_compen_2_year", np.nan, typ="double")
VARIABLE_LABELS["wage_no_compen_2_year"] = "Last wage payment secondary job 12 month recall"

# <_unitwage_2_year_>
# Stata line 1752
gen("unitwage_2_year", np.nan, typ="byte")
VARIABLE_LABELS["unitwage_2_year"] = "Last wages' time unit secondary job 12 month recall"
VALUE_LABELS["unitwage_2_year"] = LABEL_DEFS["lblunitwage_year"].copy()

# <_whours_2_year_>
# Stata line 1759
gen("whours_2_year", np.nan, typ="float")
VARIABLE_LABELS["whours_2_year"] = "Hours of work in last week secondary job 12 month recall"

# <_wmonths_2_year_>
# Stata line 1765
gen("wmonths_2_year", np.nan, typ="float")
VARIABLE_LABELS["wmonths_2_year"] = "Months of work in past 12 months secondary job 12 month recall"

# <_wage_total_2_year_>
# Stata line 1771
gen("wage_total_2_year", np.nan, typ="float")
VARIABLE_LABELS["wage_total_2_year"] = "Annualized total wage secondary job 12 month recall"

# <_firmsize_l_2_year_>
# Stata line 1776
gen("firmsize_l_2_year", np.nan, typ="float")
VARIABLE_LABELS["firmsize_l_2_year"] = "Firm size (lower bracket) secondary job 12 month recall"

# <_firmsize_u_2_year_>
# Stata line 1782
gen("firmsize_u_2_year", np.nan, typ="float")
VARIABLE_LABELS["firmsize_u_2_year"] = "Firm size (upper bracket) secondary job 12 month recall"

# ----------8.9: 12 month reference additional jobs------------------------------*

# <_t_hours_others_year_>
# Stata line 1793
gen("t_hours_others_year", np.nan, typ="float")
VARIABLE_LABELS["t_hours_others_year"] = "Annualized hours worked in all but primary and secondary jobs 12 month recall"

# <_t_wage_nocompen_others_year_>
# Stata line 1798
gen("t_wage_nocompen_others_year", np.nan, typ="float")
VARIABLE_LABELS["t_wage_nocompen_others_year"] = "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_others_year_>
# Stata line 1803
gen("t_wage_others_year", np.nan, typ="float")
VARIABLE_LABELS["t_wage_others_year"] = "Annualized wage in all but primary and secondary jobs 12 month recall"

# ----------8.10: 12 month total summary------------------------------*

# <_t_hours_total_year_>
# Stata line 1812
gen("t_hours_total_year", np.nan, typ="float")
VARIABLE_LABELS["t_hours_total_year"] = "Annualized hours worked in all jobs 12 month month recall"

# <_t_wage_nocompen_total_year_>
# Stata line 1818
gen("t_wage_nocompen_total_year", np.nan, typ="float")
VARIABLE_LABELS["t_wage_nocompen_total_year"] = "Annualized wage in all jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_total_year_>
# Stata line 1824
gen("t_wage_total_year", np.nan, typ="float")
VARIABLE_LABELS["t_wage_total_year"] = "Annualized total wage for all jobs 12 month recall"

# ----------8.11: Overall across reference periods------------------------------*

# <_njobs_>
# Stata line 1833
gen("njobs", np.nan, typ="float")
# Stata line 1834
replace("njobs", 1, where=scmp(d["s5c25"], 2, "=="))
# Stata line 1835
replace("njobs", 2, where=(scmp(d["s5c25"], 1, "==") & scmp(d["s5c36"], 2, "==")))
# Stata line 1836
replace("njobs", 3, where=(scmp(d["s5c25"], 1, "==") & scmp(d["s5c36"], 1, "==")))
# Stata line 1837
replace("njobs", np.nan, where=scmp(d["lstatus"], 1, "!="))
VARIABLE_LABELS["njobs"] = "Total number of jobs"

# <_t_hours_annual_>
# Stata line 1843
gen("t_hours_annual", np.nan, typ="float")
VARIABLE_LABELS["t_hours_annual"] = "Total hours worked in all jobs in the previous 12 months"

# <_linc_nc_>
# Stata line 1849
gen("linc_nc", np.nan, typ="float")
VARIABLE_LABELS["linc_nc"] = "Total annual wage income in all jobs, excl. bonuses, etc."

# <_laborincome_>
# Stata line 1855
gen("laborincome", d["t_wage_total_year"], typ="float")
VARIABLE_LABELS["laborincome"] = "Total annual individual labor income in all jobs, incl. bonuses, etc."

# ----------8.13: Labour cleanup------------------------------*

# <_% Correction min age_>
age_blank(['minlaborage', 'lstatus', 'nlfreason', 'unempldur_l', 'unempldur_u', 'empstat', 'ocusec', 'industry_orig', 'industrycat_isic', 'industrycat10', 'industrycat4', 'occup_orig', 'occup_isco', 'occup_skill', 'occup', 'wage_no_compen', 'unitwage', 'whours', 'wmonths', 'wage_total', 'contract', 'healthins', 'socialsec', 'union', 'firmsize_l', 'firmsize_u', 'empstat_2', 'ocusec_2', 'industry_orig_2', 'industrycat_isic_2', 'industrycat10_2', 'industrycat4_2', 'occup_orig_2', 'occup_isco_2', 'occup_skill_2', 'occup_2', 'wage_no_compen_2', 'unitwage_2', 'whours_2', 'wmonths_2', 'wage_total_2', 'firmsize_l_2', 'firmsize_u_2', 't_hours_others', 't_wage_nocompen_others', 't_wage_others', 't_hours_total', 't_wage_nocompen_total', 't_wage_total', 'lstatus_year', 'nlfreason_year', 'unempldur_l_year', 'unempldur_u_year', 'empstat_year', 'ocusec_year', 'industry_orig_year', 'industrycat_isic_year', 'industrycat10_year', 'industrycat4_year', 'occup_orig_year', 'occup_isco_year', 'occup_skill_year', 'occup_year', 'unitwage_year', 'whours_year', 'wmonths_year', 'wage_total_year', 'contract_year', 'healthins_year', 'socialsec_year', 'union_year', 'firmsize_l_year', 'firmsize_u_year', 'empstat_2_year', 'ocusec_2_year', 'industry_orig_2_year', 'industrycat_isic_2_year', 'industrycat10_2_year', 'industrycat4_2_year', 'occup_orig_2_year', 'occup_isco_2_year', 'occup_skill_2_year', 'occup_2_year', 'wage_no_compen_2_year', 'unitwage_2_year', 'whours_2_year', 'wmonths_2_year', 'wage_total_2_year', 'firmsize_l_2_year', 'firmsize_u_2_year', 't_hours_others_year', 't_wage_nocompen_others_year', 't_wage_others_year', 't_hours_total_year', 't_wage_nocompen_total_year', 't_wage_total_year', 'njobs', 't_hours_annual', 'linc_nc', 'laborincome'], "minlaborage")

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

# 9. Drop wholly missing variables, as the Stata Recreator does.
d=d[[name for name in d if not bool(np.all(smissing(d[name])))]]
# Store numeric values losslessly in a portable Stata 14+ file. File storage
# widths/label identifiers can differ, while values and label text are preserved.
for name in d:
    if d[name].dtype == object: d[name]=d[name].fillna('')
filename=OUTPUT/'PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED_PYTHON.dta'
pyreadstat.write_dta(d,str(filename),version=15,
    column_labels={k:v for k,v in VARIABLE_LABELS.items() if k in d},
    variable_value_labels={k:v for k,v in VALUE_LABELS.items() if k in d})
print(f'Saved {len(d):,} records and {len(d.columns)} variables: {filename.name}')

