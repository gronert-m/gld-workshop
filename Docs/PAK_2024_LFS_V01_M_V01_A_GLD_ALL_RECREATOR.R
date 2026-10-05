# Native R reproduction of the workshop PAK 2024 Stata Recreator.
# Run: Rscript PAK_2024_LFS_V01_M_V01_A_GLD_ALL_RECREATOR.R [input_directory] [output_directory]
# Requires haven. Inputs are read-only; download respondent microdata from PBS.
# Output: _RECREATED_R.dta. No Stata installation or reference output is needed.
# Stata comparisons, float rounding and the source's coding quirks are intentional.
if (!requireNamespace("haven", quietly=TRUE)) stop("Install the haven package before running.")
args <- commandArgs(trailingOnly=TRUE)
filearg <- grep("^--file=", commandArgs(), value=TRUE)
here <- if (length(filearg)) dirname(normalizePath(sub("^--file=", "", filearg[1]))) else getwd()
input <- if (length(args)) normalizePath(args[1], mustWork=TRUE) else here
output <- if (length(args)>1) args[2] else input
dir.create(output, recursive=TRUE, showWarnings=FALSE)
variable_labels <- list(); label_defs <- list(); value_labels <- list(); types <- list()
read_dta <- function(path) {
  x <- as.data.frame(haven::read_dta(path))
  for (nm in names(x)) attributes(x[[nm]]) <- NULL
  x
}
smissing <- function(x) if (is.character(x)) is.na(x) | x=="" else is.na(x)
scmp <- function(a,b,op) {
  ordered <- function(x) { x[is.na(x)] <- if (is.character(x)) "" else Inf; x }
  a<-ordered(a); b<-ordered(b)
  switch(op, "=="=a==b, "!="=a!=b, "<"=a<b, ">"=a>b, "<="=a<=b, ">="=a>=b)
}
sinrange <- function(x,lo,hi) !smissing(x) & scmp(x,lo,">=") & scmp(x,hi,"<=")
sinlist <- function(x,...) Reduce(`|`, lapply(list(...),function(v) scmp(x,v,"==")))
sadd <- function(a,b) if (is.character(a) || is.character(b)) paste0(a,b) else a+b
scond <- function(test,yes,no) ifelse(test,yes,no)
sstring <- function(x,fmt=NULL) {
  if (is.null(fmt)) out<-format(x, scientific=FALSE, trim=TRUE, digits=9) else out<-sprintf(fmt,x)
  out[is.na(x)]<-"."
  out
}
ssubstr <- function(x,start,len) substr(x,start,start+len-1)
rounded <- function(x,typ) {
  x<-rep(x,length.out=nrow(d))
  if (typ=="string") { x[is.na(x)]<-""; return(as.character(x)) }
  x<-as.numeric(x)
  if (typ %in% c("byte","int","long")) {
    limits<-switch(typ, byte=c(-127,100), int=c(-32767,32740), long=c(-2147483647,2147483620))
    x<-trunc(x); x[!is.na(x) & (x<limits[1] | x>limits[2])]<-NA_real_
  } else if (typ!="double") {
    x<-readBin(writeBin(x,raw(),size=4),what="double",n=length(x),size=4)
  }
  x
}
gen <- function(name,values,typ="float",where=TRUE) {
  if (name %in% names(d)) stop(paste("Already defined:",name))
  if (is.character(values)) typ<-"string"
  types[[name]]<<-typ
  x<-rounded(values,typ); where<-rep(where,length.out=nrow(d))
  x[!where]<-if (typ=="string") "" else NA_real_
  d[[name]]<<-x
}
replace <- function(name,values,where=TRUE) {
  where<-rep(where,length.out=nrow(d))
  typ<-types[[name]]
  if (is.null(typ)) typ<-if (is.character(d[[name]])) "string" else "double"
  x<-rounded(values,typ)
  d[[name]][where]<<-x[where]
}
recode <- function(name,rules) {
  original<-d[[name]]; done<-rep(FALSE,nrow(d))
  for (rule in rules) {
    selected<-rep(FALSE,nrow(d))
    for (range in rule$ranges) selected<-selected | sinrange(original,range[1],range[2])
    selected<-selected & !done
    replace(name,rule$value,selected);done<-done | selected
  }
}
drop_vars <- function(patterns) {
  selected<-unique(unlist(lapply(patterns,function(p) grep(glob2rx(p),names(d),value=TRUE))))
  d[selected]<<-NULL
  for (nm in selected) { variable_labels[[nm]]<<-NULL; value_labels[[nm]]<<-NULL; types[[nm]]<<-NULL }
}
merge_lookup <- function(key,lookup) {
  if (anyDuplicated(lookup[[key]])) stop(paste("Nonunique lookup key:",key))
  idx<-match(d[[key]],lookup[[key]])
  for (nm in setdiff(names(lookup),names(d))) d[[nm]]<<-lookup[[nm]][idx]
  for (nm in names(d)) if (is.character(d[[nm]])) d[[nm]][is.na(d[[nm]])]<<-""
  d[["_merge"]]<<-ifelse(is.na(idx),1,3)
}
labmask <- function(name,text) {
  valid<-unique(d[!smissing(d[[name]]),c(name,text)])
  if (anyDuplicated(valid[[name]])) stop(paste("Conflicting labels for",name))
  value_labels[[name]]<<-setNames(as.numeric(valid[[name]]),valid[[text]])
}
decode <- function(name) {
  labs<-value_labels[[name]]
  out<-names(labs)[match(d[[name]],unname(labs))]
  out[is.na(out)]<-""; out
}
age_blank <- function(names,threshold) {
  mask<-d[["age"]]<d[[threshold]] & !smissing(d[["age"]])
  for (name in names) replace(name,if(types[[name]]=="string") "" else NA_real_,mask)
}
universe_check <- function(name,universe) {
  table<-read.csv(file.path(here,"classification_universes",paste0(tolower(universe),"_codes.csv")),colClasses="character",fileEncoding="UTF-8")
  names(table)<-tolower(names(table))
  version<-if(universe=="ISIC") "isic_4" else "isco_2008"
  valid<-table$code[table$version==version]
  bad<-setdiff(d[[name]][!smissing(d[[name]])],valid)
  if(length(bad)) stop(paste("Invalid",universe,"codes in",name,paste(bad,collapse=", ")))
  cat(name,": classification check passed\n")
}
# 1. Assemble inputs without overwriting the migration lookup or raw files.
d<-read_dta(file.path(input,"LFS 2024-25.sav web.dta")); names(d)<-tolower(names(d))
migration<-read_dta(file.path(input,"append_lfs_districts.dta"))
names(migration)[names(migration)=="LFS24_Distcodes"]<-"city_code"
names(migration)[names(migration)=="LFS24_Distnames"]<-"city_name"
migration[c("samecode","sametext")]<-NULL; names(migration)<-tolower(names(migration))
country<-read_dta(file.path(input,"PAK_country_code_2020.dta"))
training<-read_dta(file.path(input,"PAK_training_code.dta"))

# Source SHA256: d568ed498594b5454c48da52240dade734c9df49a733a9b59e6dbc651ac4b4d9

# <_countrycode_>
# Stata line 104
gen("countrycode", "PAK", typ="string")
variable_labels[["countrycode"]] <- "Country code"

# <_survname_>
# Stata line 110
gen("survname", "LFS", typ="float")
variable_labels[["survname"]] <- "Survey acronym"

# <_survey_>
# Stata line 116
gen("survey", "LFS", typ="float")
variable_labels[["survey"]] <- "Survey type"

# <_icls_v_>
# Stata line 122
gen("icls_v", "ICLS-19", typ="float")
variable_labels[["icls_v"]] <- "ICLS version underlying questionnaire questions"

# <_isced_version_>
# Stata line 128
gen("isced_version", "isced_2011", typ="float")
variable_labels[["isced_version"]] <- "Version of ISCED used for educat_isced"

# <_isco_version_>
# Stata line 134
gen("isco_version", "isco_2008", typ="float")
variable_labels[["isco_version"]] <- "Version of ISCO used"

# <_isic_version_>
# Stata line 140
gen("isic_version", "isic_4", typ="float")
variable_labels[["isic_version"]] <- "Version of ISIC used"

# <_year_>
# Stata line 146
gen("year", 2024, typ="int")
variable_labels[["year"]] <- "Year of survey"

# <_vermast_>
# Stata line 152
gen("vermast", "", typ="float")
variable_labels[["vermast"]] <- "Version of master data"

# <_veralt_>
# Stata line 158
gen("veralt", "", typ="float")
variable_labels[["veralt"]] <- "Version of the alt/harmonized data"

# <_harmonization_>
# Stata line 164
gen("harmonization", "GLD", typ="float")
variable_labels[["harmonization"]] <- "Type of harmonization"

# <_int_year_>
# Stata line 170
gen("int_year", NA_real_, typ="float")
variable_labels[["int_year"]] <- "Year of the interview"

# <_int_month_>
# Stata line 176
gen("int_month", NA_real_, typ="float")
label_defs[["lblint_month"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"))
value_labels[["int_month"]] <- label_defs[["lblint_month"]]
variable_labels[["int_month"]] <- "Month of the interview"

# <_hhid_>
# Stata line 192
d[["hhno"]] <- sstring(d[["hhno"]], "%02.0f")
# Stata line 193
gen("hhid", paste0(if(is.character(d[["pcode"]])) d[["pcode"]] else sstring(d[["pcode"]]), if(is.character(d[["hhno"]])) d[["hhno"]] else sstring(d[["hhno"]])), typ="string")
variable_labels[["hhid"]] <- "Household ID"

# <_pid_>
# Stata line 199
gen("sno_str", d[["sno"]], typ="float")
# Stata line 200
d[["sno_str"]] <- sstring(d[["sno_str"]], "%02.0f")
# Stata line 201
gen("pid", paste0(if(is.character(d[["hhid"]])) d[["hhid"]] else sstring(d[["hhid"]]), if(is.character(d[["sno"]])) d[["sno"]] else sstring(d[["sno"]])), typ="string")
variable_labels[["pid"]] <- "Individual ID"
stopifnot(!anyDuplicated(d[["pid"]]), !any(smissing(d[["pid"]])))

# <_weight_>
# Stata line 208
gen("weight", d[["weights"]], typ="float")
variable_labels[["weight"]] <- "Survey sampling weight"

# <_weight_m_>
# Stata line 215
gen("weight_m", NA_real_, typ="float")
variable_labels[["weight_m"]] <- "Survey sampling weight to obtain national estimates for each month"

# <_weight_q_>
# Stata line 221
gen("weight_q", NA_real_, typ="float")
variable_labels[["weight_q"]] <- "Survey sampling weight to obtain national estimates for each quarter"

# <_psu_>
# Stata line 227
gen("psu", d[["pcode"]], typ="float")
variable_labels[["psu"]] <- "Primary sampling units"

# <_ssu_>
# Stata line 233
gen("ssu", d[["hhid"]], typ="float")
variable_labels[["ssu"]] <- "Secondary sampling units"

# <_strata_>
# Stata line 239
gen("strata", ssubstr(d[["pcode"]], 1, 3), typ="float")
# Stata line 240
d[["strata"]] <- as.numeric(d[["strata"]])
variable_labels[["strata"]] <- "Strata"

# <_wave_>
# Stata line 246
gen("wave", d[["quarter"]], typ="float")
variable_labels[["wave"]] <- "Survey wave"

# <_panel_>
# Stata line 252
gen("panel", "", typ="float")
variable_labels[["panel"]] <- "Panel individual belongs to"

# <_visit_no_>
# Stata line 258
gen("visit_no", NA_real_, typ="float")
variable_labels[["visit_no"]] <- "Visit number in panel"

# <_urban_>
# Stata line 272
gen("urban", d[["region"]], typ="byte")
# Stata line 273
recode("urban", list(list(ranges=list(c(1,1)), value=0), list(ranges=list(c(2,2)), value=1)))
variable_labels[["urban"]] <- "Location is urban"
label_defs[["lblurban"]] <- setNames(c(1, 0), c("Urban", "Rural"))
value_labels[["urban"]] <- label_defs[["lblurban"]]

# <_subnatid1_>
# Stata line 288
gen("subnatid1", "", typ="float")
# Stata line 289
replace("subnatid1", "1 - Khyber/Pakhtoonkhua", where=scmp(d[["province"]], 1, "=="))
# Stata line 290
replace("subnatid1", "2 - Punjab", where=scmp(d[["province"]], 2, "=="))
# Stata line 291
replace("subnatid1", "3 - Sindh", where=scmp(d[["province"]], 3, "=="))
# Stata line 292
replace("subnatid1", "4 - Balochistan", where=scmp(d[["province"]], 4, "=="))
variable_labels[["subnatid1"]] <- "Subnational ID at First Administrative Level"

# <_subnatid2_>
# Stata line 298
gen("subnatid2", "", typ="string")
variable_labels[["subnatid2"]] <- "Subnational ID at Second Administrative Level"

# <_subnatid3_>
# Stata line 304
gen("subnatid3", "", typ="string")
variable_labels[["subnatid3"]] <- "Subnational ID at Third Administrative Level"

# <_subnatidsurvey_>
# Stata line 317
gen("subnatidsurvey", "", typ="float")
# Stata line 318
replace("subnatidsurvey", sadd(d[["subnatid1"]], " - Urban"), where=scmp(d[["urban"]], 1, "=="))
# Stata line 319
replace("subnatidsurvey", sadd(d[["subnatid1"]], " - Rural"), where=scmp(d[["urban"]], 0, "=="))
variable_labels[["subnatidsurvey"]] <- "Administrative level at which survey is representative"

# <_subnatid1_prev_>
# Stata line 330
gen("subnatid1_prev", NA_real_, typ="float")
variable_labels[["subnatid1_prev"]] <- "Classification used for subnatid1 from previous survey"

# <_subnatid2_prev_>
# Stata line 336
gen("subnatid2_prev", NA_real_, typ="float")
variable_labels[["subnatid2_prev"]] <- "Classification used for subnatid2 from previous survey"

# <_subnatid3_prev_>
# Stata line 342
gen("subnatid3_prev", NA_real_, typ="float")
variable_labels[["subnatid3_prev"]] <- "Classification used for subnatid3 from previous survey"

# <_gaul_adm1_code_>
# Stata line 348
gen("gaul_adm1_code", NA_real_, typ="float")
variable_labels[["gaul_adm1_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 1 code"

# <_gaul_adm2_code_>
# Stata line 354
gen("gaul_adm2_code", NA_real_, typ="float")
variable_labels[["gaul_adm2_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 2 code"

# <_gaul_adm3_code_>
# Stata line 360
gen("gaul_adm3_code", NA_real_, typ="float")
variable_labels[["gaul_adm3_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 3 code"

# <_hsize_>
# Stata line 374
gen("member_count", 1, typ="float", where=scmp(d[["s4c3"]], 8, "<"))
# Stata line 375
replace("member_count", 0, where=smissing(d[["member_count"]]))
# Stata line 376
gen("hsize", ave(d[["member_count"]], d[["hhid"]], FUN=function(x) sum(x,na.rm=TRUE)), typ="byte")

# <_age_>
# Stata line 394
gen("age", d[["s4c6"]], typ="float")
variable_labels[["age"]] <- "Individual age"

# <_male_>
# Stata line 400
gen("male", d[["s4c5"]], typ="float")
# Stata line 401
recode("male", list(list(ranges=list(c(2,2)), value=0)))
variable_labels[["male"]] <- "Sex - Ind is male"
label_defs[["lblmale"]] <- setNames(c(1, 0), c("Male", "Female"))
value_labels[["male"]] <- label_defs[["lblmale"]]

# <_relationharm_>
# Stata line 409
gen("relationharm", d[["s4c3"]], typ="float")
# Stata line 410
recode("relationharm", list(list(ranges=list(c(4,4)), value=3), list(ranges=list(c(5,5)), value=4), list(ranges=list(c(6,6), c(7,7)), value=5), list(ranges=list(c(8,8), c(9,9)), value=6)))
variable_labels[["relationharm"]] <- "Relationship to the head of household - Harmonized"
label_defs[["lblrelationharm"]] <- setNames(c(1, 2, 3, 4, 5, 6), c("Head of household", "Spouse", "Children", "Parents", "Other relatives", "Other and non-relatives"))
value_labels[["relationharm"]] <- label_defs[["lblrelationharm"]]
# Stata line 415
gen("lowest_rel", ave(d[["s4c3"]], d[["hhid"]], FUN=function(x) min(x,na.rm=TRUE)), typ="float")
# Stata line 416
gen("tot_heads", ave(scmp(d[["s4c3"]], 1, "=="), d[["hhid"]], FUN=function(x) sum(x,na.rm=TRUE)), typ="float")
stopifnot(all(scmp(d[["lowest_rel"]], 1, "==")))
stopifnot(all(scmp(d[["tot_heads"]], 1, "==")))

# <_relationcs_>
# Stata line 423
gen("relationcs", d[["s4c3"]], typ="float")
variable_labels[["relationcs"]] <- "Relationship to the head of household - Country original"

# <_marital_>
# Stata line 429
gen("marital", d[["s4c7"]], typ="byte")
# Stata line 430
recode("marital", list(list(ranges=list(c(2,2)), value=1), list(ranges=list(c(1,1)), value=2), list(ranges=list(c(3,3)), value=5)))
variable_labels[["marital"]] <- "Marital status"
label_defs[["lblmarital"]] <- setNames(c(1, 2, 3, 4, 5), c("Married", "Never Married", "Living together", "Divorced/Separated", "Widowed"))
value_labels[["marital"]] <- label_defs[["lblmarital"]]

# <_eye_dsablty_>
# Stata line 438
gen("eye_dsablty", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["eye_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["eye_dsablty"]] <- "Disability related to eyesight"

# <_hear_dsablty_>
# Stata line 446
gen("hear_dsablty", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["hear_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["hear_dsablty"]] <- "Disability related to hearing"

# <_walk_dsablty_>
# Stata line 454
gen("walk_dsablty", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["walk_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["walk_dsablty"]] <- "Disability related to walking or climbing stairs"

# <_conc_dsord_>
# Stata line 462
gen("conc_dsord", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["conc_dsord"]] <- label_defs[["dsablty"]]
variable_labels[["conc_dsord"]] <- "Disability related to concentration or remembering"

# <_slfcre_dsablty_>
# Stata line 470
gen("slfcre_dsablty", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["slfcre_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["slfcre_dsablty"]] <- "Disability related to selfcare"

# <_comm_dsablty_>
# Stata line 478
gen("comm_dsablty", NA_real_, typ="float")
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["comm_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["comm_dsablty"]] <- "Disability related to communicating"

# <_migrated_mod_age_>
# Stata line 495
gen("migrated_mod_age", 10, typ="float")
variable_labels[["migrated_mod_age"]] <- "Migration module application age"

# <_migrated_ref_time_>
# Stata line 501
gen("migrated_ref_time", 99, typ="float")
variable_labels[["migrated_ref_time"]] <- "Reference time applied to migration questions (in years)"

# <_migrated_binary_>
# Stata line 507
gen("migrated_binary", scond(scmp(d[["s4c15"]], 1, "=="), 0, 1), typ="float")
label_defs[["lblmigrated_binary"]] <- setNames(c(0, 1), c("No", "Yes"))
# Stata line 509
replace("migrated_binary", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
value_labels[["migrated_binary"]] <- label_defs[["lblmigrated_binary"]]
variable_labels[["migrated_binary"]] <- "Individual has migrated"

# <_migrated_years_>
# Stata line 528
gen("migrated_years", NA_real_, typ="float")
# Stata line 529
replace("migrated_years", 0.5, where=scmp(d[["s4c15"]], 2, "=="))
# Stata line 530
replace("migrated_years", (d[["s4c15"]] - 2), where=sinrange(d[["s4c15"]], 3, 6))
# Stata line 531
replace("migrated_years", 7.5, where=scmp(d[["s4c15"]], 7, "=="))
# Stata line 532
replace("migrated_years", 11, where=scmp(d[["s4c15"]], 8, "=="))
# Stata line 533
replace("migrated_years", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
# Stata line 534
replace("migrated_years", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
variable_labels[["migrated_years"]] <- "Years since latest migration"

# <_migrated_from_urban_>
# Stata line 540
gen("migrated_from_urban", d[["s4c17"]], typ="float")
# Stata line 541
recode("migrated_from_urban", list(list(ranges=list(c(0,0)), value=NA_real_), list(ranges=list(c(1,1)), value=0), list(ranges=list(c(2,2)), value=1)))
# Stata line 542
replace("migrated_from_urban", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
# Stata line 543
replace("migrated_from_urban", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
label_defs[["lblmigrated_from_urban"]] <- setNames(c(0, 1), c("Rural", "Urban"))
value_labels[["migrated_from_urban"]] <- label_defs[["lblmigrated_from_urban"]]
variable_labels[["migrated_from_urban"]] <- "Migrated from area"

# <_migrated_from_cat_>
# Stata line 557
gen("helper_mfc_1", sstring(floor((d[["s4c16"]] / 100))), typ="float", where=scmp(d[["s4c16"]], 1000, "<"))
# Stata line 558
gen("helper_mfc_2", ssubstr(d[["pcode"]], 1, 1), typ="float")
# Stata line 560
gen("migrated_from_cat", NA_real_, typ="float")
# Stata line 562
replace("migrated_from_cat", 3, where=scmp(d[["helper_mfc_1"]], d[["helper_mfc_2"]], "=="))
# Stata line 563
replace("migrated_from_cat", 4, where=((scmp(d[["helper_mfc_1"]], d[["helper_mfc_2"]], "!=") & scmp(d[["migrated_binary"]], 1, "==")) & scmp(d[["s4c16"]], 1000, "<")))
# Stata line 564
replace("migrated_from_cat", 5, where=(scmp(d[["s4c16"]], 999, ">") & (!smissing(d[["s4c16"]]))))
# Stata line 566
replace("migrated_from_cat", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
# Stata line 567
replace("migrated_from_cat", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
label_defs[["lblmigrated_from_cat"]] <- setNames(c(1, 2, 3, 4, 5), c("From same admin3 area", "From same admin2 area", "From same admin1 area", "From other admin1 area", "From other country"))
value_labels[["migrated_from_cat"]] <- label_defs[["lblmigrated_from_cat"]]
variable_labels[["migrated_from_cat"]] <- "Category of migration area"
drop_vars(c("helper_mfc_*"))

# <_migrated_from_code_>
# Stata line 576
gen("city_code", d[["s4c16"]], typ="float")
# Stata line 577
merge_lookup("city_code", migration)
# Stata line 578
replace("city_code", NA_real_, where=scmp(d[["_merge"]], 1, "=="))
d <- d[!(scmp(d[["_merge"]], 2, "==")), , drop=FALSE]
# Stata line 580
gen("migrated_from_code", d[["mapped_lfscode_24"]], typ="float", where=scmp(d[["migrated_binary"]], 1, "=="))
# Stata line 581
replace("migrated_from_code", NA_real_, where=scmp(d[["mapped_lfscode_24"]], 999, ">"))
# Stata line 582
replace("migrated_from_code", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
# Stata line 583
replace("migrated_from_code", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
drop_vars(c("_merge"))
variable_labels[["migrated_from_code"]] <- "Code of migration area as subnatid level of migrated_from_cat"

# <_migrated_from_country_>
# Stata line 590
merge_lookup("city_code", country)
d <- d[!(scmp(d[["_merge"]], 2, "==")), , drop=FALSE]
drop_vars(c("_merge"))
# Stata line 593
gen("migrated_from_country", d[["city_code"]], typ="float", where=(scmp(d[["country"]], 1, "==") & scmp(d[["migrated_binary"]], 1, "==")))
# Stata line 594
gen("country_name", d[["iso_code"]], typ="float", where=(scmp(d[["country"]], 1, "==") & scmp(d[["migrated_binary"]], 1, "==")))
# Stata line 595
labmask("migrated_from_country", "country_name")
# Stata line 596
replace("migrated_from_country", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
# Stata line 597
replace("migrated_from_country", NA_real_, where=scmp(d[["age"]], d[["migrated_mod_age"]], "<"))
variable_labels[["migrated_from_country"]] <- "Code of migration country (ISO 3 Letter Code)"

# <_migrated_reason_>
# Stata line 603
gen("migrated_reason", d[["s4c18"]], typ="float")
# Stata line 604
recode("migrated_reason", list(list(ranges=list(c(1,4), c(6,6)), value=3), list(ranges=list(c(5,5)), value=2), list(ranges=list(c(8,11)), value=1), list(ranges=list(c(14,16)), value=4), list(ranges=list(c(7,7), c(12,13), c(17,17)), value=5)))
# Stata line 605
replace("migrated_reason", NA_real_, where=scmp(d[["migrated_binary"]], 1, "!="))
label_defs[["lblmigrated_reason"]] <- setNames(c(1, 2, 3, 4, 5), c("Family reasons", "Educational reasons", "Employment", "Forced (political reasons, natural disaster, \u2026)", "Other reasons"))
value_labels[["migrated_reason"]] <- label_defs[["lblmigrated_reason"]]
variable_labels[["migrated_reason"]] <- "Reason for migrating"

# <_ed_mod_age_>
# Stata line 629
gen("ed_mod_age", 5, typ="byte")
variable_labels[["ed_mod_age"]] <- "Education module application age"

# <_school_>
# Stata line 635
gen("school", NA_real_, typ="byte")
# Stata line 636
replace("school", 0, where=scmp(d[["s4c10"]], 3, "<="))
# Stata line 637
replace("school", 1, where=(scmp(d[["s4c10"]], 3, ">") & scmp(d[["s4c10"]], NA_real_, "!=")))
variable_labels[["school"]] <- "Attending school"
label_defs[["lblschool"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["school"]] <- label_defs[["lblschool"]]

# <_literacy_>
# Stata line 645
gen("literacy", NA_real_, typ="byte")
# Stata line 646
replace("literacy", 1, where=(scmp(d[["s4c81"]], 1, "==") & scmp(d[["s4c82"]], 1, "==")))
# Stata line 647
replace("literacy", 0, where=((scmp(d[["literacy"]], 1, "!=") & (!smissing(d[["s4c81"]]))) & (!smissing(d[["s4c82"]]))))
variable_labels[["literacy"]] <- "Individual can read & write"
label_defs[["lblliteracy"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["literacy"]] <- label_defs[["lblliteracy"]]

# <_educy_>
# Stata line 655
gen("educy", NA_real_, typ="byte")
# Stata line 657
replace("educy", 0, where=scmp(d[["s4c9"]], 3, "<="))
# Stata line 658
replace("educy", 5, where=scmp(d[["s4c9"]], 4, "=="))
# Stata line 659
replace("educy", 8, where=scmp(d[["s4c9"]], 5, "=="))
# Stata line 660
replace("educy", 10, where=scmp(d[["s4c9"]], 6, "=="))
# Stata line 661
replace("educy", 12, where=scmp(d[["s4c9"]], 7, "=="))
# Stata line 662
replace("educy", 16, where=scmp(d[["s4c9"]], 8, "=="))
# Stata line 663
replace("educy", 17, where=scmp(d[["s4c9"]], 9, "=="))
# Stata line 664
replace("educy", 16, where=scmp(d[["s4c9"]], 10, "=="))
# Stata line 665
replace("educy", 16, where=scmp(d[["s4c9"]], 11, "=="))
# Stata line 666
replace("educy", 16, where=scmp(d[["s4c9"]], 12, "=="))
# Stata line 667
replace("educy", 19, where=scmp(d[["s4c9"]], 13, "=="))
# Stata line 668
replace("educy", 20, where=scmp(d[["s4c9"]], 14, "=="))
# Stata line 669
replace("educy", 22, where=scmp(d[["s4c9"]], 15, "=="))
variable_labels[["educy"]] <- "Years of education"

# <_educat7_>
# Stata line 675
gen("educat7", d[["s4c9"]], typ="byte")
# Stata line 676
recode("educat7", list(list(ranges=list(c(3,3)), value=2), list(ranges=list(c(4,4)), value=3), list(ranges=list(c(5,6)), value=4), list(ranges=list(c(8,16)), value=7)))
# Stata line 677
replace("educat7", 5, where=(scmp(d[["s4c9"]], 7, "==") & scmp(d[["s4c10"]], 1, "==")))
# Stata line 678
replace("educat7", 7, where=(scmp(d[["s4c9"]], 7, "==") & sinrange(d[["s4c10"]], 8, 15)))
# Stata line 679
replace("educat7", NA_real_, where=scmp(d[["age"]], d[["ed_mod_age"]], "<"))
variable_labels[["educat7"]] <- "Level of education 1"
label_defs[["lbleducat7"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7), c("No education", "Primary incomplete", "Primary complete", "Secondary incomplete", "Secondary complete", "Higher than secondary but not university", "University incomplete or complete"))
value_labels[["educat7"]] <- label_defs[["lbleducat7"]]

# <_educat5_>
# Stata line 687
gen("educat5", d[["educat7"]], typ="byte")
# Stata line 688
recode("educat5", list(list(ranges=list(c(4,4)), value=3), list(ranges=list(c(5,5)), value=4), list(ranges=list(c(6,6), c(7,7)), value=5)))
variable_labels[["educat5"]] <- "Level of education 2"
label_defs[["lbleducat5"]] <- setNames(c(1, 2, 3, 4, 5), c("No education", "Primary incomplete", "Primary complete but secondary incomplete", "Secondary complete", "Some tertiary/post-secondary"))
value_labels[["educat5"]] <- label_defs[["lbleducat5"]]

# <_educat4_>
# Stata line 696
gen("educat4", d[["educat7"]], typ="byte")
# Stata line 697
recode("educat4", list(list(ranges=list(c(2,2), c(3,3), c(4,4)), value=2), list(ranges=list(c(5,5)), value=3), list(ranges=list(c(6,6), c(7,7)), value=4)))
variable_labels[["educat4"]] <- "Level of education 3"
label_defs[["lbleducat4"]] <- setNames(c(1, 2, 3, 4), c("No education", "Primary", "Secondary", "Post-secondary"))
value_labels[["educat4"]] <- label_defs[["lbleducat4"]]

# <_educat_orig_>
# Stata line 705
gen("educat_orig", d[["s4c9"]], typ="float")
variable_labels[["educat_orig"]] <- "Original survey education code"

# <_educat_isced_>
# Stata line 711
gen("educat_isced", d[["s4c9"]], typ="float")
# Stata line 712
replace("educat_isced", NA_real_, where=(!sinrange(d[["s4c9"]], 1, 16)))
# Stata line 713
recode("educat_isced", list(list(ranges=list(c(1,1)), value=NA_real_), list(ranges=list(c(2,3)), value=20), list(ranges=list(c(3,3)), value=100), list(ranges=list(c(4,6)), value=244), list(ranges=list(c(7,7)), value=344), list(ranges=list(c(8,12)), value=660), list(ranges=list(c(13,14)), value=760), list(ranges=list(c(1516,1516)), value=860)))
# Stata line 714
replace("educat_isced", NA_real_, where=scmp(d[["age"]], d[["ed_mod_age"]], "<"))
variable_labels[["educat_isced"]] <- "ISCED standardised level of education"

# ----------6.1: Education cleanup------------------------------*

# <_% Correction min age_>
age_blank(c("school", "literacy", "educy", "educat7", "educat5", "educat4", "educat_orig", "educat_isced"), "ed_mod_age")

# <_vocational_>
# Stata line 751
gen("vocational", d[["s4c11"]], typ="float")
# Stata line 752
recode("vocational", list(list(ranges=list(c(1,3)), value=1), list(ranges=list(c(4,4)), value=0)))
# Stata line 753
replace("vocational", NA_real_, where=(!sinrange(d[["vocational"]], 0, 1)))
label_defs[["lblvocational"]] <- setNames(c(0, 1), c("No", "Yes"))
# Source attaches undefined value label vocationallbl to vocational; no labels exported.
variable_labels[["vocational"]] <- "Ever received vocational training"

# <_vocational_type_>
# Stata line 761
gen("vocational_type", d[["s4c11"]], typ="float")
# Stata line 762
recode("vocational_type", list(list(ranges=list(c(1,1)), value=1), list(ranges=list(c(2,2)), value=2)))
# Stata line 763
replace("vocational_type", NA_real_, where=(!sinrange(d[["vocational_type"]], 1, 2)))
label_defs[["lblvocational_type"]] <- setNames(c(1, 2), c("Inside Enterprise", "External"))
value_labels[["vocational_type"]] <- label_defs[["lblvocational_type"]]
variable_labels[["vocational_type"]] <- "Type of vocational training"

# <_vocational_length_l_>
# Stata line 778
gen("vocational_length_l", d[["s4c13"]], typ="float")
# Stata line 779
replace("vocational_length_l", (d[["vocational_length_l"]] / 4.2))
variable_labels[["vocational_length_l"]] <- "Length of training in months, lower limit"

# <_vocational_length_u_>
# Stata line 785
gen("vocational_length_u", d[["s4c13"]], typ="float")
# Stata line 786
replace("vocational_length_u", (d[["vocational_length_u"]] / 4.2))
variable_labels[["vocational_length_u"]] <- "Length of training in months, upper limit"

# <_vocational_field_orig_>
# Stata line 792
gen("code", d[["s4c12"]], typ="float")
# Stata line 793
merge_lookup("code", training)
d <- d[!(scmp(d[["_merge"]], 2, "==")), , drop=FALSE]
# Stata line 795
gen("vocational_field_orig", d[["code"]], typ="float")
# Stata line 796
labmask("vocational_field_orig", "training_field")
# Stata line 797
gen("vocational_field_str", decode("vocational_field_orig"), typ="string")
# Stata line 798
replace("vocational_field_str", sadd(sadd(sstring(d[["code"]]), " - "), d[["vocational_field_str"]]))
drop_vars(c("vocational_field_orig", "code", "_merge"))
names(d)[names(d)=="vocational_field_str"] <- "vocational_field_orig"; types[["vocational_field_orig"]] <- types[["vocational_field_str"]]
# Stata line 801
replace("vocational_field_orig", "", where=scmp(d[["vocational_field_orig"]], ". - ", "=="))
variable_labels[["vocational_field_orig"]] <- "Original field of training"

# <_vocational_financed_>
# Stata line 806
gen("vocational_financed", NA_real_, typ="float")
label_defs[["lblvocational_financed"]] <- setNames(c(1, 2, 3, 4, 5), c("Employer", "Government", "Mixed Employer/Government", "Own funds", "Other"))
variable_labels[["vocational_financed"]] <- "How training was financed"

# <_minlaborage_>
# Stata line 821
gen("minlaborage", 10, typ="byte")
variable_labels[["minlaborage"]] <- "Labor module application age"

# ----------8.1: 7 day reference overall------------------------------*

# <_lstatus_>
# Stata line 830
gen("lstatus", NA_real_, typ="byte")
# Stata line 834
replace("lstatus", 1, where=scmp(d[["s5c1"]], 1, "=="))
# Stata line 839
replace("lstatus", 1, where=((scmp(d[["s5c4"]], 1, "==") & (scmp(d[["s5c6"]], 1, "==") | scmp(d[["s5c7"]], 1, "=="))) & smissing(d[["lstatus"]])))
# Stata line 842
replace("lstatus", 1, where=(scmp(d[["s5c9"]], 4, "==") & smissing(d[["lstatus"]])))
# Stata line 845
replace("lstatus", 1, where=((sinrange(d[["s5c9"]], 1, 3) & sinrange(d[["s5c10"]], 1, 2)) & smissing(d[["lstatus"]])))
# Stata line 848
replace("lstatus", 1, where=((((((scmp(d[["s5c1"]], 2, "==") & scmp(d[["s5c2"]], 2, "==")) & scmp(d[["s5c3"]], 2, "==")) & scmp(d[["s5c4"]], 2, "==")) & sinrange(d[["s5c8"]], 1, 3)) & sinrange(d[["s5c10"]], 1, 2)) & smissing(d[["lstatus"]])))
# Stata line 853
replace("lstatus", 2, where=((scmp(d[["s9c1"]], 1, "==") & scmp(d[["s9c6"]], 1, "==")) & smissing(d[["lstatus"]])))
# Stata line 861
replace("lstatus", 3, where=(smissing(d[["lstatus"]]) & scmp(d[["age"]], d[["minlaborage"]], ">=")))
# Stata line 864
replace("lstatus", NA_real_, where=scmp(d[["age"]], d[["minlaborage"]], "<"))
variable_labels[["lstatus"]] <- "Labor status 7 day recall"
label_defs[["lbllstatus"]] <- setNames(c(1, 2, 3), c("Employed", "Unemployed", "Not in labor force"))
value_labels[["lstatus"]] <- label_defs[["lbllstatus"]]

# <_potential_lf_>
# Stata line 884
gen("potential_lf", NA_real_, typ="byte")
# Stata line 885
replace("potential_lf", 0, where=scmp(d[["lstatus"]], 3, "=="))
# Stata line 886
replace("potential_lf", 1, where=((scmp(d[["s9c1"]], 2, "==") & scmp(d[["s9c6"]], 1, "==")) | (scmp(d[["s9c1"]], 1, "==") & scmp(d[["s9c6"]], 2, "=="))))
# Stata line 887
replace("potential_lf", NA_real_, where=(scmp(d[["age"]], d[["minlaborage"]], "<") & (!smissing(d[["age"]]))))
# Stata line 888
replace("potential_lf", NA_real_, where=scmp(d[["lstatus"]], 3, "!="))
variable_labels[["potential_lf"]] <- "Potential labour force status"
label_defs[["lblpotential_lf"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["potential_lf"]] <- label_defs[["lblpotential_lf"]]

# <_underemployment_>
# Stata line 896
gen("underemployment", NA_real_, typ="byte")
# Stata line 897
replace("underemployment", 1, where=scmp(d[["s6c2"]], 1, "=="))
# Stata line 898
replace("underemployment", 0, where=scmp(d[["s6c2"]], 2, "=="))
# Stata line 899
replace("underemployment", NA_real_, where=scmp(d[["age"]], d[["minlaborage"]], "<"))
# Stata line 900
replace("underemployment", NA_real_, where=(scmp(d[["age"]], d[["minlaborage"]], "<") & (!smissing(d[["age"]]))))
# Stata line 901
replace("underemployment", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["underemployment"]] <- "Underemployment status"
label_defs[["lblunderemployment"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["underemployment"]] <- label_defs[["lblunderemployment"]]

# <_nlfreason_>
# Stata line 909
gen("nlfreason", NA_real_, typ="byte")
# Stata line 910
gen("nlfreason_1", d[["s9c9"]], typ="float", where=scmp(d[["lstatus"]], 3, "=="))
# Stata line 911
recode("nlfreason_1", list(list(ranges=list(c(7,7)), value=1), list(ranges=list(c(9,9)), value=2), list(ranges=list(c(10,11)), value=3), list(ranges=list(c(1,6), c(12,13)), value=5), list(ranges=list(c(8,8)), value=4)))
# Stata line 912
gen("nlfreason_2", d[["s9c5"]], typ="float", where=scmp(d[["lstatus"]], 3, "=="))
# Stata line 913
recode("nlfreason_2", list(list(ranges=list(c(9,9)), value=1), list(ranges=list(c(10,10)), value=2), list(ranges=list(c(12,12)), value=4), list(ranges=list(c(1,8), c(11,11), c(13,14)), value=5)))
# Stata line 914
replace("nlfreason", d[["nlfreason_1"]])
# Stata line 915
replace("nlfreason", d[["nlfreason_2"]], where=smissing(d[["nlfreason"]]))
# Stata line 916
replace("nlfreason", NA_real_, where=scmp(d[["lstatus"]], 3, "!="))
# Stata line 917
replace("nlfreason", 5, where=(scmp(d[["lstatus"]], 3, "==") & scmp(d[["nlfreason"]], NA_real_, "==")))
variable_labels[["nlfreason"]] <- "Reason not in the labor force"
label_defs[["lblnlfreason"]] <- setNames(c(1, 2, 3, 4, 5), c("Student", "Housekeeper", "Retired", "Disabled", "Other"))
value_labels[["nlfreason"]] <- label_defs[["lblnlfreason"]]

# <_unempldur_l_>
# Stata line 925
gen("unempldur_l", NA_real_, typ="byte")
# Stata line 926
replace("unempldur_l", d[["s9c3"]], where=scmp(d[["lstatus"]], 2, "=="))
# Stata line 927
recode("unempldur_l", list(list(ranges=list(c(1,1)), value=0), list(ranges=list(c(2,2)), value=1), list(ranges=list(c(3,3)), value=3), list(ranges=list(c(4,4)), value=6), list(ranges=list(c(5,5)), value=12)))
# Stata line 928
replace("unempldur_l", NA_real_, where=scmp(d[["lstatus"]], 1, "=="))
variable_labels[["unempldur_l"]] <- "Unemployment duration (months) lower bracket"

# <_unempldur_u_>
# Stata line 934
gen("unempldur_u", NA_real_, typ="byte")
# Stata line 935
replace("unempldur_u", d[["s9c3"]], where=scmp(d[["lstatus"]], 2, "=="))
# Stata line 936
recode("unempldur_u", list(list(ranges=list(c(1,1)), value=0), list(ranges=list(c(2,2)), value=3), list(ranges=list(c(3,3)), value=6), list(ranges=list(c(4,4)), value=12), list(ranges=list(c(5,5)), value=NA_real_)))
# Stata line 937
replace("unempldur_u", NA_real_, where=scmp(d[["lstatus"]], 1, "=="))
variable_labels[["unempldur_u"]] <- "Unemployment duration (months) upper bracket"

# ----------8.2: 7 day reference main job------------------------------*

# <_empstat_>
# Stata line 948
gen("empstat", d[["s5c11"]], typ="byte")
# Stata line 949
recode("empstat", list(list(ranges=list(c(3,3), c(5,5)), value=1), list(ranges=list(c(4,4)), value=2), list(ranges=list(c(1,1)), value=3), list(ranges=list(c(2,2)), value=4), list(ranges=list(c(6,6)), value=5)))
# Stata line 950
replace("empstat", NA_real_, where=(!sinrange(d[["s5c11"]], 1, 6)))
# Stata line 951
replace("empstat", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["empstat"]] <- "Employment status during past week primary job 7 day recall"
label_defs[["lblempstat"]] <- setNames(c(1, 2, 3, 4, 5), c("Paid employee", "Non-paid employee", "Employer", "Self-employed", "Other, workers not classifiable by status"))
value_labels[["empstat"]] <- label_defs[["lblempstat"]]

# <_ocusec_>
# Stata line 959
gen("ocusec", d[["s5c15"]], typ="byte")
# Stata line 960
recode("ocusec", list(list(ranges=list(c(1,3)), value=1), list(ranges=list(c(4,4)), value=3), list(ranges=list(c(5,10)), value=2), list(ranges=list(c(11,11)), value=4)))
# Stata line 961
replace("ocusec", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["ocusec"]] <- "Sector of activity primary job 7 day recall"
label_defs[["lblocusec"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec"]] <- label_defs[["lblocusec"]]

# <_industry_orig_>
# Stata line 969
gen("industry_orig", sstring(d[["s5c13"]], "%04.0f"), typ="float")
# Stata line 970
replace("industry_orig", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 971
replace("industry_orig", "", where=scmp(d[["industry_orig"]], ".", "=="))
variable_labels[["industry_orig"]] <- "Original survey industry code, main job 7 day recall"

# <_industrycat_isic_>
# Stata line 977
gen("industrycat_isic", d[["industry_orig"]], typ="float")
# Stata line 978
replace("industrycat_isic", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 979
replace("industrycat_isic", "", where=scmp(d[["industrycat_isic"]], ".", "=="))
universe_check("industrycat_isic", "ISIC")
variable_labels[["industrycat_isic"]] <- "ISIC code of primary job 7 day recall"

# <_industrycat10_>
# Stata line 996
gen("industrycat10", NA_real_, typ="byte")
# Stata line 997
replace("industrycat10", 1, where=sinrange(d[["industrycat_isic"]], "0100", "0399"))
# Stata line 998
replace("industrycat10", 2, where=sinrange(d[["industrycat_isic"]], "0500", "0999"))
# Stata line 999
replace("industrycat10", 3, where=sinrange(d[["industrycat_isic"]], "1000", "3399"))
# Stata line 1000
replace("industrycat10", 4, where=sinrange(d[["industrycat_isic"]], "3500", "3900"))
# Stata line 1001
replace("industrycat10", 5, where=sinrange(d[["industrycat_isic"]], "4100", "4399"))
# Stata line 1002
replace("industrycat10", 6, where=(sinrange(d[["industrycat_isic"]], "4500", "4799") | sinrange(d[["industrycat_isic"]], "5500", "5699")))
# Stata line 1003
replace("industrycat10", 7, where=(sinrange(d[["industrycat_isic"]], "4900", "5399") | sinrange(d[["industrycat_isic"]], "5800", "6399")))
# Stata line 1004
replace("industrycat10", 8, where=sinrange(d[["industrycat_isic"]], "6400", "8299"))
# Stata line 1005
replace("industrycat10", 9, where=sinrange(d[["industrycat_isic"]], "8400", "8499"))
# Stata line 1006
replace("industrycat10", 10, where=sinrange(d[["industrycat_isic"]], "8500", "9900"))
variable_labels[["industrycat10"]] <- "1 digit industry classification, primary job 7 day recall"
label_defs[["lblindustrycat10"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Agriculture", "Mining", "Manufacturing", "Public utilities", "Construction", "Commerce", "Transport and Comnunications", "Financial and Business Services", "Public Administration", "Other Services, Unspecified"))
value_labels[["industrycat10"]] <- label_defs[["lblindustrycat10"]]

# <_industrycat4_>
# Stata line 1015
gen("industrycat4", d[["industrycat10"]], typ="byte")
# Stata line 1016
recode("industrycat4", list(list(ranges=list(c(1,1)), value=1), list(ranges=list(c(2,2), c(3,3), c(4,4), c(5,5)), value=2), list(ranges=list(c(6,6), c(7,7), c(8,8), c(9,9)), value=3), list(ranges=list(c(10,10)), value=4)))
variable_labels[["industrycat4"]] <- "Broad Economic Activities classification, primary job 7 day recall"
label_defs[["lblindustrycat4"]] <- setNames(c(1, 2, 3, 4), c("Agriculture", "Industry", "Services", "Other"))
value_labels[["industrycat4"]] <- label_defs[["lblindustrycat4"]]

# <_occup_orig_>
# Stata line 1024
gen("occup_orig", sstring(d[["s5c12"]], "%04.0f"), typ="float")
# Stata line 1025
replace("occup_orig", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1026
replace("occup_orig", "", where=scmp(d[["industry_orig"]], ".", "=="))
variable_labels[["occup_orig"]] <- "Original occupation record primary job 7 day recall"

# <_occup_isco_>
# Stata line 1032
gen("occup_isco", d[["occup_orig"]], typ="float")
# Stata line 1033
replace("occup_isco", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1034
replace("occup_isco", "", where=scmp(d[["occup_isco"]], ".", "=="))
# Stata line 1037
replace("occup_isco", "4100", where=scmp(d[["occup_isco"]], "4140", "=="))
universe_check("occup_isco", "ISCO")
variable_labels[["occup_isco"]] <- "ISCO code of primary job 7 day recall"

# <_occup_>
# Stata line 1053
gen("occup", NA_real_, typ="byte")
# Stata line 1054
replace("occup", 1, where=sinrange(d[["occup_isco"]], "1000", "1999"))
# Stata line 1055
replace("occup", 2, where=sinrange(d[["occup_isco"]], "2000", "2999"))
# Stata line 1056
replace("occup", 3, where=sinrange(d[["occup_isco"]], "3000", "3999"))
# Stata line 1057
replace("occup", 4, where=sinrange(d[["occup_isco"]], "4000", "4999"))
# Stata line 1058
replace("occup", 5, where=sinrange(d[["occup_isco"]], "5000", "5999"))
# Stata line 1059
replace("occup", 6, where=sinrange(d[["occup_isco"]], "6000", "6999"))
# Stata line 1060
replace("occup", 7, where=sinrange(d[["occup_isco"]], "7000", "7999"))
# Stata line 1061
replace("occup", 8, where=sinrange(d[["occup_isco"]], "8000", "8999"))
# Stata line 1062
replace("occup", 9, where=sinrange(d[["occup_isco"]], "9000", "9999"))
# Stata line 1063
replace("occup", 10, where=sinrange(d[["occup_isco"]], "0000", "0999"))
variable_labels[["occup"]] <- "1 digit occupational classification, primary job 7 day recall"
label_defs[["lbloccup"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99), c("Managers", "Professionals", "Technicians", "Clerks", "Service and market sales workers", "Skilled agricultural", "Craft workers", "Machine operators", "Elementary occupations", "Armed forces", "Others"))
value_labels[["occup"]] <- label_defs[["lbloccup"]]

# <_occup_skill_>
# Stata line 1071
gen("occup_skill", d[["occup"]], typ="float")
# Stata line 1072
replace("occup_skill", 3, where=sinrange(d[["occup"]], 1, 3))
# Stata line 1073
replace("occup_skill", 2, where=sinrange(d[["occup"]], 4, 8))
# Stata line 1074
replace("occup_skill", 1, where=scmp(d[["occup"]], 9, "=="))
label_defs[["lblskill"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill"]] <- label_defs[["lblskill"]]
variable_labels[["occup_skill"]] <- "Skill based on ISCO standard primary job 7 day recall"

# <_wage_no_compen_>
# Stata line 1082
gen("last_week", d[["s7c33"]], typ="float")
# Stata line 1083
gen("last_month", d[["s7c43"]], typ="float")
# Stata line 1084
gen("last_year", d[["s7c9"]], typ="float")
# Stata line 1087
replace("last_week", NA_real_, where=scmp(d[["last_week"]], 0, "<="))
# Stata line 1088
replace("last_month", NA_real_, where=scmp(d[["last_month"]], 0, "<="))
# Stata line 1089
replace("last_year", NA_real_, where=scmp(d[["last_year"]], 0, "<="))
# Stata line 1092
replace("last_week", NA_real_, where=((!smissing(d[["last_week"]])) & (!smissing(d[["last_month"]]))))
# Stata line 1095
gen("wage_no_compen", {z<-as.matrix(d[c("last_week", "last_month", "last_year")]); x<-rowSums(z,na.rm=TRUE);x[rowSums(!is.na(z))==0]<-NA_real_;x}, typ="double")
# Stata line 1098
replace("wage_no_compen", NA_real_, where=scmp(d[["empstat"]], 2, "=="))
# Stata line 1099
replace("wage_no_compen", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["wage_no_compen"]] <- "Last wage payment primary job 7 day recall"
drop_vars(c("last_week", "last_month", "last_year"))

# <_unitwage_>
# Stata line 1113
gen("unitwage", NA_real_, typ="byte")
# Stata line 1114
replace("unitwage", 2, where=(((!smissing(d[["s7c33"]])) & scmp(d[["s7c33"]], 0, ">")) & scmp(d[["lstatus"]], 1, "==")))
# Stata line 1115
replace("unitwage", 5, where=(((!smissing(d[["s7c43"]])) & scmp(d[["s7c43"]], 0, ">")) & scmp(d[["lstatus"]], 1, "==")))
# Stata line 1116
replace("unitwage", 8, where=(((((!smissing(d[["s7c9"]])) & scmp(d[["s7c9"]], 0, ">")) & scmp(d[["lstatus"]], 1, "==")) & smissing(d[["s7c43"]])) & smissing(d[["s7c33"]])))
# Stata line 1118
replace("unitwage", NA_real_, where=scmp(d[["empstat"]], 2, "=="))
# Stata line 1119
replace("unitwage", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["unitwage"]] <- "Last wages' time unit primary job 7 day recall"
label_defs[["lblunitwage"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Daily", "Weekly", "Every two weeks", "Bimonthly", "Monthly", "Trimester", "Biannual", "Annually", "Hourly", "Other"))
value_labels[["unitwage"]] <- label_defs[["lblunitwage"]]

# <_whours_>
# Stata line 1130
gen("whours", NA_real_, typ="float")
# Stata line 1131
replace("whours", d[["s5c24"]], where=scmp(d[["lstatus"]], 1, "=="))
# Stata line 1132
replace("whours", NA_real_, where=(scmp(d[["whours"]], 0, "==") & scmp(d[["lstatus"]], 1, "==")))
variable_labels[["whours"]] <- "Hours of work in last week primary job 7 day recall"

# <_wmonths_>
# Stata line 1138
gen("wmonths", NA_real_, typ="float")
# Stata line 1139
replace("wmonths", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["wmonths"]] <- "Months of work in past 12 months primary job 7 day recall"

# <_wage_total_>
# Stata line 1151
gen("wage_total", NA_real_, typ="float")
variable_labels[["wage_total"]] <- "Annualized total wage primary job 7 day recall"

# <_contract_>
# Stata line 1157
gen("contract", NA_real_, typ="byte")
# Stata line 1158
replace("contract", d[["s7c1"]], where=scmp(d[["lstatus"]], 1, "=="))
# Stata line 1159
recode("contract", list(list(ranges=list(c(1,6)), value=1), list(ranges=list(c(7,7)), value=0)))
variable_labels[["contract"]] <- "Employment has contract primary job 7 day recall"
label_defs[["lblcontract"]] <- setNames(c(0, 1), c("Without contract", "With contract"))
value_labels[["contract"]] <- label_defs[["lblcontract"]]

# <_healthins_>
# Stata line 1167
gen("healthins", NA_real_, typ="byte")
variable_labels[["healthins"]] <- "Employment has health insurance primary job 7 day recall"
label_defs[["lblhealthins"]] <- setNames(c(0, 1), c("Without health insurance", "With health insurance"))
value_labels[["healthins"]] <- label_defs[["lblhealthins"]]

# <_socialsec_>
# Stata line 1175
gen("socialsec", 0, typ="byte")
# Stata line 1176
replace("socialsec", 1, where=(scmp(d[["s7c61"]], 1, "==") | scmp(d[["s7c64"]], 4, "==")))
# Stata line 1177
replace("socialsec", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["socialsec"]] <- "Employment has social security insurance primary job 7 day recall"
label_defs[["lblsocialsec"]] <- setNames(c(1, 0), c("With social security", "Without social secturity"))
value_labels[["socialsec"]] <- label_defs[["lblsocialsec"]]

# <_union_>
# Stata line 1185
gen("union", NA_real_, typ="byte")
# Stata line 1186
replace("union", 1, where=scmp(d[["s5c20"]], 1, "=="))
# Stata line 1187
replace("union", 0, where=(scmp(d[["s5c20"]], 2, "==") | scmp(d[["s5c20"]], 3, "==")))
# Stata line 1188
replace("union", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["union"]] <- "Union membership at primary job 7 day recall"
label_defs[["lblunion"]] <- setNames(c(0, 1), c("Not union member", "Union member"))
value_labels[["union"]] <- label_defs[["lblunion"]]

# <_firmsize_l_>
# Stata line 1196
gen("firmsize_l", d[["s5c18"]], typ="float")
# Stata line 1197
replace("firmsize_l", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["firmsize_l"]] <- "Firm size (lower bracket) primary job 7 day recall"

# <_firmsize_u_>
# Stata line 1203
gen("firmsize_u", d[["s5c18"]], typ="float")
# Stata line 1204
replace("firmsize_u", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["firmsize_u"]] <- "Firm size (upper bracket) primary job 7 day recall"

# ----------8.3: 7 day reference secondary job------------------------------*

# <_empstat_2_>
# Stata line 1217
gen("empstat_2", d[["s5c26"]], typ="byte")
# Stata line 1218
recode("empstat_2", list(list(ranges=list(c(3,3), c(5,5)), value=1), list(ranges=list(c(4,4)), value=2), list(ranges=list(c(1,1)), value=3), list(ranges=list(c(2,2)), value=4), list(ranges=list(c(6,6)), value=5), list(ranges=list(c(0,0)), value=NA_real_)))
# Stata line 1219
replace("empstat_2", NA_real_, where=scmp(d[["s5c25"]], 1, "!="))
# Stata line 1220
replace("empstat_2", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["empstat_2"]] <- "Employment status during past week secondary job 7 day recall"
value_labels[["empstat_2"]] <- label_defs[["lblempstat"]]

# <_ocusec_2_>
# Stata line 1227
gen("ocusec_2", d[["s5c30"]], typ="byte")
# Stata line 1228
recode("ocusec_2", list(list(ranges=list(c(1,3)), value=1), list(ranges=list(c(4,4)), value=3), list(ranges=list(c(5,10)), value=2), list(ranges=list(c(11,11)), value=4)))
# Stata line 1229
replace("ocusec_2", NA_real_, where=scmp(d[["s5c25"]], 1, "!="))
# Stata line 1230
replace("ocusec_2", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["ocusec_2"]] <- "Sector of activity secondary job 7 day recall"
value_labels[["ocusec_2"]] <- label_defs[["lblocusec"]]

# <_industry_orig_2_>
# Stata line 1237
gen("industry_orig_2", sstring(d[["s5c28"]], "%04.0f"), typ="float")
# Stata line 1238
replace("industry_orig_2", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1239
replace("industry_orig_2", "", where=scmp(d[["industry_orig"]], ".", "=="))
variable_labels[["industry_orig_2"]] <- "Original survey industry code, secondary job 7 day recall"

# <_industrycat_isic_2_>
# Stata line 1246
gen("industrycat_isic_2", d[["industry_orig_2"]], typ="float")
# Stata line 1247
replace("industrycat_isic_2", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1248
replace("industrycat_isic_2", "", where=scmp(d[["industrycat_isic_2"]], ".", "=="))
# Stata line 1249
replace("industrycat_isic_2", "", where=smissing(d[["empstat_2"]]))
# Stata line 1250
replace("industrycat_isic_2", "0320", where=scmp(d[["industry_orig_2"]], "320", "=="))
# Stata line 1252
replace("industrycat_isic_2", "6120", where=scmp(d[["industry_orig_2"]], "6121", "=="))
universe_check("industrycat_isic_2", "ISIC")
variable_labels[["industrycat_isic_2"]] <- "ISIC code of secondary job 7 day recall"

# <_industrycat10_2_>
# Stata line 1267
gen("industrycat10_2", NA_real_, typ="byte")
# Stata line 1268
replace("industrycat10_2", 1, where=sinrange(d[["industrycat_isic_2"]], "0100", "0399"))
# Stata line 1269
replace("industrycat10_2", 2, where=sinrange(d[["industrycat_isic_2"]], "0500", "0999"))
# Stata line 1270
replace("industrycat10_2", 3, where=sinrange(d[["industrycat_isic_2"]], "1000", "3399"))
# Stata line 1271
replace("industrycat10_2", 4, where=sinrange(d[["industrycat_isic_2"]], "3500", "3900"))
# Stata line 1272
replace("industrycat10_2", 5, where=sinrange(d[["industrycat_isic_2"]], "4100", "4399"))
# Stata line 1273
replace("industrycat10_2", 6, where=(sinrange(d[["industrycat_isic_2"]], "4500", "4799") | sinrange(d[["industrycat_isic_2"]], "5500", "5699")))
# Stata line 1274
replace("industrycat10_2", 7, where=(sinrange(d[["industrycat_isic_2"]], "4900", "5399") | sinrange(d[["industrycat_isic_2"]], "5800", "6399")))
# Stata line 1275
replace("industrycat10_2", 8, where=sinrange(d[["industrycat_isic_2"]], "6400", "8299"))
# Stata line 1276
replace("industrycat10_2", 9, where=sinrange(d[["industrycat_isic_2"]], "8400", "8499"))
# Stata line 1277
replace("industrycat10_2", 10, where=sinrange(d[["industrycat_isic_2"]], "8500", "9900"))
variable_labels[["industrycat10_2"]] <- "1 digit industry classification, secondary job 7 day recall"
value_labels[["industrycat10_2"]] <- label_defs[["lblindustrycat10"]]

# <_industrycat4_2_>
# Stata line 1284
gen("industrycat4_2", d[["industrycat10_2"]], typ="byte")
# Stata line 1285
recode("industrycat4_2", list(list(ranges=list(c(1,1)), value=1), list(ranges=list(c(2,2), c(3,3), c(4,4), c(5,5)), value=2), list(ranges=list(c(6,6), c(7,7), c(8,8), c(9,9)), value=3), list(ranges=list(c(10,10)), value=4)))
variable_labels[["industrycat4_2"]] <- "Broad Economic Activities classification, secondary job 7 day recall"
value_labels[["industrycat4_2"]] <- label_defs[["lblindustrycat4"]]

# <_occup_orig_2_>
# Stata line 1292
gen("occup_orig_2", sstring(d[["s5c27"]], "%04.0f"), typ="float")
# Stata line 1293
replace("occup_orig_2", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1294
replace("occup_orig_2", "", where=scmp(d[["industry_orig"]], ".", "=="))
variable_labels[["occup_orig_2"]] <- "Original occupation record secondary job 7 day recall"

# <_occup_isco_2_>
# Stata line 1300
gen("occup_isco_2", d[["occup_orig_2"]], typ="float")
# Stata line 1301
replace("occup_isco_2", "", where=scmp(d[["lstatus"]], 1, "!="))
# Stata line 1302
replace("occup_isco_2", "", where=scmp(d[["occup_isco_2"]], ".", "=="))
# Stata line 1305
replace("occup_isco_2", "4100", where=scmp(d[["occup_isco_2"]], "4140", "=="))
# Stata line 1306
replace("occup_isco_2", "2300", where=scmp(d[["occup_isco_2"]], "2333", "=="))
# Stata line 1307
replace("occup_isco_2", "9500", where=scmp(d[["occup_isco_2"]], "9516", "=="))
universe_check("occup_isco_2", "ISCO")
variable_labels[["occup_isco_2"]] <- "ISCO code of secondary job 7 day recall"

# <_occup_2_>
# Stata line 1322
gen("occup_2", NA_real_, typ="byte")
# Stata line 1323
replace("occup_2", 1, where=sinrange(d[["occup_isco_2"]], "1000", "1999"))
# Stata line 1324
replace("occup_2", 2, where=sinrange(d[["occup_isco_2"]], "2000", "2999"))
# Stata line 1325
replace("occup_2", 3, where=sinrange(d[["occup_isco_2"]], "3000", "3999"))
# Stata line 1326
replace("occup_2", 4, where=sinrange(d[["occup_isco_2"]], "4000", "4999"))
# Stata line 1327
replace("occup_2", 5, where=sinrange(d[["occup_isco_2"]], "5000", "5999"))
# Stata line 1328
replace("occup_2", 6, where=sinrange(d[["occup_isco_2"]], "6000", "6999"))
# Stata line 1329
replace("occup_2", 7, where=sinrange(d[["occup_isco_2"]], "7000", "7999"))
# Stata line 1330
replace("occup_2", 8, where=sinrange(d[["occup_isco_2"]], "8000", "8999"))
# Stata line 1331
replace("occup_2", 9, where=sinrange(d[["occup_isco_2"]], "9000", "9999"))
# Stata line 1332
replace("occup_2", 10, where=sinrange(d[["occup_isco_2"]], "0000", "0999"))
variable_labels[["occup_2"]] <- "1 digit occupational classification secondary job 7 day recall"
value_labels[["occup_2"]] <- label_defs[["lbloccup"]]

# <_occup_skill_2_>
# Stata line 1339
gen("occup_skill_2", NA_real_, typ="float")
# Stata line 1340
replace("occup_skill_2", 3, where=sinrange(d[["occup_2"]], 1, 3))
# Stata line 1341
replace("occup_skill_2", 2, where=sinrange(d[["occup_2"]], 4, 8))
# Stata line 1342
replace("occup_skill_2", 1, where=scmp(d[["occup_2"]], 9, "=="))
label_defs[["lblskill2"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_2"]] <- label_defs[["lblskill2"]]
variable_labels[["occup_skill_2"]] <- "Skill based on ISCO standard secondary job 7 day recall"

# <_wage_no_compen_2_>
# Stata line 1350
gen("wage_no_compen_2", NA_real_, typ="double")
variable_labels[["wage_no_compen_2"]] <- "Last wage payment secondary job 7 day recall"

# <_unitwage_2_>
# Stata line 1356
gen("unitwage_2", NA_real_, typ="byte")
variable_labels[["unitwage_2"]] <- "Last wages' time unit secondary job 7 day recall"
value_labels[["unitwage_2"]] <- label_defs[["lblunitwage"]]

# <_whours_2_>
# Stata line 1363
gen("whours_2", d[["s5c35"]], typ="float")
# Stata line 1364
replace("whours_2", NA_real_, where=scmp(d[["s5c25"]], 1, "!="))
variable_labels[["whours_2"]] <- "Hours of work in last week secondary job 7 day recall"

# <_wmonths_2_>
# Stata line 1370
gen("wmonths_2", NA_real_, typ="float")
variable_labels[["wmonths_2"]] <- "Months of work in past 12 months secondary job 7 day recall"

# <_wage_total_2_>
# Stata line 1376
gen("wage_total_2", NA_real_, typ="float")
variable_labels[["wage_total_2"]] <- "Annualized total wage secondary job 7 day recall"

# <_firmsize_l_2_>
# Stata line 1382
gen("firmsize_l_2", d[["s5c33"]], typ="float")
# Stata line 1383
replace("firmsize_l_2", NA_real_, where=(scmp(d[["s5c25"]], 1, "!=") | scmp(d[["s5c33"]], 0, "==")))
variable_labels[["firmsize_l_2"]] <- "Firm size (lower bracket) secondary job 7 day recall"

# <_firmsize_u_2_>
# Stata line 1389
gen("firmsize_u_2", d[["s5c33"]], typ="float")
# Stata line 1390
replace("firmsize_l_2", NA_real_, where=(scmp(d[["s5c25"]], 1, "!=") | scmp(d[["s5c33"]], 0, "==")))
variable_labels[["firmsize_u_2"]] <- "Firm size (upper bracket) secondary job 7 day recall"

# ----------8.4: 7 day reference additional jobs------------------------------*

# <_t_hours_others_>
# Stata line 1399
gen("t_hours_others", NA_real_, typ="float")
variable_labels[["t_hours_others"]] <- "Annualized hours worked in all but primary and secondary jobs 7 day recall"

# <_t_wage_nocompen_others_>
# Stata line 1405
gen("t_wage_nocompen_others", NA_real_, typ="float")
variable_labels[["t_wage_nocompen_others"]] <- "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_others_>
# Stata line 1411
gen("t_wage_others", NA_real_, typ="float")
variable_labels[["t_wage_others"]] <- "Annualized wage in all but primary and secondary jobs (12-mon ref period)"

# ----------8.5: 7 day reference total summary------------------------------*

# <_t_hours_total_>
# Stata line 1420
gen("t_hours_total", NA_real_, typ="float")
variable_labels[["t_hours_total"]] <- "Annualized hours worked in all jobs 7 day recall"

# <_t_wage_nocompen_total_>
# Stata line 1426
gen("t_wage_nocompen_total", NA_real_, typ="float")
variable_labels[["t_wage_nocompen_total"]] <- "Annualized wage in all jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_total_>
# Stata line 1432
gen("t_wage_total", NA_real_, typ="float")
variable_labels[["t_wage_total"]] <- "Annualized total wage for all jobs 7 day recall"

# ----------8.6: 12 month reference overall------------------------------*

# <_lstatus_year_>
# Stata line 1442
gen("lstatus_year", NA_real_, typ="byte")
# Stata line 1443
replace("lstatus_year", NA_real_, where=(scmp(d[["age"]], d[["minlaborage"]], "<") & (!smissing(d[["age"]]))))
variable_labels[["lstatus_year"]] <- "Labor status during last year"
label_defs[["lbllstatus_year"]] <- setNames(c(1, 2, 3), c("Employed", "Unemployed", "Non-LF"))
value_labels[["lstatus_year"]] <- label_defs[["lbllstatus_year"]]

# <_potential_lf_year_>
# Stata line 1450
gen("potential_lf_year", NA_real_, typ="byte")
# Stata line 1451
replace("potential_lf_year", NA_real_, where=(scmp(d[["age"]], d[["minlaborage"]], "<") & (!smissing(d[["age"]]))))
# Stata line 1452
replace("potential_lf_year", NA_real_, where=scmp(d[["lstatus_year"]], 3, "!="))
variable_labels[["potential_lf_year"]] <- "Potential labour force status"
label_defs[["lblpotential_lf_year"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["potential_lf_year"]] <- label_defs[["lblpotential_lf_year"]]

# <_underemployment_year_>
# Stata line 1460
gen("underemployment_year", NA_real_, typ="byte")
# Stata line 1461
replace("underemployment_year", NA_real_, where=(scmp(d[["age"]], d[["minlaborage"]], "<") & (!smissing(d[["age"]]))))
# Stata line 1462
replace("underemployment_year", NA_real_, where=scmp(d[["lstatus_year"]], 1, "=="))
variable_labels[["underemployment_year"]] <- "Underemployment status"
label_defs[["lblunderemployment_year"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["underemployment_year"]] <- label_defs[["lblunderemployment_year"]]

# <_nlfreason_year_>
# Stata line 1470
gen("nlfreason_year", NA_real_, typ="byte")
variable_labels[["nlfreason_year"]] <- "Reason not in the labor force"
label_defs[["lblnlfreason_year"]] <- setNames(c(1, 2, 3, 4, 5), c("Student", "Housekeeper", "Retired", "Disabled", "Other"))
value_labels[["nlfreason_year"]] <- label_defs[["lblnlfreason_year"]]

# <_unempldur_l_year_>
# Stata line 1478
gen("unempldur_l_year", NA_real_, typ="byte")
variable_labels[["unempldur_l_year"]] <- "Unemployment duration (months) lower bracket"

# <_unempldur_u_year_>
# Stata line 1484
gen("unempldur_u_year", NA_real_, typ="byte")
variable_labels[["unempldur_u_year"]] <- "Unemployment duration (months) upper bracket"

# ----------8.7: 12 month reference main job------------------------------*

# <_empstat_year_>
# Stata line 1495
gen("empstat_year", NA_real_, typ="byte")
variable_labels[["empstat_year"]] <- "Employment status during past week primary job 12 month recall"
label_defs[["lblempstat_year"]] <- setNames(c(1, 2, 3, 4, 5), c("Paid employee", "Non-paid employee", "Employer", "Self-employed", "Other, workers not classifiable by status"))
value_labels[["empstat_year"]] <- label_defs[["lblempstat_year"]]

# <_ocusec_year_>
# Stata line 1502
gen("ocusec_year", NA_real_, typ="byte")
variable_labels[["ocusec_year"]] <- "Sector of activity primary job 12 month recall"
label_defs[["lblocusec_year"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec_year"]] <- label_defs[["lblocusec_year"]]

# <_industry_orig_year_>
# Stata line 1509
gen("industry_orig_year", NA_real_, typ="float")
variable_labels[["industry_orig_year"]] <- "Original industry record main job 12 month recall"

# <_industrycat_isic_year_>
# Stata line 1515
gen("industrycat_isic_year", NA_real_, typ="float")
variable_labels[["industrycat_isic_year"]] <- "ISIC code of primary job 12 month recall"

# <_industrycat10_year_>
# Stata line 1531
gen("industrycat10_year", NA_real_, typ="byte")
variable_labels[["industrycat10_year"]] <- "1 digit industry classification, primary job 12 month recall"
label_defs[["lblindustrycat10_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Agriculture", "Mining", "Manufacturing", "Public utilities", "Construction", "Commerce", "Transport and Comnunications", "Financial and Business Services", "Public Administration", "Other Services, Unspecified"))
value_labels[["industrycat10_year"]] <- label_defs[["lblindustrycat10_year"]]

# <_industrycat4_year_>
# Stata line 1539
gen("industrycat4_year", d[["industrycat10_year"]], typ="byte")
# Stata line 1540
recode("industrycat4_year", list(list(ranges=list(c(1,1)), value=1), list(ranges=list(c(2,2), c(3,3), c(4,4), c(5,5)), value=2), list(ranges=list(c(6,6), c(7,7), c(8,8), c(9,9)), value=3), list(ranges=list(c(10,10)), value=4)))
variable_labels[["industrycat4_year"]] <- "Broad Economic Activities classification, primary job 12 month recall"
label_defs[["lblindustrycat4_year"]] <- setNames(c(1, 2, 3, 4), c("Agriculture", "Industry", "Services", "Other"))
value_labels[["industrycat4_year"]] <- label_defs[["lblindustrycat4_year"]]

# <_occup_orig_year_>
# Stata line 1548
gen("occup_orig_year", NA_real_, typ="float")
variable_labels[["occup_orig_year"]] <- "Original occupation record primary job 12 month recall"

# <_occup_isco_year_>
# Stata line 1554
gen("occup_isco_year", "", typ="float")
variable_labels[["occup_isco_year"]] <- "ISCO code of primary job 12 month recall"

# <_occup_year_>
# Stata line 1571
gen("occup_year", NA_real_, typ="byte")
variable_labels[["occup_year"]] <- "1 digit occupational classification, primary job 12 month recall"
label_defs[["lbloccup_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99), c("Managers", "Professionals", "Technicians", "Clerks", "Service and market sales workers", "Skilled agricultural", "Craft workers", "Machine operators", "Elementary occupations", "Armed forces", "Others"))
value_labels[["occup_year"]] <- label_defs[["lbloccup_year"]]

# <_occup_skill_year_>
# Stata line 1579
gen("occup_skill_year", NA_real_, typ="float")
# Stata line 1580
replace("occup_skill_year", 3, where=sinrange(d[["occup_year"]], 1, 3))
# Stata line 1581
replace("occup_skill_year", 2, where=sinrange(d[["occup_year"]], 4, 8))
# Stata line 1582
replace("occup_skill_year", 1, where=scmp(d[["occup_year"]], 9, "=="))
label_defs[["lblskillyear"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_year"]] <- label_defs[["lblskillyear"]]
variable_labels[["occup_skill_year"]] <- "Skill based on ISCO standard primary job 12 month recall"

# <_wage_no_compen_year_> --- this var has the same name as other and when quoted in the keep and order codes is repeated.
# Stata line 1590
gen("wage_no_compen_year", NA_real_, typ="double")
variable_labels[["wage_no_compen_year"]] <- "Last wage payment primary job 12 month recall"

# <_unitwage_year_>
# Stata line 1596
gen("unitwage_year", NA_real_, typ="byte")
variable_labels[["unitwage_year"]] <- "Last wages' time unit primary job 12 month recall"
label_defs[["lblunitwage_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Daily", "Weekly", "Every two weeks", "Bimonthly", "Monthly", "Trimester", "Biannual", "Annually", "Hourly", "Other"))
value_labels[["unitwage_year"]] <- label_defs[["lblunitwage_year"]]

# <_whours_year_>
# Stata line 1604
gen("whours_year", NA_real_, typ="float")
variable_labels[["whours_year"]] <- "Hours of work in last week primary job 12 month recall"

# <_wmonths_year_>
# Stata line 1610
gen("wmonths_year", NA_real_, typ="float")
variable_labels[["wmonths_year"]] <- "Months of work in past 12 months primary job 12 month recall"

# <_wage_total_year_>
# Stata line 1616
gen("wage_total_year", NA_real_, typ="float")
variable_labels[["wage_total_year"]] <- "Annualized total wage primary job 12 month recall"

# <_contract_year_>
# Stata line 1622
gen("contract_year", NA_real_, typ="byte")
variable_labels[["contract_year"]] <- "Employment has contract primary job 12 month recall"
label_defs[["lblcontract_year"]] <- setNames(c(0, 1), c("Without contract", "With contract"))
value_labels[["contract_year"]] <- label_defs[["lblcontract_year"]]

# <_healthins_year_>
# Stata line 1630
gen("healthins_year", NA_real_, typ="byte")
variable_labels[["healthins_year"]] <- "Employment has health insurance primary job 12 month recall"
label_defs[["lblhealthins_year"]] <- setNames(c(0, 1), c("Without health insurance", "With health insurance"))
value_labels[["healthins_year"]] <- label_defs[["lblhealthins_year"]]

# <_socialsec_year_>
# Stata line 1638
gen("socialsec_year", NA_real_, typ="byte")
variable_labels[["socialsec_year"]] <- "Employment has social security insurance primary job 7 day recall"
label_defs[["lblsocialsec_year"]] <- setNames(c(1, 0), c("With social security", "Without social secturity"))
value_labels[["socialsec_year"]] <- label_defs[["lblsocialsec_year"]]

# <_union_year_>
# Stata line 1646
gen("union_year", NA_real_, typ="byte")
variable_labels[["union_year"]] <- "Union membership at primary job 12 month recall"
label_defs[["lblunion_year"]] <- setNames(c(0, 1), c("Not union member", "Union member"))
value_labels[["union_year"]] <- label_defs[["lblunion_year"]]

# <_firmsize_l_year_>
# Stata line 1654
gen("firmsize_l_year", NA_real_, typ="float")
variable_labels[["firmsize_l_year"]] <- "Firm size (lower bracket) primary job 12 month recall"

# <_firmsize_u_year_>
# Stata line 1660
gen("firmsize_u_year", NA_real_, typ="float")
variable_labels[["firmsize_u_year"]] <- "Firm size (upper bracket) primary job 12 month recall"

# ----------8.8: 12 month reference secondary job------------------------------*

# <_empstat_2_year_>
# Stata line 1672
gen("empstat_2_year", NA_real_, typ="byte")
variable_labels[["empstat_2_year"]] <- "Employment status during past week secondary job 12 month recall"
value_labels[["empstat_2_year"]] <- label_defs[["lblempstat_year"]]

# <_ocusec_2_year_>
# Stata line 1679
gen("ocusec_2_year", NA_real_, typ="byte")
variable_labels[["ocusec_2_year"]] <- "Sector of activity secondary job 12 month recall"
label_defs[["lblocusec_2_year"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec_2_year"]] <- label_defs[["lblocusec_2_year"]]

# <_industry_orig_2_year_>
# Stata line 1688
gen("industry_orig_2_year", NA_real_, typ="float")
variable_labels[["industry_orig_2_year"]] <- "Original survey industry code, secondary job 12 month recall"

# <_industrycat_isic_2_year_>
# Stata line 1695
gen("industrycat_isic_2_year", NA_real_, typ="float")
variable_labels[["industrycat_isic_2_year"]] <- "ISIC code of secondary job 12 month recall"

# <_industrycat10_2_year_>
# Stata line 1701
gen("industrycat10_2_year", NA_real_, typ="byte")
variable_labels[["industrycat10_2_year"]] <- "1 digit industry classification, secondary job 12 month recall"
value_labels[["industrycat10_2_year"]] <- label_defs[["lblindustrycat10_year"]]

# <_industrycat4_2_year_>
# Stata line 1708
gen("industrycat4_2_year", d[["industrycat10_2_year"]], typ="byte")
# Stata line 1709
recode("industrycat4_2_year", list(list(ranges=list(c(1,1)), value=1), list(ranges=list(c(2,2), c(3,3), c(4,4), c(5,5)), value=2), list(ranges=list(c(6,6), c(7,7), c(8,8), c(9,9)), value=3), list(ranges=list(c(10,10)), value=4)))
variable_labels[["industrycat4_2_year"]] <- "Broad Economic Activities classification, secondary job 12 month recall"
value_labels[["industrycat4_2_year"]] <- label_defs[["lblindustrycat4_year"]]

# <_occup_orig_2_year_>
# Stata line 1716
gen("occup_orig_2_year", NA_real_, typ="float")
variable_labels[["occup_orig_2_year"]] <- "Original occupation record secondary job 12 month recall"

# <_occup_isco_2_year_>
# Stata line 1722
gen("occup_isco_2_year", "", typ="float")
variable_labels[["occup_isco_2_year"]] <- "ISCO code of secondary job 12 month recall"

# <_occup_2_year_>
# Stata line 1728
gen("occup_2_year", NA_real_, typ="byte")
variable_labels[["occup_2_year"]] <- "1 digit occupational classification, secondary job 12 month recall"
value_labels[["occup_2_year"]] <- label_defs[["lbloccup_year"]]

# <_occup_skill_2_year_>
# Stata line 1735
gen("occup_skill_2_year", NA_real_, typ="float")
# Stata line 1736
replace("occup_skill_2_year", 3, where=sinrange(d[["occup_2_year"]], 1, 3))
# Stata line 1737
replace("occup_skill_2_year", 2, where=sinrange(d[["occup_2_year"]], 4, 8))
# Stata line 1738
replace("occup_skill_2_year", 1, where=scmp(d[["occup_2_year"]], 9, "=="))
label_defs[["lblskilly2"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_2_year"]] <- label_defs[["lblskilly2"]]
variable_labels[["occup_skill_2_year"]] <- "Skill based on ISCO standard secondary job 12 month recall"

# <_wage_no_compen_2_year_>
# Stata line 1746
gen("wage_no_compen_2_year", NA_real_, typ="double")
variable_labels[["wage_no_compen_2_year"]] <- "Last wage payment secondary job 12 month recall"

# <_unitwage_2_year_>
# Stata line 1752
gen("unitwage_2_year", NA_real_, typ="byte")
variable_labels[["unitwage_2_year"]] <- "Last wages' time unit secondary job 12 month recall"
value_labels[["unitwage_2_year"]] <- label_defs[["lblunitwage_year"]]

# <_whours_2_year_>
# Stata line 1759
gen("whours_2_year", NA_real_, typ="float")
variable_labels[["whours_2_year"]] <- "Hours of work in last week secondary job 12 month recall"

# <_wmonths_2_year_>
# Stata line 1765
gen("wmonths_2_year", NA_real_, typ="float")
variable_labels[["wmonths_2_year"]] <- "Months of work in past 12 months secondary job 12 month recall"

# <_wage_total_2_year_>
# Stata line 1771
gen("wage_total_2_year", NA_real_, typ="float")
variable_labels[["wage_total_2_year"]] <- "Annualized total wage secondary job 12 month recall"

# <_firmsize_l_2_year_>
# Stata line 1776
gen("firmsize_l_2_year", NA_real_, typ="float")
variable_labels[["firmsize_l_2_year"]] <- "Firm size (lower bracket) secondary job 12 month recall"

# <_firmsize_u_2_year_>
# Stata line 1782
gen("firmsize_u_2_year", NA_real_, typ="float")
variable_labels[["firmsize_u_2_year"]] <- "Firm size (upper bracket) secondary job 12 month recall"

# ----------8.9: 12 month reference additional jobs------------------------------*

# <_t_hours_others_year_>
# Stata line 1793
gen("t_hours_others_year", NA_real_, typ="float")
variable_labels[["t_hours_others_year"]] <- "Annualized hours worked in all but primary and secondary jobs 12 month recall"

# <_t_wage_nocompen_others_year_>
# Stata line 1798
gen("t_wage_nocompen_others_year", NA_real_, typ="float")
variable_labels[["t_wage_nocompen_others_year"]] <- "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_others_year_>
# Stata line 1803
gen("t_wage_others_year", NA_real_, typ="float")
variable_labels[["t_wage_others_year"]] <- "Annualized wage in all but primary and secondary jobs 12 month recall"

# ----------8.10: 12 month total summary------------------------------*

# <_t_hours_total_year_>
# Stata line 1812
gen("t_hours_total_year", NA_real_, typ="float")
variable_labels[["t_hours_total_year"]] <- "Annualized hours worked in all jobs 12 month month recall"

# <_t_wage_nocompen_total_year_>
# Stata line 1818
gen("t_wage_nocompen_total_year", NA_real_, typ="float")
variable_labels[["t_wage_nocompen_total_year"]] <- "Annualized wage in all jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_total_year_>
# Stata line 1824
gen("t_wage_total_year", NA_real_, typ="float")
variable_labels[["t_wage_total_year"]] <- "Annualized total wage for all jobs 12 month recall"

# ----------8.11: Overall across reference periods------------------------------*

# <_njobs_>
# Stata line 1833
gen("njobs", NA_real_, typ="float")
# Stata line 1834
replace("njobs", 1, where=scmp(d[["s5c25"]], 2, "=="))
# Stata line 1835
replace("njobs", 2, where=(scmp(d[["s5c25"]], 1, "==") & scmp(d[["s5c36"]], 2, "==")))
# Stata line 1836
replace("njobs", 3, where=(scmp(d[["s5c25"]], 1, "==") & scmp(d[["s5c36"]], 1, "==")))
# Stata line 1837
replace("njobs", NA_real_, where=scmp(d[["lstatus"]], 1, "!="))
variable_labels[["njobs"]] <- "Total number of jobs"

# <_t_hours_annual_>
# Stata line 1843
gen("t_hours_annual", NA_real_, typ="float")
variable_labels[["t_hours_annual"]] <- "Total hours worked in all jobs in the previous 12 months"

# <_linc_nc_>
# Stata line 1849
gen("linc_nc", NA_real_, typ="float")
variable_labels[["linc_nc"]] <- "Total annual wage income in all jobs, excl. bonuses, etc."

# <_laborincome_>
# Stata line 1855
gen("laborincome", d[["t_wage_total_year"]], typ="float")
variable_labels[["laborincome"]] <- "Total annual individual labor income in all jobs, incl. bonuses, etc."

# ----------8.13: Labour cleanup------------------------------*

# <_% Correction min age_>
age_blank(c("minlaborage", "lstatus", "nlfreason", "unempldur_l", "unempldur_u", "empstat", "ocusec", "industry_orig", "industrycat_isic", "industrycat10", "industrycat4", "occup_orig", "occup_isco", "occup_skill", "occup", "wage_no_compen", "unitwage", "whours", "wmonths", "wage_total", "contract", "healthins", "socialsec", "union", "firmsize_l", "firmsize_u", "empstat_2", "ocusec_2", "industry_orig_2", "industrycat_isic_2", "industrycat10_2", "industrycat4_2", "occup_orig_2", "occup_isco_2", "occup_skill_2", "occup_2", "wage_no_compen_2", "unitwage_2", "whours_2", "wmonths_2", "wage_total_2", "firmsize_l_2", "firmsize_u_2", "t_hours_others", "t_wage_nocompen_others", "t_wage_others", "t_hours_total", "t_wage_nocompen_total", "t_wage_total", "lstatus_year", "nlfreason_year", "unempldur_l_year", "unempldur_u_year", "empstat_year", "ocusec_year", "industry_orig_year", "industrycat_isic_year", "industrycat10_year", "industrycat4_year", "occup_orig_year", "occup_isco_year", "occup_skill_year", "occup_year", "unitwage_year", "whours_year", "wmonths_year", "wage_total_year", "contract_year", "healthins_year", "socialsec_year", "union_year", "firmsize_l_year", "firmsize_u_year", "empstat_2_year", "ocusec_2_year", "industry_orig_2_year", "industrycat_isic_2_year", "industrycat10_2_year", "industrycat4_2_year", "occup_orig_2_year", "occup_isco_2_year", "occup_skill_2_year", "occup_2_year", "wage_no_compen_2_year", "unitwage_2_year", "whours_2_year", "wmonths_2_year", "wage_total_2_year", "firmsize_l_2_year", "firmsize_u_2_year", "t_hours_others_year", "t_wage_nocompen_others_year", "t_wage_others_year", "t_hours_total_year", "t_wage_nocompen_total_year", "t_wage_total_year", "njobs", "t_hours_annual", "linc_nc", "laborincome"), "minlaborage")

# <_% KEEP VARIABLES - ALL_>
# Stata line 1891
d <- d[c("countrycode", "survname", "survey", "icls_v", "isced_version", "isco_version", "isic_version", "year", "vermast", "veralt", "harmonization", "int_year", "int_month", "hhid", "pid", "weight", "weight_m", "weight_q", "psu", "ssu", "strata", "wave", "panel", "visit_no", "urban", "subnatid1", "subnatid2", "subnatid3", "subnatidsurvey", "subnatid1_prev", "subnatid2_prev", "subnatid3_prev", "gaul_adm1_code", "gaul_adm2_code", "gaul_adm3_code", "hsize", "age", "male", "relationharm", "relationcs", "marital", "eye_dsablty", "hear_dsablty", "walk_dsablty", "conc_dsord", "slfcre_dsablty", "comm_dsablty", "migrated_mod_age", "migrated_ref_time", "migrated_binary", "migrated_years", "migrated_from_urban", "migrated_from_cat", "migrated_from_code", "migrated_from_country", "migrated_reason", "ed_mod_age", "school", "literacy", "educy", "educat7", "educat5", "educat4", "educat_orig", "educat_isced", "vocational", "vocational_type", "vocational_length_l", "vocational_length_u", "vocational_field_orig", "vocational_financed", "minlaborage", "lstatus", "potential_lf", "underemployment", "nlfreason", "unempldur_l", "unempldur_u", "empstat", "ocusec", "industry_orig", "industrycat_isic", "industrycat10", "industrycat4", "occup_orig", "occup_isco", "occup_skill", "occup", "wage_no_compen", "unitwage", "whours", "wmonths", "wage_total", "contract", "healthins", "socialsec", "union", "firmsize_l", "firmsize_u", "empstat_2", "ocusec_2", "industry_orig_2", "industrycat_isic_2", "industrycat10_2", "industrycat4_2", "occup_orig_2", "occup_isco_2", "occup_skill_2", "occup_2", "wage_no_compen_2", "unitwage_2", "whours_2", "wmonths_2", "wage_total_2", "firmsize_l_2", "firmsize_u_2", "t_hours_others", "t_wage_nocompen_others", "t_wage_others", "t_hours_total", "t_wage_nocompen_total", "t_wage_total", "lstatus_year", "potential_lf_year", "underemployment_year", "nlfreason_year", "unempldur_l_year", "unempldur_u_year", "empstat_year", "ocusec_year", "industry_orig_year", "industrycat_isic_year", "industrycat10_year", "industrycat4_year", "occup_orig_year", "occup_isco_year", "occup_skill_year", "occup_year", "wage_no_compen_year", "unitwage_year", "whours_year", "wmonths_year", "wage_total_year", "contract_year", "healthins_year", "socialsec_year", "union_year", "firmsize_l_year", "firmsize_u_year", "empstat_2_year", "ocusec_2_year", "industry_orig_2_year", "industrycat_isic_2_year", "industrycat10_2_year", "industrycat4_2_year", "occup_orig_2_year", "occup_isco_2_year", "occup_skill_2_year", "occup_2_year", "wage_no_compen_2_year", "unitwage_2_year", "whours_2_year", "wmonths_2_year", "wage_total_2_year", "firmsize_l_2_year", "firmsize_u_2_year", "t_hours_others_year", "t_wage_nocompen_others_year", "t_wage_others_year", "t_hours_total_year", "t_wage_nocompen_total_year", "t_wage_total_year", "njobs", "t_hours_annual", "linc_nc", "laborincome")]

# <_% ORDER VARIABLES_>
# Stata line 1897
d <- d[c("countrycode", "survname", "survey", "icls_v", "isced_version", "isco_version", "isic_version", "year", "vermast", "veralt", "harmonization", "int_year", "int_month", "hhid", "pid", "weight", "weight_m", "weight_q", "psu", "ssu", "strata", "wave", "panel", "visit_no", "urban", "subnatid1", "subnatid2", "subnatid3", "subnatidsurvey", "subnatid1_prev", "subnatid2_prev", "subnatid3_prev", "gaul_adm1_code", "gaul_adm2_code", "gaul_adm3_code", "hsize", "age", "male", "relationharm", "relationcs", "marital", "eye_dsablty", "hear_dsablty", "walk_dsablty", "conc_dsord", "slfcre_dsablty", "comm_dsablty", "migrated_mod_age", "migrated_ref_time", "migrated_binary", "migrated_years", "migrated_from_urban", "migrated_from_cat", "migrated_from_code", "migrated_from_country", "migrated_reason", "ed_mod_age", "school", "literacy", "educy", "educat7", "educat5", "educat4", "educat_orig", "educat_isced", "vocational", "vocational_type", "vocational_length_l", "vocational_length_u", "vocational_field_orig", "vocational_financed", "minlaborage", "lstatus", "potential_lf", "underemployment", "nlfreason", "unempldur_l", "unempldur_u", "empstat", "ocusec", "industry_orig", "industrycat_isic", "industrycat10", "industrycat4", "occup_orig", "occup_isco", "occup_skill", "occup", "wage_no_compen", "unitwage", "whours", "wmonths", "wage_total", "contract", "healthins", "socialsec", "union", "firmsize_l", "firmsize_u", "empstat_2", "ocusec_2", "industry_orig_2", "industrycat_isic_2", "industrycat10_2", "industrycat4_2", "occup_orig_2", "occup_isco_2", "occup_skill_2", "occup_2", "wage_no_compen_2", "unitwage_2", "whours_2", "wmonths_2", "wage_total_2", "firmsize_l_2", "firmsize_u_2", "t_hours_others", "t_wage_nocompen_others", "t_wage_others", "t_hours_total", "t_wage_nocompen_total", "t_wage_total", "lstatus_year", "potential_lf_year", "underemployment_year", "nlfreason_year", "unempldur_l_year", "unempldur_u_year", "empstat_year", "ocusec_year", "industry_orig_year", "industrycat_isic_year", "industrycat10_year", "industrycat4_year", "occup_orig_year", "occup_isco_year", "occup_skill_year", "occup_year", "wage_no_compen_year", "unitwage_year", "whours_year", "wmonths_year", "wage_total_year", "contract_year", "healthins_year", "socialsec_year", "union_year", "firmsize_l_year", "firmsize_u_year", "empstat_2_year", "ocusec_2_year", "industry_orig_2_year", "industrycat_isic_2_year", "industrycat10_2_year", "industrycat4_2_year", "occup_orig_2_year", "occup_isco_2_year", "occup_skill_2_year", "occup_2_year", "wage_no_compen_2_year", "unitwage_2_year", "whours_2_year", "wmonths_2_year", "wage_total_2_year", "firmsize_l_2_year", "firmsize_u_2_year", "t_hours_others_year", "t_wage_nocompen_others_year", "t_wage_others_year", "t_hours_total_year", "t_wage_nocompen_total_year", "t_wage_total_year", "njobs", "t_hours_annual", "linc_nc", "laborincome")]

# <_% DROP UNUSED LABELS_>

# <_% DELETE MISSING VARIABLES_>

# <_% COMPRESS_>

# <_% SAVE_>

# 9. Drop wholly missing variables, as the Stata Recreator does.
d <- d[!vapply(d,function(x) all(smissing(x)), logical(1))]
for (nm in names(d)) {
  if (!is.null(value_labels[[nm]])) d[[nm]]<-haven::labelled(d[[nm]], value_labels[[nm]])
  if (!is.null(variable_labels[[nm]])) attr(d[[nm]],"label")<-variable_labels[[nm]]
}
filename<-file.path(output,"PAK_2024_LFS_V01_M_V01_A_GLD_RECREATED_R.dta")
haven::write_dta(d,filename,version=14)
cat("Saved",nrow(d),"records and",ncol(d),"variables:",basename(filename),"\n")

