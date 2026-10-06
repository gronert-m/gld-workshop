# Direct R translation of PAK_2024_LFS_V01_M_V01_A_GLD.do.
# The code follows the Stata program section by section using ordinary base R/haven
# statements. Project-specific int_classif_universe validation blocks are skipped.
if (!requireNamespace("haven", quietly=TRUE)) stop("Install the haven package before running.")

# 1.2 Set directories — direct translation of the Stata path logic.
username <- Sys.info()[["user"]]
if (username == "wb582017") {
  server <- file.path("C:/Users", username, "WBG", "GLD - 582018_AQ")
} else {
  server <- file.path("C:/Users", username, "WBG", "GLD - Current Contributors", "582018_AQ")
}

country <- "PAK"
year <- "2024"
survey <- "LFS"
vermast <- "V01"
veralt <- "V01"

level_1 <- paste(country, year, survey, sep="_")
level_2_mast <- paste(level_1, vermast, "M", sep="_")
level_2_harm <- paste(level_1, vermast, "M", veralt, "A", "GLD", sep="_")

path_in_stata <- file.path(server, country, level_1, level_2_mast, "Data", "Stata")
path_in_other <- file.path(server, country, level_1, level_2_mast, "Data", "Original")
path_output <- file.path(server, country, level_1, level_2_harm, "Data", "Harmonized")

if (username == "wb582018") {
  myroot <- file.path("C:/Users", username, "OneDrive - WBG", paste0("GLD - ", country))
  path_in_stata <- file.path(myroot, level_1, level_2_mast, "Data", "Stata")
  path_in_other <- file.path(myroot, level_1, level_2_mast, "Data", "Original")
  path_output <- file.path(myroot, level_1, level_2_harm, "Data", "Harmonized")
}

dir.create(path_output, recursive=TRUE, showWarnings=FALSE)

# The supplied Stata excerpt uses `out_file` at save time but does not define it.
# Set this to the same filename used by the full Stata program if it differs.
OUT_FILE <- "PAK_2024_LFS_V01_M_V01_A_GLD.dta"

variable_labels <- list(); label_defs <- list(); value_labels <- list()

# 1. Assemble inputs without overwriting the migration lookup or raw files.
d <- as.data.frame(haven::read_dta(file.path(path_in_stata, "LFS2024-25.sav.dta")))
names(d) <- tolower(names(d))
migration <- as.data.frame(haven::read_dta(file.path(path_in_stata, "append_lfs_districts.dta")))
names(migration)[names(migration)=="LFS24_Distcodes"]<-"city_code"
names(migration)[names(migration)=="LFS24_Distnames"]<-"city_name"
migration[c("samecode","sametext")]<-NULL; names(migration)<-tolower(names(migration))
country <- as.data.frame(haven::read_dta(file.path(path_in_stata, "PAK_country_code_2020.dta")))
training <- as.data.frame(haven::read_dta(file.path(path_in_stata, "PAK_training_code.dta")))

# Source SHA256: d568ed498594b5454c48da52240dade734c9df49a733a9b59e6dbc651ac4b4d9

# <_countrycode_>
# Stata line 104
d[["countrycode"]] <- "PAK"
variable_labels[["countrycode"]] <- "Country code"

# <_survname_>
# Stata line 110
d[["survname"]] <- "LFS"
variable_labels[["survname"]] <- "Survey acronym"

# <_survey_>
# Stata line 116
d[["survey"]] <- "LFS"
variable_labels[["survey"]] <- "Survey type"

# <_icls_v_>
# Stata line 122
d[["icls_v"]] <- "ICLS-19"
variable_labels[["icls_v"]] <- "ICLS version underlying questionnaire questions"

# <_isced_version_>
# Stata line 128
d[["isced_version"]] <- "isced_2011"
variable_labels[["isced_version"]] <- "Version of ISCED used for educat_isced"

# <_isco_version_>
# Stata line 134
d[["isco_version"]] <- "isco_2008"
variable_labels[["isco_version"]] <- "Version of ISCO used"

# <_isic_version_>
# Stata line 140
d[["isic_version"]] <- "isic_4"
variable_labels[["isic_version"]] <- "Version of ISIC used"

# <_year_>
# Stata line 146
d[["year"]] <- 2024
variable_labels[["year"]] <- "Year of survey"

# <_vermast_>
# Stata line 152
d[["vermast"]] <- "V01"
variable_labels[["vermast"]] <- "Version of master data"

# <_veralt_>
# Stata line 158
d[["veralt"]] <- "V01"
variable_labels[["veralt"]] <- "Version of the alt/harmonized data"

# <_harmonization_>
# Stata line 164
d[["harmonization"]] <- "GLD"
variable_labels[["harmonization"]] <- "Type of harmonization"

# <_int_year_>
# Stata line 170
d[["int_year"]] <- NA_real_
variable_labels[["int_year"]] <- "Year of the interview"

# <_int_month_>
# Stata line 176
d[["int_month"]] <- NA_real_
label_defs[["lblint_month"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"))
value_labels[["int_month"]] <- label_defs[["lblint_month"]]
variable_labels[["int_month"]] <- "Month of the interview"

# <_hhid_>
# Stata line 192
d[["hhno"]] <- ifelse(is.na(d[["hhno"]]), ".", sprintf("%02.0f", d[["hhno"]]))
# Stata line 193
d[["hhid"]] <- paste0(if(is.character(d[["pcode"]])) d[["pcode"]] else ifelse(is.na(d[["pcode"]]), ".", format(d[["pcode"]], scientific=FALSE, trim=TRUE, digits=9)), if(is.character(d[["hhno"]])) d[["hhno"]] else ifelse(is.na(d[["hhno"]]), ".", format(d[["hhno"]], scientific=FALSE, trim=TRUE, digits=9)))
variable_labels[["hhid"]] <- "Household ID"

# <_pid_>
# Stata line 199
d[["sno_str"]] <- d[["sno"]]
# Stata line 200
d[["sno_str"]] <- ifelse(is.na(d[["sno_str"]]), ".", sprintf("%02.0f", d[["sno_str"]]))
# Stata line 201
d[["pid"]] <- paste0(if(is.character(d[["hhid"]])) d[["hhid"]] else ifelse(is.na(d[["hhid"]]), ".", format(d[["hhid"]], scientific=FALSE, trim=TRUE, digits=9)), if(is.character(d[["sno"]])) d[["sno"]] else ifelse(is.na(d[["sno"]]), ".", format(d[["sno"]], scientific=FALSE, trim=TRUE, digits=9)))
variable_labels[["pid"]] <- "Individual ID"
stopifnot(!anyDuplicated(d[["pid"]]), !any((is.na(d[["pid"]]) | (is.character(d[["pid"]]) & as.character(d[["pid"]]) == ""))))

# <_weight_>
# Stata line 208
d[["weight"]] <- d[["weights"]]
variable_labels[["weight"]] <- "Survey sampling weight"

# <_weight_m_>
# Stata line 215
d[["weight_m"]] <- NA_real_
variable_labels[["weight_m"]] <- "Survey sampling weight to obtain national estimates for each month"

# <_weight_q_>
# Stata line 221
d[["weight_q"]] <- NA_real_
variable_labels[["weight_q"]] <- "Survey sampling weight to obtain national estimates for each quarter"

# <_psu_>
# Stata line 227
d[["psu"]] <- d[["pcode"]]
variable_labels[["psu"]] <- "Primary sampling units"

# <_ssu_>
# Stata line 233
d[["ssu"]] <- d[["hhid"]]
variable_labels[["ssu"]] <- "Secondary sampling units"

# <_strata_>
# Stata line 239
d[["strata"]] <- substr(d[["pcode"]], 1, 1 + 3 - 1)
# Stata line 240
d[["strata"]] <- as.numeric(d[["strata"]])
variable_labels[["strata"]] <- "Strata"

# <_wave_>
# Stata line 246
d[["wave"]] <- d[["quarter"]]
variable_labels[["wave"]] <- "Survey wave"

# <_panel_>
# Stata line 252
d[["panel"]] <- ""
variable_labels[["panel"]] <- "Panel individual belongs to"

# <_visit_no_>
# Stata line 258
d[["visit_no"]] <- NA_real_
variable_labels[["visit_no"]] <- "Visit number in panel"

# <_urban_>
# Stata line 272
d[["urban"]] <- d[["region"]]
# Stata line 273
.recode_source <- d[["urban"]]
d[["urban"]][(.recode_source == 1)] <- 0
d[["urban"]][(.recode_source == 2)] <- 1
rm(.recode_source)
variable_labels[["urban"]] <- "Location is urban"
label_defs[["lblurban"]] <- setNames(c(1, 0), c("Urban", "Rural"))
value_labels[["urban"]] <- label_defs[["lblurban"]]

# <_subnatid1_>
# Stata line 288
d[["subnatid1"]] <- ""
# Stata line 289
d[["subnatid1"]][(!is.na(d[["province"]]) & d[["province"]] == 1)] <- "1 - Khyber/Pakhtoonkhua"
# Stata line 290
d[["subnatid1"]][(!is.na(d[["province"]]) & d[["province"]] == 2)] <- "2 - Punjab"
# Stata line 291
d[["subnatid1"]][(!is.na(d[["province"]]) & d[["province"]] == 3)] <- "3 - Sindh"
# Stata line 292
d[["subnatid1"]][(!is.na(d[["province"]]) & d[["province"]] == 4)] <- "4 - Balochistan"
variable_labels[["subnatid1"]] <- "Subnational ID at First Administrative Level"

# <_subnatid2_>
# Stata line 298
d[["subnatid2"]] <- ""
variable_labels[["subnatid2"]] <- "Subnational ID at Second Administrative Level"

# <_subnatid3_>
# Stata line 304
d[["subnatid3"]] <- ""
variable_labels[["subnatid3"]] <- "Subnational ID at Third Administrative Level"

# <_subnatidsurvey_>
# Stata line 317
d[["subnatidsurvey"]] <- ""
# Stata line 318
d[["subnatidsurvey"]][(!is.na(d[["urban"]]) & d[["urban"]] == 1)] <- paste0(d[["subnatid1"]], " - Urban")
# Stata line 319
d[["subnatidsurvey"]][(!is.na(d[["urban"]]) & d[["urban"]] == 0)] <- paste0(d[["subnatid1"]], " - Rural")
variable_labels[["subnatidsurvey"]] <- "Administrative level at which survey is representative"

# <_subnatid1_prev_>
# Stata line 330
d[["subnatid1_prev"]] <- NA_real_
variable_labels[["subnatid1_prev"]] <- "Classification used for subnatid1 from previous survey"

# <_subnatid2_prev_>
# Stata line 336
d[["subnatid2_prev"]] <- NA_real_
variable_labels[["subnatid2_prev"]] <- "Classification used for subnatid2 from previous survey"

# <_subnatid3_prev_>
# Stata line 342
d[["subnatid3_prev"]] <- NA_real_
variable_labels[["subnatid3_prev"]] <- "Classification used for subnatid3 from previous survey"

# <_gaul_adm1_code_>
# Stata line 348
d[["gaul_adm1_code"]] <- NA_real_
variable_labels[["gaul_adm1_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 1 code"

# <_gaul_adm2_code_>
# Stata line 354
d[["gaul_adm2_code"]] <- NA_real_
variable_labels[["gaul_adm2_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 2 code"

# <_gaul_adm3_code_>
# Stata line 360
d[["gaul_adm3_code"]] <- NA_real_
variable_labels[["gaul_adm3_code"]] <- "Global Administrative Unit Layers (GAUL) Admin 3 code"

# <_hsize_>
# Stata line 374
d[["member_count"]] <- 1
d[["member_count"]][!((!is.na(d[["s4c3"]]) & d[["s4c3"]] < 8))] <- NA
# Stata line 375
d[["member_count"]][(is.na(d[["member_count"]]) | (is.character(d[["member_count"]]) & as.character(d[["member_count"]]) == ""))] <- 0
# Stata line 376
d[["hsize"]] <- ave(d[["member_count"]], d[["hhid"]], FUN=function(x) sum(x,na.rm=TRUE))

# <_age_>
# Stata line 394
d[["age"]] <- d[["s4c6"]]
variable_labels[["age"]] <- "Individual age"

# <_male_>
# Stata line 400
d[["male"]] <- d[["s4c5"]]
# Stata line 401
.recode_source <- d[["male"]]
d[["male"]][(.recode_source == 2)] <- 0
rm(.recode_source)
variable_labels[["male"]] <- "Sex - Ind is male"
label_defs[["lblmale"]] <- setNames(c(1, 0), c("Male", "Female"))
value_labels[["male"]] <- label_defs[["lblmale"]]

# <_relationharm_>
# Stata line 409
d[["relationharm"]] <- d[["s4c3"]]
# Stata line 410
.recode_source <- d[["relationharm"]]
d[["relationharm"]][(.recode_source == 4)] <- 3
d[["relationharm"]][(.recode_source == 5)] <- 4
d[["relationharm"]][(.recode_source == 6) | (.recode_source == 7)] <- 5
d[["relationharm"]][(.recode_source == 8) | (.recode_source == 9)] <- 6
rm(.recode_source)
variable_labels[["relationharm"]] <- "Relationship to the head of household - Harmonized"
label_defs[["lblrelationharm"]] <- setNames(c(1, 2, 3, 4, 5, 6), c("Head of household", "Spouse", "Children", "Parents", "Other relatives", "Other and non-relatives"))
value_labels[["relationharm"]] <- label_defs[["lblrelationharm"]]
# Stata line 415
d[["lowest_rel"]] <- ave(d[["s4c3"]], d[["hhid"]], FUN=function(x) min(x,na.rm=TRUE))
# Stata line 416
d[["tot_heads"]] <- ave((!is.na(d[["s4c3"]]) & d[["s4c3"]] == 1), d[["hhid"]], FUN=function(x) sum(x,na.rm=TRUE))
stopifnot(all((!is.na(d[["lowest_rel"]]) & d[["lowest_rel"]] == 1)))
stopifnot(all((!is.na(d[["tot_heads"]]) & d[["tot_heads"]] == 1)))

# <_relationcs_>
# Stata line 423
d[["relationcs"]] <- d[["s4c3"]]
variable_labels[["relationcs"]] <- "Relationship to the head of household - Country original"

# <_marital_>
# Stata line 429
d[["marital"]] <- d[["s4c7"]]
# Stata line 430
.recode_source <- d[["marital"]]
d[["marital"]][(.recode_source == 2)] <- 1
d[["marital"]][(.recode_source == 1)] <- 2
d[["marital"]][(.recode_source == 3)] <- 5
rm(.recode_source)
variable_labels[["marital"]] <- "Marital status"
label_defs[["lblmarital"]] <- setNames(c(1, 2, 3, 4, 5), c("Married", "Never Married", "Living together", "Divorced/Separated", "Widowed"))
value_labels[["marital"]] <- label_defs[["lblmarital"]]

# <_eye_dsablty_>
# Stata line 438
d[["eye_dsablty"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["eye_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["eye_dsablty"]] <- "Disability related to eyesight"

# <_hear_dsablty_>
# Stata line 446
d[["hear_dsablty"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["hear_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["hear_dsablty"]] <- "Disability related to hearing"

# <_walk_dsablty_>
# Stata line 454
d[["walk_dsablty"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["walk_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["walk_dsablty"]] <- "Disability related to walking or climbing stairs"

# <_conc_dsord_>
# Stata line 462
d[["conc_dsord"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["conc_dsord"]] <- label_defs[["dsablty"]]
variable_labels[["conc_dsord"]] <- "Disability related to concentration or remembering"

# <_slfcre_dsablty_>
# Stata line 470
d[["slfcre_dsablty"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["slfcre_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["slfcre_dsablty"]] <- "Disability related to selfcare"

# <_comm_dsablty_>
# Stata line 478
d[["comm_dsablty"]] <- NA_real_
label_defs[["dsablty"]] <- setNames(c(1, 2, 3, 4), c("No \u2013 no difficulty", "Yes \u2013 some difficulty", "Yes \u2013 a lot of difficulty", "Cannot do at all"))
value_labels[["comm_dsablty"]] <- label_defs[["dsablty"]]
variable_labels[["comm_dsablty"]] <- "Disability related to communicating"

# <_migrated_mod_age_>
# Stata line 495
d[["migrated_mod_age"]] <- 10
variable_labels[["migrated_mod_age"]] <- "Migration module application age"

# <_migrated_ref_time_>
# Stata line 501
d[["migrated_ref_time"]] <- 99
variable_labels[["migrated_ref_time"]] <- "Reference time applied to migration questions (in years)"

# <_migrated_binary_>
# Stata line 507
d[["migrated_binary"]] <- ifelse((!is.na(d[["s4c15"]]) & d[["s4c15"]] == 1), 0, 1)
label_defs[["lblmigrated_binary"]] <- setNames(c(0, 1), c("No", "Yes"))
# Stata line 509
d[["migrated_binary"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
value_labels[["migrated_binary"]] <- label_defs[["lblmigrated_binary"]]
variable_labels[["migrated_binary"]] <- "Individual has migrated"

# <_migrated_years_>
# Stata line 528
d[["migrated_years"]] <- NA_real_
# Stata line 529
d[["migrated_years"]][(!is.na(d[["s4c15"]]) & d[["s4c15"]] == 2)] <- 0.5
# Stata line 530
d[["migrated_years"]][(!is.na(d[["s4c15"]]) & d[["s4c15"]] >= 3 & d[["s4c15"]] <= 6)] <- (d[["s4c15"]] - 2)
# Stata line 531
d[["migrated_years"]][(!is.na(d[["s4c15"]]) & d[["s4c15"]] == 7)] <- 7.5
# Stata line 532
d[["migrated_years"]][(!is.na(d[["s4c15"]]) & d[["s4c15"]] == 8)] <- 11
# Stata line 533
d[["migrated_years"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
# Stata line 534
d[["migrated_years"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
variable_labels[["migrated_years"]] <- "Years since latest migration"

# <_migrated_from_urban_>
# Stata line 540
d[["migrated_from_urban"]] <- d[["s4c17"]]
# Stata line 541
.recode_source <- d[["migrated_from_urban"]]
d[["migrated_from_urban"]][(.recode_source == 0)] <- NA_real_
d[["migrated_from_urban"]][(.recode_source == 1)] <- 0
d[["migrated_from_urban"]][(.recode_source == 2)] <- 1
rm(.recode_source)
# Stata line 542
d[["migrated_from_urban"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
# Stata line 543
d[["migrated_from_urban"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
label_defs[["lblmigrated_from_urban"]] <- setNames(c(0, 1), c("Rural", "Urban"))
value_labels[["migrated_from_urban"]] <- label_defs[["lblmigrated_from_urban"]]
variable_labels[["migrated_from_urban"]] <- "Migrated from area"

# <_migrated_from_cat_>
# Stata line 557
d[["helper_mfc_1"]] <- ifelse(is.na(floor((d[["s4c16"]] / 100))), ".", format(floor((d[["s4c16"]] / 100)), scientific=FALSE, trim=TRUE, digits=9))
d[["helper_mfc_1"]][!((!is.na(d[["s4c16"]]) & d[["s4c16"]] < 1000))] <- NA
# Stata line 558
d[["helper_mfc_2"]] <- substr(d[["pcode"]], 1, 1 + 1 - 1)
# Stata line 560
d[["migrated_from_cat"]] <- NA_real_
# Stata line 562
d[["migrated_from_cat"]][(!is.na(d[["helper_mfc_1"]]) & d[["helper_mfc_1"]] == d[["helper_mfc_2"]])] <- 3
# Stata line 563
d[["migrated_from_cat"]][(((is.na(d[["helper_mfc_1"]]) | d[["helper_mfc_1"]] != d[["helper_mfc_2"]]) & (!is.na(d[["migrated_binary"]]) & d[["migrated_binary"]] == 1)) & (!is.na(d[["s4c16"]]) & d[["s4c16"]] < 1000))] <- 4
# Stata line 564
d[["migrated_from_cat"]][((is.na(d[["s4c16"]]) | d[["s4c16"]] > 999) & (!(is.na(d[["s4c16"]]) | (is.character(d[["s4c16"]]) & as.character(d[["s4c16"]]) == ""))))] <- 5
# Stata line 566
d[["migrated_from_cat"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
# Stata line 567
d[["migrated_from_cat"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
label_defs[["lblmigrated_from_cat"]] <- setNames(c(1, 2, 3, 4, 5), c("From same admin3 area", "From same admin2 area", "From same admin1 area", "From other admin1 area", "From other country"))
value_labels[["migrated_from_cat"]] <- label_defs[["lblmigrated_from_cat"]]
variable_labels[["migrated_from_cat"]] <- "Category of migration area"
.drop_cols <- unique(unlist(lapply(c("helper_mfc_*"), function(p) grep(glob2rx(p), names(d), value=TRUE))))
d[.drop_cols] <- NULL
rm(.drop_cols)

# <_migrated_from_code_>
# Stata line 576
d[["city_code"]] <- d[["s4c16"]]
# Stata line 577
if (anyDuplicated(migration[["city_code"]])) stop(paste("Nonunique lookup key:", "city_code"))
.idx <- match(d[["city_code"]], migration[["city_code"]])
for (.nm in setdiff(names(migration), names(d))) d[[.nm]] <- migration[[.nm]][.idx]
d[["_merge"]] <- ifelse(is.na(.idx), 1, 3)
rm(.idx, .nm)
# Stata line 578
d[["city_code"]][(!is.na(d[["_merge"]]) & d[["_merge"]] == 1)] <- NA_real_
d <- d[!((!is.na(d[["_merge"]]) & d[["_merge"]] == 2)), , drop=FALSE]
# Stata line 580
d[["migrated_from_code"]] <- d[["mapped_lfscode_24"]]
d[["migrated_from_code"]][!((!is.na(d[["migrated_binary"]]) & d[["migrated_binary"]] == 1))] <- NA
# Stata line 581
d[["migrated_from_code"]][(is.na(d[["mapped_lfscode_24"]]) | d[["mapped_lfscode_24"]] > 999)] <- NA_real_
# Stata line 582
d[["migrated_from_code"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
# Stata line 583
d[["migrated_from_code"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
.drop_cols <- unique(unlist(lapply(c("_merge"), function(p) grep(glob2rx(p), names(d), value=TRUE))))
d[.drop_cols] <- NULL
rm(.drop_cols)
variable_labels[["migrated_from_code"]] <- "Code of migration area as subnatid level of migrated_from_cat"

# <_migrated_from_country_>
# Stata line 590
if (anyDuplicated(country[["city_code"]])) stop(paste("Nonunique lookup key:", "city_code"))
.idx <- match(d[["city_code"]], country[["city_code"]])
for (.nm in setdiff(names(country), names(d))) d[[.nm]] <- country[[.nm]][.idx]
d[["_merge"]] <- ifelse(is.na(.idx), 1, 3)
rm(.idx, .nm)
d <- d[!((!is.na(d[["_merge"]]) & d[["_merge"]] == 2)), , drop=FALSE]
.drop_cols <- unique(unlist(lapply(c("_merge"), function(p) grep(glob2rx(p), names(d), value=TRUE))))
d[.drop_cols] <- NULL
rm(.drop_cols)
# Stata line 593
d[["migrated_from_country"]] <- d[["city_code"]]
d[["migrated_from_country"]][!(((!is.na(d[["country"]]) & d[["country"]] == 1) & (!is.na(d[["migrated_binary"]]) & d[["migrated_binary"]] == 1)))] <- NA
# Stata line 594
d[["country_name"]] <- d[["iso_code"]]
d[["country_name"]][!(((!is.na(d[["country"]]) & d[["country"]] == 1) & (!is.na(d[["migrated_binary"]]) & d[["migrated_binary"]] == 1)))] <- NA
# Stata line 595
.valid <- unique(d[!is.na(d[["migrated_from_country"]]) & d[["migrated_from_country"]] != "", c("migrated_from_country", "country_name")])
if (anyDuplicated(.valid[["migrated_from_country"]])) stop(paste("Conflicting labels for", "migrated_from_country"))
value_labels[["migrated_from_country"]] <- setNames(as.numeric(.valid[["migrated_from_country"]]), .valid[["country_name"]])
rm(.valid)
# Stata line 596
d[["migrated_from_country"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
# Stata line 597
d[["migrated_from_country"]][(!is.na(d[["age"]]) & d[["age"]] < d[["migrated_mod_age"]])] <- NA_real_
variable_labels[["migrated_from_country"]] <- "Code of migration country (ISO 3 Letter Code)"

# <_migrated_reason_>
# Stata line 603
d[["migrated_reason"]] <- d[["s4c18"]]
# Stata line 604
.recode_source <- d[["migrated_reason"]]
d[["migrated_reason"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 4) | (.recode_source == 6)] <- 3
d[["migrated_reason"]][(.recode_source == 5)] <- 2
d[["migrated_reason"]][(!is.na(.recode_source) & .recode_source >= 8 & .recode_source <= 11)] <- 1
d[["migrated_reason"]][(!is.na(.recode_source) & .recode_source >= 14 & .recode_source <= 16)] <- 4
d[["migrated_reason"]][(.recode_source == 7) | (!is.na(.recode_source) & .recode_source >= 12 & .recode_source <= 13) | (.recode_source == 17)] <- 5
rm(.recode_source)
# Stata line 605
d[["migrated_reason"]][(is.na(d[["migrated_binary"]]) | d[["migrated_binary"]] != 1)] <- NA_real_
label_defs[["lblmigrated_reason"]] <- setNames(c(1, 2, 3, 4, 5), c("Family reasons", "Educational reasons", "Employment", "Forced (political reasons, natural disaster, \u2026)", "Other reasons"))
value_labels[["migrated_reason"]] <- label_defs[["lblmigrated_reason"]]
variable_labels[["migrated_reason"]] <- "Reason for migrating"

# <_ed_mod_age_>
# Stata line 629
d[["ed_mod_age"]] <- 5
variable_labels[["ed_mod_age"]] <- "Education module application age"

# <_school_>
# Stata line 635
d[["school"]] <- NA_real_
# Stata line 636
d[["school"]][(!is.na(d[["s4c10"]]) & d[["s4c10"]] <= 3)] <- 0
# Stata line 637
d[["school"]][((is.na(d[["s4c10"]]) | d[["s4c10"]] > 3) & !is.na(d[["s4c10"]]))] <- 1
variable_labels[["school"]] <- "Attending school"
label_defs[["lblschool"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["school"]] <- label_defs[["lblschool"]]

# <_literacy_>
# Stata line 645
d[["literacy"]] <- NA_real_
# Stata line 646
d[["literacy"]][((!is.na(d[["s4c81"]]) & d[["s4c81"]] == 1) & (!is.na(d[["s4c82"]]) & d[["s4c82"]] == 1))] <- 1
# Stata line 647
d[["literacy"]][(((is.na(d[["literacy"]]) | d[["literacy"]] != 1) & (!(is.na(d[["s4c81"]]) | (is.character(d[["s4c81"]]) & as.character(d[["s4c81"]]) == "")))) & (!(is.na(d[["s4c82"]]) | (is.character(d[["s4c82"]]) & as.character(d[["s4c82"]]) == ""))))] <- 0
variable_labels[["literacy"]] <- "Individual can read & write"
label_defs[["lblliteracy"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["literacy"]] <- label_defs[["lblliteracy"]]

# <_educy_>
# Stata line 655
d[["educy"]] <- NA_real_
# Stata line 657
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] <= 3)] <- 0
# Stata line 658
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 4)] <- 5
# Stata line 659
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 5)] <- 8
# Stata line 660
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 6)] <- 10
# Stata line 661
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 7)] <- 12
# Stata line 662
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 8)] <- 16
# Stata line 663
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 9)] <- 17
# Stata line 664
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 10)] <- 16
# Stata line 665
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 11)] <- 16
# Stata line 666
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 12)] <- 16
# Stata line 667
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 13)] <- 19
# Stata line 668
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 14)] <- 20
# Stata line 669
d[["educy"]][(!is.na(d[["s4c9"]]) & d[["s4c9"]] == 15)] <- 22
variable_labels[["educy"]] <- "Years of education"

# <_educat7_>
# Stata line 675
d[["educat7"]] <- d[["s4c9"]]
# Stata line 676
.recode_source <- d[["educat7"]]
d[["educat7"]][(.recode_source == 3)] <- 2
d[["educat7"]][(.recode_source == 4)] <- 3
d[["educat7"]][(!is.na(.recode_source) & .recode_source >= 5 & .recode_source <= 6)] <- 4
d[["educat7"]][(!is.na(.recode_source) & .recode_source >= 8 & .recode_source <= 16)] <- 7
rm(.recode_source)
# Stata line 677
d[["educat7"]][((!is.na(d[["s4c9"]]) & d[["s4c9"]] == 7) & (!is.na(d[["s4c10"]]) & d[["s4c10"]] == 1))] <- 5
# Stata line 678
d[["educat7"]][((!is.na(d[["s4c9"]]) & d[["s4c9"]] == 7) & (!is.na(d[["s4c10"]]) & d[["s4c10"]] >= 8 & d[["s4c10"]] <= 15))] <- 7
# Stata line 679
d[["educat7"]][(!is.na(d[["age"]]) & d[["age"]] < d[["ed_mod_age"]])] <- NA_real_
variable_labels[["educat7"]] <- "Level of education 1"
label_defs[["lbleducat7"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7), c("No education", "Primary incomplete", "Primary complete", "Secondary incomplete", "Secondary complete", "Higher than secondary but not university", "University incomplete or complete"))
value_labels[["educat7"]] <- label_defs[["lbleducat7"]]

# <_educat5_>
# Stata line 687
d[["educat5"]] <- d[["educat7"]]
# Stata line 688
.recode_source <- d[["educat5"]]
d[["educat5"]][(.recode_source == 4)] <- 3
d[["educat5"]][(.recode_source == 5)] <- 4
d[["educat5"]][(.recode_source == 6) | (.recode_source == 7)] <- 5
rm(.recode_source)
variable_labels[["educat5"]] <- "Level of education 2"
label_defs[["lbleducat5"]] <- setNames(c(1, 2, 3, 4, 5), c("No education", "Primary incomplete", "Primary complete but secondary incomplete", "Secondary complete", "Some tertiary/post-secondary"))
value_labels[["educat5"]] <- label_defs[["lbleducat5"]]

# <_educat4_>
# Stata line 696
d[["educat4"]] <- d[["educat7"]]
# Stata line 697
.recode_source <- d[["educat4"]]
d[["educat4"]][(.recode_source == 2) | (.recode_source == 3) | (.recode_source == 4)] <- 2
d[["educat4"]][(.recode_source == 5)] <- 3
d[["educat4"]][(.recode_source == 6) | (.recode_source == 7)] <- 4
rm(.recode_source)
variable_labels[["educat4"]] <- "Level of education 3"
label_defs[["lbleducat4"]] <- setNames(c(1, 2, 3, 4), c("No education", "Primary", "Secondary", "Post-secondary"))
value_labels[["educat4"]] <- label_defs[["lbleducat4"]]

# <_educat_orig_>
# Stata line 705
d[["educat_orig"]] <- d[["s4c9"]]
variable_labels[["educat_orig"]] <- "Original survey education code"

# <_educat_isced_>
# Stata line 711
d[["educat_isced"]] <- d[["s4c9"]]
# Stata line 712
d[["educat_isced"]][(!(!is.na(d[["s4c9"]]) & d[["s4c9"]] >= 1 & d[["s4c9"]] <= 16))] <- NA_real_
# Stata line 713
.recode_source <- d[["educat_isced"]]
d[["educat_isced"]][(.recode_source == 1)] <- NA_real_
d[["educat_isced"]][(!is.na(.recode_source) & .recode_source >= 2 & .recode_source <= 3)] <- 20
d[["educat_isced"]][(.recode_source == 3)] <- 100
d[["educat_isced"]][(!is.na(.recode_source) & .recode_source >= 4 & .recode_source <= 6)] <- 244
d[["educat_isced"]][(.recode_source == 7)] <- 344
d[["educat_isced"]][(!is.na(.recode_source) & .recode_source >= 8 & .recode_source <= 12)] <- 660
d[["educat_isced"]][(!is.na(.recode_source) & .recode_source >= 13 & .recode_source <= 14)] <- 760
d[["educat_isced"]][(.recode_source == 1516)] <- 860
rm(.recode_source)
# Stata line 714
d[["educat_isced"]][(!is.na(d[["age"]]) & d[["age"]] < d[["ed_mod_age"]])] <- NA_real_
variable_labels[["educat_isced"]] <- "ISCED standardised level of education"

# ----------6.1: Education cleanup------------------------------*

# <_% Correction min age_>
.age_mask <- d[["age"]] < d[["ed_mod_age"]] & !is.na(d[["age"]])
for (.name in c("school", "literacy", "educy", "educat7", "educat5", "educat4", "educat_orig", "educat_isced")) d[[.name]][.age_mask] <- if (is.character(d[[.name]])) "" else NA_real_
rm(.age_mask, .name)

# <_vocational_>
# Stata line 751
d[["vocational"]] <- d[["s4c11"]]
# Stata line 752
.recode_source <- d[["vocational"]]
d[["vocational"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 3)] <- 1
d[["vocational"]][(.recode_source == 4)] <- 0
rm(.recode_source)
# Stata line 753
d[["vocational"]][(!(!is.na(d[["vocational"]]) & d[["vocational"]] >= 0 & d[["vocational"]] <= 1))] <- NA_real_
label_defs[["lblvocational"]] <- setNames(c(0, 1), c("No", "Yes"))
# Source attaches undefined value label vocationallbl to vocational; no labels exported.
variable_labels[["vocational"]] <- "Ever received vocational training"

# <_vocational_type_>
# Stata line 761
d[["vocational_type"]] <- d[["s4c11"]]
# Stata line 762
.recode_source <- d[["vocational_type"]]
d[["vocational_type"]][(.recode_source == 1)] <- 1
d[["vocational_type"]][(.recode_source == 2)] <- 2
rm(.recode_source)
# Stata line 763
d[["vocational_type"]][(!(!is.na(d[["vocational_type"]]) & d[["vocational_type"]] >= 1 & d[["vocational_type"]] <= 2))] <- NA_real_
label_defs[["lblvocational_type"]] <- setNames(c(1, 2), c("Inside Enterprise", "External"))
value_labels[["vocational_type"]] <- label_defs[["lblvocational_type"]]
variable_labels[["vocational_type"]] <- "Type of vocational training"

# <_vocational_length_l_>
# Stata line 778
d[["vocational_length_l"]] <- d[["s4c13"]]
# Stata line 779
d[["vocational_length_l"]] <- (d[["vocational_length_l"]] / 4.2)
variable_labels[["vocational_length_l"]] <- "Length of training in months, lower limit"

# <_vocational_length_u_>
# Stata line 785
d[["vocational_length_u"]] <- d[["s4c13"]]
# Stata line 786
d[["vocational_length_u"]] <- (d[["vocational_length_u"]] / 4.2)
variable_labels[["vocational_length_u"]] <- "Length of training in months, upper limit"

# <_vocational_field_orig_>
# Stata line 792
d[["code"]] <- d[["s4c12"]]
# Stata line 793
if (anyDuplicated(training[["code"]])) stop(paste("Nonunique lookup key:", "code"))
.idx <- match(d[["code"]], training[["code"]])
for (.nm in setdiff(names(training), names(d))) d[[.nm]] <- training[[.nm]][.idx]
d[["_merge"]] <- ifelse(is.na(.idx), 1, 3)
rm(.idx, .nm)
d <- d[!((!is.na(d[["_merge"]]) & d[["_merge"]] == 2)), , drop=FALSE]
# Stata line 795
d[["vocational_field_orig"]] <- d[["code"]]
# Stata line 796
.valid <- unique(d[!is.na(d[["vocational_field_orig"]]) & d[["vocational_field_orig"]] != "", c("vocational_field_orig", "training_field")])
if (anyDuplicated(.valid[["vocational_field_orig"]])) stop(paste("Conflicting labels for", "vocational_field_orig"))
value_labels[["vocational_field_orig"]] <- setNames(as.numeric(.valid[["vocational_field_orig"]]), .valid[["training_field"]])
rm(.valid)
# Stata line 797
d[["vocational_field_str"]] <- { labs <- value_labels[["vocational_field_orig"]]; out <- names(labs)[match(d[["vocational_field_orig"]], unname(labs))]; out[is.na(out)] <- ""; out }
# Stata line 798
d[["vocational_field_str"]] <- paste0(paste0(ifelse(is.na(d[["code"]]), ".", format(d[["code"]], scientific=FALSE, trim=TRUE, digits=9)), " - "), d[["vocational_field_str"]])
.drop_cols <- unique(unlist(lapply(c("vocational_field_orig", "code", "_merge"), function(p) grep(glob2rx(p), names(d), value=TRUE))))
d[.drop_cols] <- NULL
rm(.drop_cols)

# Stata line 801
d[["vocational_field_orig"]][(!is.na(d[["vocational_field_orig"]]) & d[["vocational_field_orig"]] == ". - ")] <- ""
variable_labels[["vocational_field_orig"]] <- "Original field of training"

# <_vocational_financed_>
# Stata line 806
d[["vocational_financed"]] <- NA_real_
label_defs[["lblvocational_financed"]] <- setNames(c(1, 2, 3, 4, 5), c("Employer", "Government", "Mixed Employer/Government", "Own funds", "Other"))
variable_labels[["vocational_financed"]] <- "How training was financed"

# <_minlaborage_>
# Stata line 821
d[["minlaborage"]] <- 10
variable_labels[["minlaborage"]] <- "Labor module application age"

# ----------8.1: 7 day reference overall------------------------------*

# <_lstatus_>
# Stata line 830
d[["lstatus"]] <- NA_real_
# Stata line 834
d[["lstatus"]][(!is.na(d[["s5c1"]]) & d[["s5c1"]] == 1)] <- 1
# Stata line 839
d[["lstatus"]][(((!is.na(d[["s5c4"]]) & d[["s5c4"]] == 1) & ((!is.na(d[["s5c6"]]) & d[["s5c6"]] == 1) | (!is.na(d[["s5c7"]]) & d[["s5c7"]] == 1))) & (is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")))] <- 1
# Stata line 842
d[["lstatus"]][((!is.na(d[["s5c9"]]) & d[["s5c9"]] == 4) & (is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")))] <- 1
# Stata line 845
d[["lstatus"]][(((!is.na(d[["s5c9"]]) & d[["s5c9"]] >= 1 & d[["s5c9"]] <= 3) & (!is.na(d[["s5c10"]]) & d[["s5c10"]] >= 1 & d[["s5c10"]] <= 2)) & (is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")))] <- 1
# Stata line 848
d[["lstatus"]][(((((((!is.na(d[["s5c1"]]) & d[["s5c1"]] == 2) & (!is.na(d[["s5c2"]]) & d[["s5c2"]] == 2)) & (!is.na(d[["s5c3"]]) & d[["s5c3"]] == 2)) & (!is.na(d[["s5c4"]]) & d[["s5c4"]] == 2)) & (!is.na(d[["s5c8"]]) & d[["s5c8"]] >= 1 & d[["s5c8"]] <= 3)) & (!is.na(d[["s5c10"]]) & d[["s5c10"]] >= 1 & d[["s5c10"]] <= 2)) & (is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")))] <- 1
# Stata line 853
d[["lstatus"]][(((!is.na(d[["s9c1"]]) & d[["s9c1"]] == 1) & (!is.na(d[["s9c6"]]) & d[["s9c6"]] == 1)) & (is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")))] <- 2
# Stata line 861
d[["lstatus"]][((is.na(d[["lstatus"]]) | (is.character(d[["lstatus"]]) & as.character(d[["lstatus"]]) == "")) & (is.na(d[["age"]]) | d[["age"]] >= d[["minlaborage"]]))] <- 3
# Stata line 864
d[["lstatus"]][(!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]])] <- NA_real_
variable_labels[["lstatus"]] <- "Labor status 7 day recall"
label_defs[["lbllstatus"]] <- setNames(c(1, 2, 3), c("Employed", "Unemployed", "Not in labor force"))
value_labels[["lstatus"]] <- label_defs[["lbllstatus"]]

# <_potential_lf_>
# Stata line 884
d[["potential_lf"]] <- NA_real_
# Stata line 885
d[["potential_lf"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 3)] <- 0
# Stata line 886
d[["potential_lf"]][(((!is.na(d[["s9c1"]]) & d[["s9c1"]] == 2) & (!is.na(d[["s9c6"]]) & d[["s9c6"]] == 1)) | ((!is.na(d[["s9c1"]]) & d[["s9c1"]] == 1) & (!is.na(d[["s9c6"]]) & d[["s9c6"]] == 2)))] <- 1
# Stata line 887
d[["potential_lf"]][((!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]]) & (!(is.na(d[["age"]]) | (is.character(d[["age"]]) & as.character(d[["age"]]) == ""))))] <- NA_real_
# Stata line 888
d[["potential_lf"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 3)] <- NA_real_
variable_labels[["potential_lf"]] <- "Potential labour force status"
label_defs[["lblpotential_lf"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["potential_lf"]] <- label_defs[["lblpotential_lf"]]

# <_underemployment_>
# Stata line 896
d[["underemployment"]] <- NA_real_
# Stata line 897
d[["underemployment"]][(!is.na(d[["s6c2"]]) & d[["s6c2"]] == 1)] <- 1
# Stata line 898
d[["underemployment"]][(!is.na(d[["s6c2"]]) & d[["s6c2"]] == 2)] <- 0
# Stata line 899
d[["underemployment"]][(!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]])] <- NA_real_
# Stata line 900
d[["underemployment"]][((!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]]) & (!(is.na(d[["age"]]) | (is.character(d[["age"]]) & as.character(d[["age"]]) == ""))))] <- NA_real_
# Stata line 901
d[["underemployment"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["underemployment"]] <- "Underemployment status"
label_defs[["lblunderemployment"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["underemployment"]] <- label_defs[["lblunderemployment"]]

# <_nlfreason_>
# Stata line 909
d[["nlfreason"]] <- NA_real_
# Stata line 910
d[["nlfreason_1"]] <- d[["s9c9"]]
d[["nlfreason_1"]][!((!is.na(d[["lstatus"]]) & d[["lstatus"]] == 3))] <- NA
# Stata line 911
.recode_source <- d[["nlfreason_1"]]
d[["nlfreason_1"]][(.recode_source == 7)] <- 1
d[["nlfreason_1"]][(.recode_source == 9)] <- 2
d[["nlfreason_1"]][(!is.na(.recode_source) & .recode_source >= 10 & .recode_source <= 11)] <- 3
d[["nlfreason_1"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 6) | (!is.na(.recode_source) & .recode_source >= 12 & .recode_source <= 13)] <- 5
d[["nlfreason_1"]][(.recode_source == 8)] <- 4
rm(.recode_source)
# Stata line 912
d[["nlfreason_2"]] <- d[["s9c5"]]
d[["nlfreason_2"]][!((!is.na(d[["lstatus"]]) & d[["lstatus"]] == 3))] <- NA
# Stata line 913
.recode_source <- d[["nlfreason_2"]]
d[["nlfreason_2"]][(.recode_source == 9)] <- 1
d[["nlfreason_2"]][(.recode_source == 10)] <- 2
d[["nlfreason_2"]][(.recode_source == 12)] <- 4
d[["nlfreason_2"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 8) | (.recode_source == 11) | (!is.na(.recode_source) & .recode_source >= 13 & .recode_source <= 14)] <- 5
rm(.recode_source)
# Stata line 914
d[["nlfreason"]] <- d[["nlfreason_1"]]
# Stata line 915
d[["nlfreason"]][(is.na(d[["nlfreason"]]) | (is.character(d[["nlfreason"]]) & as.character(d[["nlfreason"]]) == ""))] <- d[["nlfreason_2"]]
# Stata line 916
d[["nlfreason"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 3)] <- NA_real_
# Stata line 917
d[["nlfreason"]][((!is.na(d[["lstatus"]]) & d[["lstatus"]] == 3) & is.na(d[["nlfreason"]]))] <- 5
variable_labels[["nlfreason"]] <- "Reason not in the labor force"
label_defs[["lblnlfreason"]] <- setNames(c(1, 2, 3, 4, 5), c("Student", "Housekeeper", "Retired", "Disabled", "Other"))
value_labels[["nlfreason"]] <- label_defs[["lblnlfreason"]]

# <_unempldur_l_>
# Stata line 925
d[["unempldur_l"]] <- NA_real_
# Stata line 926
d[["unempldur_l"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 2)] <- d[["s9c3"]]
# Stata line 927
.recode_source <- d[["unempldur_l"]]
d[["unempldur_l"]][(.recode_source == 1)] <- 0
d[["unempldur_l"]][(.recode_source == 2)] <- 1
d[["unempldur_l"]][(.recode_source == 3)] <- 3
d[["unempldur_l"]][(.recode_source == 4)] <- 6
d[["unempldur_l"]][(.recode_source == 5)] <- 12
rm(.recode_source)
# Stata line 928
d[["unempldur_l"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1)] <- NA_real_
variable_labels[["unempldur_l"]] <- "Unemployment duration (months) lower bracket"

# <_unempldur_u_>
# Stata line 934
d[["unempldur_u"]] <- NA_real_
# Stata line 935
d[["unempldur_u"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 2)] <- d[["s9c3"]]
# Stata line 936
.recode_source <- d[["unempldur_u"]]
d[["unempldur_u"]][(.recode_source == 1)] <- 0
d[["unempldur_u"]][(.recode_source == 2)] <- 3
d[["unempldur_u"]][(.recode_source == 3)] <- 6
d[["unempldur_u"]][(.recode_source == 4)] <- 12
d[["unempldur_u"]][(.recode_source == 5)] <- NA_real_
rm(.recode_source)
# Stata line 937
d[["unempldur_u"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1)] <- NA_real_
variable_labels[["unempldur_u"]] <- "Unemployment duration (months) upper bracket"

# ----------8.2: 7 day reference main job------------------------------*

# <_empstat_>
# Stata line 948
d[["empstat"]] <- d[["s5c11"]]
# Stata line 949
.recode_source <- d[["empstat"]]
d[["empstat"]][(.recode_source == 3) | (.recode_source == 5)] <- 1
d[["empstat"]][(.recode_source == 4)] <- 2
d[["empstat"]][(.recode_source == 1)] <- 3
d[["empstat"]][(.recode_source == 2)] <- 4
d[["empstat"]][(.recode_source == 6)] <- 5
rm(.recode_source)
# Stata line 950
d[["empstat"]][(!(!is.na(d[["s5c11"]]) & d[["s5c11"]] >= 1 & d[["s5c11"]] <= 6))] <- NA_real_
# Stata line 951
d[["empstat"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["empstat"]] <- "Employment status during past week primary job 7 day recall"
label_defs[["lblempstat"]] <- setNames(c(1, 2, 3, 4, 5), c("Paid employee", "Non-paid employee", "Employer", "Self-employed", "Other, workers not classifiable by status"))
value_labels[["empstat"]] <- label_defs[["lblempstat"]]

# <_ocusec_>
# Stata line 959
d[["ocusec"]] <- d[["s5c15"]]
# Stata line 960
.recode_source <- d[["ocusec"]]
d[["ocusec"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 3)] <- 1
d[["ocusec"]][(.recode_source == 4)] <- 3
d[["ocusec"]][(!is.na(.recode_source) & .recode_source >= 5 & .recode_source <= 10)] <- 2
d[["ocusec"]][(.recode_source == 11)] <- 4
rm(.recode_source)
# Stata line 961
d[["ocusec"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["ocusec"]] <- "Sector of activity primary job 7 day recall"
label_defs[["lblocusec"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec"]] <- label_defs[["lblocusec"]]

# <_industry_orig_>
# Stata line 969
d[["industry_orig"]] <- ifelse(is.na(d[["s5c13"]]), ".", sprintf("%04.0f", d[["s5c13"]]))
# Stata line 970
d[["industry_orig"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 971
d[["industry_orig"]][(!is.na(d[["industry_orig"]]) & d[["industry_orig"]] == ".")] <- ""
variable_labels[["industry_orig"]] <- "Original survey industry code, main job 7 day recall"

# <_industrycat_isic_>
# Stata line 977
d[["industrycat_isic"]] <- d[["industry_orig"]]
# Stata line 978
d[["industrycat_isic"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 979
d[["industrycat_isic"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] == ".")] <- ""
# GLD int_classif_universe validation intentionally skipped.
variable_labels[["industrycat_isic"]] <- "ISIC code of primary job 7 day recall"

# <_industrycat10_>
# Stata line 996
d[["industrycat10"]] <- NA_real_
# Stata line 997
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "0100" & d[["industrycat_isic"]] <= "0399")] <- 1
# Stata line 998
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "0500" & d[["industrycat_isic"]] <= "0999")] <- 2
# Stata line 999
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "1000" & d[["industrycat_isic"]] <= "3399")] <- 3
# Stata line 1000
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "3500" & d[["industrycat_isic"]] <= "3900")] <- 4
# Stata line 1001
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "4100" & d[["industrycat_isic"]] <= "4399")] <- 5
# Stata line 1002
d[["industrycat10"]][((!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "4500" & d[["industrycat_isic"]] <= "4799") | (!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "5500" & d[["industrycat_isic"]] <= "5699"))] <- 6
# Stata line 1003
d[["industrycat10"]][((!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "4900" & d[["industrycat_isic"]] <= "5399") | (!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "5800" & d[["industrycat_isic"]] <= "6399"))] <- 7
# Stata line 1004
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "6400" & d[["industrycat_isic"]] <= "8299")] <- 8
# Stata line 1005
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "8400" & d[["industrycat_isic"]] <= "8499")] <- 9
# Stata line 1006
d[["industrycat10"]][(!is.na(d[["industrycat_isic"]]) & d[["industrycat_isic"]] >= "8500" & d[["industrycat_isic"]] <= "9900")] <- 10
variable_labels[["industrycat10"]] <- "1 digit industry classification, primary job 7 day recall"
label_defs[["lblindustrycat10"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Agriculture", "Mining", "Manufacturing", "Public utilities", "Construction", "Commerce", "Transport and Comnunications", "Financial and Business Services", "Public Administration", "Other Services, Unspecified"))
value_labels[["industrycat10"]] <- label_defs[["lblindustrycat10"]]

# <_industrycat4_>
# Stata line 1015
d[["industrycat4"]] <- d[["industrycat10"]]
# Stata line 1016
.recode_source <- d[["industrycat4"]]
d[["industrycat4"]][(.recode_source == 1)] <- 1
d[["industrycat4"]][(.recode_source == 2) | (.recode_source == 3) | (.recode_source == 4) | (.recode_source == 5)] <- 2
d[["industrycat4"]][(.recode_source == 6) | (.recode_source == 7) | (.recode_source == 8) | (.recode_source == 9)] <- 3
d[["industrycat4"]][(.recode_source == 10)] <- 4
rm(.recode_source)
variable_labels[["industrycat4"]] <- "Broad Economic Activities classification, primary job 7 day recall"
label_defs[["lblindustrycat4"]] <- setNames(c(1, 2, 3, 4), c("Agriculture", "Industry", "Services", "Other"))
value_labels[["industrycat4"]] <- label_defs[["lblindustrycat4"]]

# <_occup_orig_>
# Stata line 1024
d[["occup_orig"]] <- ifelse(is.na(d[["s5c12"]]), ".", sprintf("%04.0f", d[["s5c12"]]))
# Stata line 1025
d[["occup_orig"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1026
d[["occup_orig"]][(!is.na(d[["industry_orig"]]) & d[["industry_orig"]] == ".")] <- ""
variable_labels[["occup_orig"]] <- "Original occupation record primary job 7 day recall"

# <_occup_isco_>
# Stata line 1032
d[["occup_isco"]] <- d[["occup_orig"]]
# Stata line 1033
d[["occup_isco"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1034
d[["occup_isco"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] == ".")] <- ""
# Stata line 1037
d[["occup_isco"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] == "4140")] <- "4100"
# GLD int_classif_universe validation intentionally skipped.
variable_labels[["occup_isco"]] <- "ISCO code of primary job 7 day recall"

# <_occup_>
# Stata line 1053
d[["occup"]] <- NA_real_
# Stata line 1054
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "1000" & d[["occup_isco"]] <= "1999")] <- 1
# Stata line 1055
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "2000" & d[["occup_isco"]] <= "2999")] <- 2
# Stata line 1056
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "3000" & d[["occup_isco"]] <= "3999")] <- 3
# Stata line 1057
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "4000" & d[["occup_isco"]] <= "4999")] <- 4
# Stata line 1058
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "5000" & d[["occup_isco"]] <= "5999")] <- 5
# Stata line 1059
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "6000" & d[["occup_isco"]] <= "6999")] <- 6
# Stata line 1060
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "7000" & d[["occup_isco"]] <= "7999")] <- 7
# Stata line 1061
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "8000" & d[["occup_isco"]] <= "8999")] <- 8
# Stata line 1062
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "9000" & d[["occup_isco"]] <= "9999")] <- 9
# Stata line 1063
d[["occup"]][(!is.na(d[["occup_isco"]]) & d[["occup_isco"]] >= "0000" & d[["occup_isco"]] <= "0999")] <- 10
variable_labels[["occup"]] <- "1 digit occupational classification, primary job 7 day recall"
label_defs[["lbloccup"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99), c("Managers", "Professionals", "Technicians", "Clerks", "Service and market sales workers", "Skilled agricultural", "Craft workers", "Machine operators", "Elementary occupations", "Armed forces", "Others"))
value_labels[["occup"]] <- label_defs[["lbloccup"]]

# <_occup_skill_>
# Stata line 1071
d[["occup_skill"]] <- d[["occup"]]
# Stata line 1072
d[["occup_skill"]][(!is.na(d[["occup"]]) & d[["occup"]] >= 1 & d[["occup"]] <= 3)] <- 3
# Stata line 1073
d[["occup_skill"]][(!is.na(d[["occup"]]) & d[["occup"]] >= 4 & d[["occup"]] <= 8)] <- 2
# Stata line 1074
d[["occup_skill"]][(!is.na(d[["occup"]]) & d[["occup"]] == 9)] <- 1
label_defs[["lblskill"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill"]] <- label_defs[["lblskill"]]
variable_labels[["occup_skill"]] <- "Skill based on ISCO standard primary job 7 day recall"

# <_wage_no_compen_>
# Stata line 1082
d[["last_week"]] <- d[["s7c33"]]
# Stata line 1083
d[["last_month"]] <- d[["s7c43"]]
# Stata line 1084
d[["last_year"]] <- d[["s7c9"]]
# Stata line 1087
d[["last_week"]][(!is.na(d[["last_week"]]) & d[["last_week"]] <= 0)] <- NA_real_
# Stata line 1088
d[["last_month"]][(!is.na(d[["last_month"]]) & d[["last_month"]] <= 0)] <- NA_real_
# Stata line 1089
d[["last_year"]][(!is.na(d[["last_year"]]) & d[["last_year"]] <= 0)] <- NA_real_
# Stata line 1092
d[["last_week"]][((!(is.na(d[["last_week"]]) | (is.character(d[["last_week"]]) & as.character(d[["last_week"]]) == ""))) & (!(is.na(d[["last_month"]]) | (is.character(d[["last_month"]]) & as.character(d[["last_month"]]) == ""))))] <- NA_real_
# Stata line 1095
d[["wage_no_compen"]] <- {z<-as.matrix(d[c("last_week", "last_month", "last_year")]); x<-rowSums(z,na.rm=TRUE);x[rowSums(!is.na(z))==0]<-NA_real_;x}
# Stata line 1098
d[["wage_no_compen"]][(!is.na(d[["empstat"]]) & d[["empstat"]] == 2)] <- NA_real_
# Stata line 1099
d[["wage_no_compen"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["wage_no_compen"]] <- "Last wage payment primary job 7 day recall"
.drop_cols <- unique(unlist(lapply(c("last_week", "last_month", "last_year"), function(p) grep(glob2rx(p), names(d), value=TRUE))))
d[.drop_cols] <- NULL
rm(.drop_cols)

# <_unitwage_>
# Stata line 1113
d[["unitwage"]] <- NA_real_
# Stata line 1114
d[["unitwage"]][(((!(is.na(d[["s7c33"]]) | (is.character(d[["s7c33"]]) & as.character(d[["s7c33"]]) == ""))) & (is.na(d[["s7c33"]]) | d[["s7c33"]] > 0)) & (!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1))] <- 2
# Stata line 1115
d[["unitwage"]][(((!(is.na(d[["s7c43"]]) | (is.character(d[["s7c43"]]) & as.character(d[["s7c43"]]) == ""))) & (is.na(d[["s7c43"]]) | d[["s7c43"]] > 0)) & (!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1))] <- 5
# Stata line 1116
d[["unitwage"]][(((((!(is.na(d[["s7c9"]]) | (is.character(d[["s7c9"]]) & as.character(d[["s7c9"]]) == ""))) & (is.na(d[["s7c9"]]) | d[["s7c9"]] > 0)) & (!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1)) & (is.na(d[["s7c43"]]) | (is.character(d[["s7c43"]]) & as.character(d[["s7c43"]]) == ""))) & (is.na(d[["s7c33"]]) | (is.character(d[["s7c33"]]) & as.character(d[["s7c33"]]) == "")))] <- 8
# Stata line 1118
d[["unitwage"]][(!is.na(d[["empstat"]]) & d[["empstat"]] == 2)] <- NA_real_
# Stata line 1119
d[["unitwage"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["unitwage"]] <- "Last wages' time unit primary job 7 day recall"
label_defs[["lblunitwage"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Daily", "Weekly", "Every two weeks", "Bimonthly", "Monthly", "Trimester", "Biannual", "Annually", "Hourly", "Other"))
value_labels[["unitwage"]] <- label_defs[["lblunitwage"]]

# <_whours_>
# Stata line 1130
d[["whours"]] <- NA_real_
# Stata line 1131
d[["whours"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1)] <- d[["s5c24"]]
# Stata line 1132
d[["whours"]][((!is.na(d[["whours"]]) & d[["whours"]] == 0) & (!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1))] <- NA_real_
variable_labels[["whours"]] <- "Hours of work in last week primary job 7 day recall"

# <_wmonths_>
# Stata line 1138
d[["wmonths"]] <- NA_real_
# Stata line 1139
d[["wmonths"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["wmonths"]] <- "Months of work in past 12 months primary job 7 day recall"

# <_wage_total_>
# Stata line 1151
d[["wage_total"]] <- NA_real_
variable_labels[["wage_total"]] <- "Annualized total wage primary job 7 day recall"

# <_contract_>
# Stata line 1157
d[["contract"]] <- NA_real_
# Stata line 1158
d[["contract"]][(!is.na(d[["lstatus"]]) & d[["lstatus"]] == 1)] <- d[["s7c1"]]
# Stata line 1159
.recode_source <- d[["contract"]]
d[["contract"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 6)] <- 1
d[["contract"]][(.recode_source == 7)] <- 0
rm(.recode_source)
variable_labels[["contract"]] <- "Employment has contract primary job 7 day recall"
label_defs[["lblcontract"]] <- setNames(c(0, 1), c("Without contract", "With contract"))
value_labels[["contract"]] <- label_defs[["lblcontract"]]

# <_healthins_>
# Stata line 1167
d[["healthins"]] <- NA_real_
variable_labels[["healthins"]] <- "Employment has health insurance primary job 7 day recall"
label_defs[["lblhealthins"]] <- setNames(c(0, 1), c("Without health insurance", "With health insurance"))
value_labels[["healthins"]] <- label_defs[["lblhealthins"]]

# <_socialsec_>
# Stata line 1175
d[["socialsec"]] <- 0
# Stata line 1176
d[["socialsec"]][((!is.na(d[["s7c61"]]) & d[["s7c61"]] == 1) | (!is.na(d[["s7c64"]]) & d[["s7c64"]] == 4))] <- 1
# Stata line 1177
d[["socialsec"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["socialsec"]] <- "Employment has social security insurance primary job 7 day recall"
label_defs[["lblsocialsec"]] <- setNames(c(1, 0), c("With social security", "Without social secturity"))
value_labels[["socialsec"]] <- label_defs[["lblsocialsec"]]

# <_union_>
# Stata line 1185
d[["union"]] <- NA_real_
# Stata line 1186
d[["union"]][(!is.na(d[["s5c20"]]) & d[["s5c20"]] == 1)] <- 1
# Stata line 1187
d[["union"]][((!is.na(d[["s5c20"]]) & d[["s5c20"]] == 2) | (!is.na(d[["s5c20"]]) & d[["s5c20"]] == 3))] <- 0
# Stata line 1188
d[["union"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["union"]] <- "Union membership at primary job 7 day recall"
label_defs[["lblunion"]] <- setNames(c(0, 1), c("Not union member", "Union member"))
value_labels[["union"]] <- label_defs[["lblunion"]]

# <_firmsize_l_>
# Stata line 1196
d[["firmsize_l"]] <- d[["s5c18"]]
# Stata line 1197
d[["firmsize_l"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["firmsize_l"]] <- "Firm size (lower bracket) primary job 7 day recall"

# <_firmsize_u_>
# Stata line 1203
d[["firmsize_u"]] <- d[["s5c18"]]
# Stata line 1204
d[["firmsize_u"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["firmsize_u"]] <- "Firm size (upper bracket) primary job 7 day recall"

# ----------8.3: 7 day reference secondary job------------------------------*

# <_empstat_2_>
# Stata line 1217
d[["empstat_2"]] <- d[["s5c26"]]
# Stata line 1218
.recode_source <- d[["empstat_2"]]
d[["empstat_2"]][(.recode_source == 3) | (.recode_source == 5)] <- 1
d[["empstat_2"]][(.recode_source == 4)] <- 2
d[["empstat_2"]][(.recode_source == 1)] <- 3
d[["empstat_2"]][(.recode_source == 2)] <- 4
d[["empstat_2"]][(.recode_source == 6)] <- 5
d[["empstat_2"]][(.recode_source == 0)] <- NA_real_
rm(.recode_source)
# Stata line 1219
d[["empstat_2"]][(is.na(d[["s5c25"]]) | d[["s5c25"]] != 1)] <- NA_real_
# Stata line 1220
d[["empstat_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["empstat_2"]] <- "Employment status during past week secondary job 7 day recall"
value_labels[["empstat_2"]] <- label_defs[["lblempstat"]]

# <_ocusec_2_>
# Stata line 1227
d[["ocusec_2"]] <- d[["s5c30"]]
# Stata line 1228
.recode_source <- d[["ocusec_2"]]
d[["ocusec_2"]][(!is.na(.recode_source) & .recode_source >= 1 & .recode_source <= 3)] <- 1
d[["ocusec_2"]][(.recode_source == 4)] <- 3
d[["ocusec_2"]][(!is.na(.recode_source) & .recode_source >= 5 & .recode_source <= 10)] <- 2
d[["ocusec_2"]][(.recode_source == 11)] <- 4
rm(.recode_source)
# Stata line 1229
d[["ocusec_2"]][(is.na(d[["s5c25"]]) | d[["s5c25"]] != 1)] <- NA_real_
# Stata line 1230
d[["ocusec_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["ocusec_2"]] <- "Sector of activity secondary job 7 day recall"
value_labels[["ocusec_2"]] <- label_defs[["lblocusec"]]

# <_industry_orig_2_>
# Stata line 1237
d[["industry_orig_2"]] <- ifelse(is.na(d[["s5c28"]]), ".", sprintf("%04.0f", d[["s5c28"]]))
# Stata line 1238
d[["industry_orig_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1239
d[["industry_orig_2"]][(!is.na(d[["industry_orig"]]) & d[["industry_orig"]] == ".")] <- ""
variable_labels[["industry_orig_2"]] <- "Original survey industry code, secondary job 7 day recall"

# <_industrycat_isic_2_>
# Stata line 1246
d[["industrycat_isic_2"]] <- d[["industry_orig_2"]]
# Stata line 1247
d[["industrycat_isic_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1248
d[["industrycat_isic_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] == ".")] <- ""
# Stata line 1249
d[["industrycat_isic_2"]][(is.na(d[["empstat_2"]]) | (is.character(d[["empstat_2"]]) & as.character(d[["empstat_2"]]) == ""))] <- ""
# Stata line 1250
d[["industrycat_isic_2"]][(!is.na(d[["industry_orig_2"]]) & d[["industry_orig_2"]] == "320")] <- "0320"
# Stata line 1252
d[["industrycat_isic_2"]][(!is.na(d[["industry_orig_2"]]) & d[["industry_orig_2"]] == "6121")] <- "6120"
# GLD int_classif_universe validation intentionally skipped.
variable_labels[["industrycat_isic_2"]] <- "ISIC code of secondary job 7 day recall"

# <_industrycat10_2_>
# Stata line 1267
d[["industrycat10_2"]] <- NA_real_
# Stata line 1268
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "0100" & d[["industrycat_isic_2"]] <= "0399")] <- 1
# Stata line 1269
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "0500" & d[["industrycat_isic_2"]] <= "0999")] <- 2
# Stata line 1270
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "1000" & d[["industrycat_isic_2"]] <= "3399")] <- 3
# Stata line 1271
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "3500" & d[["industrycat_isic_2"]] <= "3900")] <- 4
# Stata line 1272
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "4100" & d[["industrycat_isic_2"]] <= "4399")] <- 5
# Stata line 1273
d[["industrycat10_2"]][((!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "4500" & d[["industrycat_isic_2"]] <= "4799") | (!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "5500" & d[["industrycat_isic_2"]] <= "5699"))] <- 6
# Stata line 1274
d[["industrycat10_2"]][((!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "4900" & d[["industrycat_isic_2"]] <= "5399") | (!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "5800" & d[["industrycat_isic_2"]] <= "6399"))] <- 7
# Stata line 1275
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "6400" & d[["industrycat_isic_2"]] <= "8299")] <- 8
# Stata line 1276
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "8400" & d[["industrycat_isic_2"]] <= "8499")] <- 9
# Stata line 1277
d[["industrycat10_2"]][(!is.na(d[["industrycat_isic_2"]]) & d[["industrycat_isic_2"]] >= "8500" & d[["industrycat_isic_2"]] <= "9900")] <- 10
variable_labels[["industrycat10_2"]] <- "1 digit industry classification, secondary job 7 day recall"
value_labels[["industrycat10_2"]] <- label_defs[["lblindustrycat10"]]

# <_industrycat4_2_>
# Stata line 1284
d[["industrycat4_2"]] <- d[["industrycat10_2"]]
# Stata line 1285
.recode_source <- d[["industrycat4_2"]]
d[["industrycat4_2"]][(.recode_source == 1)] <- 1
d[["industrycat4_2"]][(.recode_source == 2) | (.recode_source == 3) | (.recode_source == 4) | (.recode_source == 5)] <- 2
d[["industrycat4_2"]][(.recode_source == 6) | (.recode_source == 7) | (.recode_source == 8) | (.recode_source == 9)] <- 3
d[["industrycat4_2"]][(.recode_source == 10)] <- 4
rm(.recode_source)
variable_labels[["industrycat4_2"]] <- "Broad Economic Activities classification, secondary job 7 day recall"
value_labels[["industrycat4_2"]] <- label_defs[["lblindustrycat4"]]

# <_occup_orig_2_>
# Stata line 1292
d[["occup_orig_2"]] <- ifelse(is.na(d[["s5c27"]]), ".", sprintf("%04.0f", d[["s5c27"]]))
# Stata line 1293
d[["occup_orig_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1294
d[["occup_orig_2"]][(!is.na(d[["industry_orig"]]) & d[["industry_orig"]] == ".")] <- ""
variable_labels[["occup_orig_2"]] <- "Original occupation record secondary job 7 day recall"

# <_occup_isco_2_>
# Stata line 1300
d[["occup_isco_2"]] <- d[["occup_orig_2"]]
# Stata line 1301
d[["occup_isco_2"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- ""
# Stata line 1302
d[["occup_isco_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] == ".")] <- ""
# Stata line 1305
d[["occup_isco_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] == "4140")] <- "4100"
# Stata line 1306
d[["occup_isco_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] == "2333")] <- "2300"
# Stata line 1307
d[["occup_isco_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] == "9516")] <- "9500"
# GLD int_classif_universe validation intentionally skipped.
variable_labels[["occup_isco_2"]] <- "ISCO code of secondary job 7 day recall"

# <_occup_2_>
# Stata line 1322
d[["occup_2"]] <- NA_real_
# Stata line 1323
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "1000" & d[["occup_isco_2"]] <= "1999")] <- 1
# Stata line 1324
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "2000" & d[["occup_isco_2"]] <= "2999")] <- 2
# Stata line 1325
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "3000" & d[["occup_isco_2"]] <= "3999")] <- 3
# Stata line 1326
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "4000" & d[["occup_isco_2"]] <= "4999")] <- 4
# Stata line 1327
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "5000" & d[["occup_isco_2"]] <= "5999")] <- 5
# Stata line 1328
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "6000" & d[["occup_isco_2"]] <= "6999")] <- 6
# Stata line 1329
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "7000" & d[["occup_isco_2"]] <= "7999")] <- 7
# Stata line 1330
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "8000" & d[["occup_isco_2"]] <= "8999")] <- 8
# Stata line 1331
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "9000" & d[["occup_isco_2"]] <= "9999")] <- 9
# Stata line 1332
d[["occup_2"]][(!is.na(d[["occup_isco_2"]]) & d[["occup_isco_2"]] >= "0000" & d[["occup_isco_2"]] <= "0999")] <- 10
variable_labels[["occup_2"]] <- "1 digit occupational classification secondary job 7 day recall"
value_labels[["occup_2"]] <- label_defs[["lbloccup"]]

# <_occup_skill_2_>
# Stata line 1339
d[["occup_skill_2"]] <- NA_real_
# Stata line 1340
d[["occup_skill_2"]][(!is.na(d[["occup_2"]]) & d[["occup_2"]] >= 1 & d[["occup_2"]] <= 3)] <- 3
# Stata line 1341
d[["occup_skill_2"]][(!is.na(d[["occup_2"]]) & d[["occup_2"]] >= 4 & d[["occup_2"]] <= 8)] <- 2
# Stata line 1342
d[["occup_skill_2"]][(!is.na(d[["occup_2"]]) & d[["occup_2"]] == 9)] <- 1
label_defs[["lblskill2"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_2"]] <- label_defs[["lblskill2"]]
variable_labels[["occup_skill_2"]] <- "Skill based on ISCO standard secondary job 7 day recall"

# <_wage_no_compen_2_>
# Stata line 1350
d[["wage_no_compen_2"]] <- NA_real_
variable_labels[["wage_no_compen_2"]] <- "Last wage payment secondary job 7 day recall"

# <_unitwage_2_>
# Stata line 1356
d[["unitwage_2"]] <- NA_real_
variable_labels[["unitwage_2"]] <- "Last wages' time unit secondary job 7 day recall"
value_labels[["unitwage_2"]] <- label_defs[["lblunitwage"]]

# <_whours_2_>
# Stata line 1363
d[["whours_2"]] <- d[["s5c35"]]
# Stata line 1364
d[["whours_2"]][(is.na(d[["s5c25"]]) | d[["s5c25"]] != 1)] <- NA_real_
variable_labels[["whours_2"]] <- "Hours of work in last week secondary job 7 day recall"

# <_wmonths_2_>
# Stata line 1370
d[["wmonths_2"]] <- NA_real_
variable_labels[["wmonths_2"]] <- "Months of work in past 12 months secondary job 7 day recall"

# <_wage_total_2_>
# Stata line 1376
d[["wage_total_2"]] <- NA_real_
variable_labels[["wage_total_2"]] <- "Annualized total wage secondary job 7 day recall"

# <_firmsize_l_2_>
# Stata line 1382
d[["firmsize_l_2"]] <- d[["s5c33"]]
# Stata line 1383
d[["firmsize_l_2"]][((is.na(d[["s5c25"]]) | d[["s5c25"]] != 1) | (!is.na(d[["s5c33"]]) & d[["s5c33"]] == 0))] <- NA_real_
variable_labels[["firmsize_l_2"]] <- "Firm size (lower bracket) secondary job 7 day recall"

# <_firmsize_u_2_>
# Stata line 1389
d[["firmsize_u_2"]] <- d[["s5c33"]]
# Stata line 1390
d[["firmsize_l_2"]][((is.na(d[["s5c25"]]) | d[["s5c25"]] != 1) | (!is.na(d[["s5c33"]]) & d[["s5c33"]] == 0))] <- NA_real_
variable_labels[["firmsize_u_2"]] <- "Firm size (upper bracket) secondary job 7 day recall"

# ----------8.4: 7 day reference additional jobs------------------------------*

# <_t_hours_others_>
# Stata line 1399
d[["t_hours_others"]] <- NA_real_
variable_labels[["t_hours_others"]] <- "Annualized hours worked in all but primary and secondary jobs 7 day recall"

# <_t_wage_nocompen_others_>
# Stata line 1405
d[["t_wage_nocompen_others"]] <- NA_real_
variable_labels[["t_wage_nocompen_others"]] <- "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_others_>
# Stata line 1411
d[["t_wage_others"]] <- NA_real_
variable_labels[["t_wage_others"]] <- "Annualized wage in all but primary and secondary jobs (12-mon ref period)"

# ----------8.5: 7 day reference total summary------------------------------*

# <_t_hours_total_>
# Stata line 1420
d[["t_hours_total"]] <- NA_real_
variable_labels[["t_hours_total"]] <- "Annualized hours worked in all jobs 7 day recall"

# <_t_wage_nocompen_total_>
# Stata line 1426
d[["t_wage_nocompen_total"]] <- NA_real_
variable_labels[["t_wage_nocompen_total"]] <- "Annualized wage in all jobs excl. bonuses, etc. 7 day recall"

# <_t_wage_total_>
# Stata line 1432
d[["t_wage_total"]] <- NA_real_
variable_labels[["t_wage_total"]] <- "Annualized total wage for all jobs 7 day recall"

# ----------8.6: 12 month reference overall------------------------------*

# <_lstatus_year_>
# Stata line 1442
d[["lstatus_year"]] <- NA_real_
# Stata line 1443
d[["lstatus_year"]][((!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]]) & (!(is.na(d[["age"]]) | (is.character(d[["age"]]) & as.character(d[["age"]]) == ""))))] <- NA_real_
variable_labels[["lstatus_year"]] <- "Labor status during last year"
label_defs[["lbllstatus_year"]] <- setNames(c(1, 2, 3), c("Employed", "Unemployed", "Non-LF"))
value_labels[["lstatus_year"]] <- label_defs[["lbllstatus_year"]]

# <_potential_lf_year_>
# Stata line 1450
d[["potential_lf_year"]] <- NA_real_
# Stata line 1451
d[["potential_lf_year"]][((!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]]) & (!(is.na(d[["age"]]) | (is.character(d[["age"]]) & as.character(d[["age"]]) == ""))))] <- NA_real_
# Stata line 1452
d[["potential_lf_year"]][(is.na(d[["lstatus_year"]]) | d[["lstatus_year"]] != 3)] <- NA_real_
variable_labels[["potential_lf_year"]] <- "Potential labour force status"
label_defs[["lblpotential_lf_year"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["potential_lf_year"]] <- label_defs[["lblpotential_lf_year"]]

# <_underemployment_year_>
# Stata line 1460
d[["underemployment_year"]] <- NA_real_
# Stata line 1461
d[["underemployment_year"]][((!is.na(d[["age"]]) & d[["age"]] < d[["minlaborage"]]) & (!(is.na(d[["age"]]) | (is.character(d[["age"]]) & as.character(d[["age"]]) == ""))))] <- NA_real_
# Stata line 1462
d[["underemployment_year"]][(!is.na(d[["lstatus_year"]]) & d[["lstatus_year"]] == 1)] <- NA_real_
variable_labels[["underemployment_year"]] <- "Underemployment status"
label_defs[["lblunderemployment_year"]] <- setNames(c(0, 1), c("No", "Yes"))
value_labels[["underemployment_year"]] <- label_defs[["lblunderemployment_year"]]

# <_nlfreason_year_>
# Stata line 1470
d[["nlfreason_year"]] <- NA_real_
variable_labels[["nlfreason_year"]] <- "Reason not in the labor force"
label_defs[["lblnlfreason_year"]] <- setNames(c(1, 2, 3, 4, 5), c("Student", "Housekeeper", "Retired", "Disabled", "Other"))
value_labels[["nlfreason_year"]] <- label_defs[["lblnlfreason_year"]]

# <_unempldur_l_year_>
# Stata line 1478
d[["unempldur_l_year"]] <- NA_real_
variable_labels[["unempldur_l_year"]] <- "Unemployment duration (months) lower bracket"

# <_unempldur_u_year_>
# Stata line 1484
d[["unempldur_u_year"]] <- NA_real_
variable_labels[["unempldur_u_year"]] <- "Unemployment duration (months) upper bracket"

# ----------8.7: 12 month reference main job------------------------------*

# <_empstat_year_>
# Stata line 1495
d[["empstat_year"]] <- NA_real_
variable_labels[["empstat_year"]] <- "Employment status during past week primary job 12 month recall"
label_defs[["lblempstat_year"]] <- setNames(c(1, 2, 3, 4, 5), c("Paid employee", "Non-paid employee", "Employer", "Self-employed", "Other, workers not classifiable by status"))
value_labels[["empstat_year"]] <- label_defs[["lblempstat_year"]]

# <_ocusec_year_>
# Stata line 1502
d[["ocusec_year"]] <- NA_real_
variable_labels[["ocusec_year"]] <- "Sector of activity primary job 12 month recall"
label_defs[["lblocusec_year"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec_year"]] <- label_defs[["lblocusec_year"]]

# <_industry_orig_year_>
# Stata line 1509
d[["industry_orig_year"]] <- NA_real_
variable_labels[["industry_orig_year"]] <- "Original industry record main job 12 month recall"

# <_industrycat_isic_year_>
# Stata line 1515
d[["industrycat_isic_year"]] <- NA_real_
variable_labels[["industrycat_isic_year"]] <- "ISIC code of primary job 12 month recall"

# <_industrycat10_year_>
# Stata line 1531
d[["industrycat10_year"]] <- NA_real_
variable_labels[["industrycat10_year"]] <- "1 digit industry classification, primary job 12 month recall"
label_defs[["lblindustrycat10_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Agriculture", "Mining", "Manufacturing", "Public utilities", "Construction", "Commerce", "Transport and Comnunications", "Financial and Business Services", "Public Administration", "Other Services, Unspecified"))
value_labels[["industrycat10_year"]] <- label_defs[["lblindustrycat10_year"]]

# <_industrycat4_year_>
# Stata line 1539
d[["industrycat4_year"]] <- d[["industrycat10_year"]]
# Stata line 1540
.recode_source <- d[["industrycat4_year"]]
d[["industrycat4_year"]][(.recode_source == 1)] <- 1
d[["industrycat4_year"]][(.recode_source == 2) | (.recode_source == 3) | (.recode_source == 4) | (.recode_source == 5)] <- 2
d[["industrycat4_year"]][(.recode_source == 6) | (.recode_source == 7) | (.recode_source == 8) | (.recode_source == 9)] <- 3
d[["industrycat4_year"]][(.recode_source == 10)] <- 4
rm(.recode_source)
variable_labels[["industrycat4_year"]] <- "Broad Economic Activities classification, primary job 12 month recall"
label_defs[["lblindustrycat4_year"]] <- setNames(c(1, 2, 3, 4), c("Agriculture", "Industry", "Services", "Other"))
value_labels[["industrycat4_year"]] <- label_defs[["lblindustrycat4_year"]]

# <_occup_orig_year_>
# Stata line 1548
d[["occup_orig_year"]] <- NA_real_
variable_labels[["occup_orig_year"]] <- "Original occupation record primary job 12 month recall"

# <_occup_isco_year_>
# Stata line 1554
d[["occup_isco_year"]] <- ""
variable_labels[["occup_isco_year"]] <- "ISCO code of primary job 12 month recall"

# <_occup_year_>
# Stata line 1571
d[["occup_year"]] <- NA_real_
variable_labels[["occup_year"]] <- "1 digit occupational classification, primary job 12 month recall"
label_defs[["lbloccup_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99), c("Managers", "Professionals", "Technicians", "Clerks", "Service and market sales workers", "Skilled agricultural", "Craft workers", "Machine operators", "Elementary occupations", "Armed forces", "Others"))
value_labels[["occup_year"]] <- label_defs[["lbloccup_year"]]

# <_occup_skill_year_>
# Stata line 1579
d[["occup_skill_year"]] <- NA_real_
# Stata line 1580
d[["occup_skill_year"]][(!is.na(d[["occup_year"]]) & d[["occup_year"]] >= 1 & d[["occup_year"]] <= 3)] <- 3
# Stata line 1581
d[["occup_skill_year"]][(!is.na(d[["occup_year"]]) & d[["occup_year"]] >= 4 & d[["occup_year"]] <= 8)] <- 2
# Stata line 1582
d[["occup_skill_year"]][(!is.na(d[["occup_year"]]) & d[["occup_year"]] == 9)] <- 1
label_defs[["lblskillyear"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_year"]] <- label_defs[["lblskillyear"]]
variable_labels[["occup_skill_year"]] <- "Skill based on ISCO standard primary job 12 month recall"

# <_wage_no_compen_year_> --- this var has the same name as other and when quoted in the keep and order codes is repeated.
# Stata line 1590
d[["wage_no_compen_year"]] <- NA_real_
variable_labels[["wage_no_compen_year"]] <- "Last wage payment primary job 12 month recall"

# <_unitwage_year_>
# Stata line 1596
d[["unitwage_year"]] <- NA_real_
variable_labels[["unitwage_year"]] <- "Last wages' time unit primary job 12 month recall"
label_defs[["lblunitwage_year"]] <- setNames(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), c("Daily", "Weekly", "Every two weeks", "Bimonthly", "Monthly", "Trimester", "Biannual", "Annually", "Hourly", "Other"))
value_labels[["unitwage_year"]] <- label_defs[["lblunitwage_year"]]

# <_whours_year_>
# Stata line 1604
d[["whours_year"]] <- NA_real_
variable_labels[["whours_year"]] <- "Hours of work in last week primary job 12 month recall"

# <_wmonths_year_>
# Stata line 1610
d[["wmonths_year"]] <- NA_real_
variable_labels[["wmonths_year"]] <- "Months of work in past 12 months primary job 12 month recall"

# <_wage_total_year_>
# Stata line 1616
d[["wage_total_year"]] <- NA_real_
variable_labels[["wage_total_year"]] <- "Annualized total wage primary job 12 month recall"

# <_contract_year_>
# Stata line 1622
d[["contract_year"]] <- NA_real_
variable_labels[["contract_year"]] <- "Employment has contract primary job 12 month recall"
label_defs[["lblcontract_year"]] <- setNames(c(0, 1), c("Without contract", "With contract"))
value_labels[["contract_year"]] <- label_defs[["lblcontract_year"]]

# <_healthins_year_>
# Stata line 1630
d[["healthins_year"]] <- NA_real_
variable_labels[["healthins_year"]] <- "Employment has health insurance primary job 12 month recall"
label_defs[["lblhealthins_year"]] <- setNames(c(0, 1), c("Without health insurance", "With health insurance"))
value_labels[["healthins_year"]] <- label_defs[["lblhealthins_year"]]

# <_socialsec_year_>
# Stata line 1638
d[["socialsec_year"]] <- NA_real_
variable_labels[["socialsec_year"]] <- "Employment has social security insurance primary job 7 day recall"
label_defs[["lblsocialsec_year"]] <- setNames(c(1, 0), c("With social security", "Without social secturity"))
value_labels[["socialsec_year"]] <- label_defs[["lblsocialsec_year"]]

# <_union_year_>
# Stata line 1646
d[["union_year"]] <- NA_real_
variable_labels[["union_year"]] <- "Union membership at primary job 12 month recall"
label_defs[["lblunion_year"]] <- setNames(c(0, 1), c("Not union member", "Union member"))
value_labels[["union_year"]] <- label_defs[["lblunion_year"]]

# <_firmsize_l_year_>
# Stata line 1654
d[["firmsize_l_year"]] <- NA_real_
variable_labels[["firmsize_l_year"]] <- "Firm size (lower bracket) primary job 12 month recall"

# <_firmsize_u_year_>
# Stata line 1660
d[["firmsize_u_year"]] <- NA_real_
variable_labels[["firmsize_u_year"]] <- "Firm size (upper bracket) primary job 12 month recall"

# ----------8.8: 12 month reference secondary job------------------------------*

# <_empstat_2_year_>
# Stata line 1672
d[["empstat_2_year"]] <- NA_real_
variable_labels[["empstat_2_year"]] <- "Employment status during past week secondary job 12 month recall"
value_labels[["empstat_2_year"]] <- label_defs[["lblempstat_year"]]

# <_ocusec_2_year_>
# Stata line 1679
d[["ocusec_2_year"]] <- NA_real_
variable_labels[["ocusec_2_year"]] <- "Sector of activity secondary job 12 month recall"
label_defs[["lblocusec_2_year"]] <- setNames(c(1, 2, 3, 4), c("Public Sector, Central Government, Army", "Private, NGO", "State owned", "Public or State-owned, but cannot distinguish"))
value_labels[["ocusec_2_year"]] <- label_defs[["lblocusec_2_year"]]

# <_industry_orig_2_year_>
# Stata line 1688
d[["industry_orig_2_year"]] <- NA_real_
variable_labels[["industry_orig_2_year"]] <- "Original survey industry code, secondary job 12 month recall"

# <_industrycat_isic_2_year_>
# Stata line 1695
d[["industrycat_isic_2_year"]] <- NA_real_
variable_labels[["industrycat_isic_2_year"]] <- "ISIC code of secondary job 12 month recall"

# <_industrycat10_2_year_>
# Stata line 1701
d[["industrycat10_2_year"]] <- NA_real_
variable_labels[["industrycat10_2_year"]] <- "1 digit industry classification, secondary job 12 month recall"
value_labels[["industrycat10_2_year"]] <- label_defs[["lblindustrycat10_year"]]

# <_industrycat4_2_year_>
# Stata line 1708
d[["industrycat4_2_year"]] <- d[["industrycat10_2_year"]]
# Stata line 1709
.recode_source <- d[["industrycat4_2_year"]]
d[["industrycat4_2_year"]][(.recode_source == 1)] <- 1
d[["industrycat4_2_year"]][(.recode_source == 2) | (.recode_source == 3) | (.recode_source == 4) | (.recode_source == 5)] <- 2
d[["industrycat4_2_year"]][(.recode_source == 6) | (.recode_source == 7) | (.recode_source == 8) | (.recode_source == 9)] <- 3
d[["industrycat4_2_year"]][(.recode_source == 10)] <- 4
rm(.recode_source)
variable_labels[["industrycat4_2_year"]] <- "Broad Economic Activities classification, secondary job 12 month recall"
value_labels[["industrycat4_2_year"]] <- label_defs[["lblindustrycat4_year"]]

# <_occup_orig_2_year_>
# Stata line 1716
d[["occup_orig_2_year"]] <- NA_real_
variable_labels[["occup_orig_2_year"]] <- "Original occupation record secondary job 12 month recall"

# <_occup_isco_2_year_>
# Stata line 1722
d[["occup_isco_2_year"]] <- ""
variable_labels[["occup_isco_2_year"]] <- "ISCO code of secondary job 12 month recall"

# <_occup_2_year_>
# Stata line 1728
d[["occup_2_year"]] <- NA_real_
variable_labels[["occup_2_year"]] <- "1 digit occupational classification, secondary job 12 month recall"
value_labels[["occup_2_year"]] <- label_defs[["lbloccup_year"]]

# <_occup_skill_2_year_>
# Stata line 1735
d[["occup_skill_2_year"]] <- NA_real_
# Stata line 1736
d[["occup_skill_2_year"]][(!is.na(d[["occup_2_year"]]) & d[["occup_2_year"]] >= 1 & d[["occup_2_year"]] <= 3)] <- 3
# Stata line 1737
d[["occup_skill_2_year"]][(!is.na(d[["occup_2_year"]]) & d[["occup_2_year"]] >= 4 & d[["occup_2_year"]] <= 8)] <- 2
# Stata line 1738
d[["occup_skill_2_year"]][(!is.na(d[["occup_2_year"]]) & d[["occup_2_year"]] == 9)] <- 1
label_defs[["lblskilly2"]] <- setNames(c(1, 2, 3), c("Low skill", "Medium skill", "High skill"))
value_labels[["occup_skill_2_year"]] <- label_defs[["lblskilly2"]]
variable_labels[["occup_skill_2_year"]] <- "Skill based on ISCO standard secondary job 12 month recall"

# <_wage_no_compen_2_year_>
# Stata line 1746
d[["wage_no_compen_2_year"]] <- NA_real_
variable_labels[["wage_no_compen_2_year"]] <- "Last wage payment secondary job 12 month recall"

# <_unitwage_2_year_>
# Stata line 1752
d[["unitwage_2_year"]] <- NA_real_
variable_labels[["unitwage_2_year"]] <- "Last wages' time unit secondary job 12 month recall"
value_labels[["unitwage_2_year"]] <- label_defs[["lblunitwage_year"]]

# <_whours_2_year_>
# Stata line 1759
d[["whours_2_year"]] <- NA_real_
variable_labels[["whours_2_year"]] <- "Hours of work in last week secondary job 12 month recall"

# <_wmonths_2_year_>
# Stata line 1765
d[["wmonths_2_year"]] <- NA_real_
variable_labels[["wmonths_2_year"]] <- "Months of work in past 12 months secondary job 12 month recall"

# <_wage_total_2_year_>
# Stata line 1771
d[["wage_total_2_year"]] <- NA_real_
variable_labels[["wage_total_2_year"]] <- "Annualized total wage secondary job 12 month recall"

# <_firmsize_l_2_year_>
# Stata line 1776
d[["firmsize_l_2_year"]] <- NA_real_
variable_labels[["firmsize_l_2_year"]] <- "Firm size (lower bracket) secondary job 12 month recall"

# <_firmsize_u_2_year_>
# Stata line 1782
d[["firmsize_u_2_year"]] <- NA_real_
variable_labels[["firmsize_u_2_year"]] <- "Firm size (upper bracket) secondary job 12 month recall"

# ----------8.9: 12 month reference additional jobs------------------------------*

# <_t_hours_others_year_>
# Stata line 1793
d[["t_hours_others_year"]] <- NA_real_
variable_labels[["t_hours_others_year"]] <- "Annualized hours worked in all but primary and secondary jobs 12 month recall"

# <_t_wage_nocompen_others_year_>
# Stata line 1798
d[["t_wage_nocompen_others_year"]] <- NA_real_
variable_labels[["t_wage_nocompen_others_year"]] <- "Annualized wage in all but 1st & 2nd jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_others_year_>
# Stata line 1803
d[["t_wage_others_year"]] <- NA_real_
variable_labels[["t_wage_others_year"]] <- "Annualized wage in all but primary and secondary jobs 12 month recall"

# ----------8.10: 12 month total summary------------------------------*

# <_t_hours_total_year_>
# Stata line 1812
d[["t_hours_total_year"]] <- NA_real_
variable_labels[["t_hours_total_year"]] <- "Annualized hours worked in all jobs 12 month month recall"

# <_t_wage_nocompen_total_year_>
# Stata line 1818
d[["t_wage_nocompen_total_year"]] <- NA_real_
variable_labels[["t_wage_nocompen_total_year"]] <- "Annualized wage in all jobs excl. bonuses, etc. 12 month recall"

# <_t_wage_total_year_>
# Stata line 1824
d[["t_wage_total_year"]] <- NA_real_
variable_labels[["t_wage_total_year"]] <- "Annualized total wage for all jobs 12 month recall"

# ----------8.11: Overall across reference periods------------------------------*

# <_njobs_>
# Stata line 1833
d[["njobs"]] <- NA_real_
# Stata line 1834
d[["njobs"]][(!is.na(d[["s5c25"]]) & d[["s5c25"]] == 2)] <- 1
# Stata line 1835
d[["njobs"]][((!is.na(d[["s5c25"]]) & d[["s5c25"]] == 1) & (!is.na(d[["s5c36"]]) & d[["s5c36"]] == 2))] <- 2
# Stata line 1836
d[["njobs"]][((!is.na(d[["s5c25"]]) & d[["s5c25"]] == 1) & (!is.na(d[["s5c36"]]) & d[["s5c36"]] == 1))] <- 3
# Stata line 1837
d[["njobs"]][(is.na(d[["lstatus"]]) | d[["lstatus"]] != 1)] <- NA_real_
variable_labels[["njobs"]] <- "Total number of jobs"

# <_t_hours_annual_>
# Stata line 1843
d[["t_hours_annual"]] <- NA_real_
variable_labels[["t_hours_annual"]] <- "Total hours worked in all jobs in the previous 12 months"

# <_linc_nc_>
# Stata line 1849
d[["linc_nc"]] <- NA_real_
variable_labels[["linc_nc"]] <- "Total annual wage income in all jobs, excl. bonuses, etc."

# <_laborincome_>
# Stata line 1855
d[["laborincome"]] <- d[["t_wage_total_year"]]
variable_labels[["laborincome"]] <- "Total annual individual labor income in all jobs, incl. bonuses, etc."

# ----------8.13: Labour cleanup------------------------------*

# <_% Correction min age_>
.age_mask <- d[["age"]] < d[["minlaborage"]] & !is.na(d[["age"]])
for (.name in c("minlaborage", "lstatus", "nlfreason", "unempldur_l", "unempldur_u", "empstat", "ocusec", "industry_orig", "industrycat_isic", "industrycat10", "industrycat4", "occup_orig", "occup_isco", "occup_skill", "occup", "wage_no_compen", "unitwage", "whours", "wmonths", "wage_total", "contract", "healthins", "socialsec", "union", "firmsize_l", "firmsize_u", "empstat_2", "ocusec_2", "industry_orig_2", "industrycat_isic_2", "industrycat10_2", "industrycat4_2", "occup_orig_2", "occup_isco_2", "occup_skill_2", "occup_2", "wage_no_compen_2", "unitwage_2", "whours_2", "wmonths_2", "wage_total_2", "firmsize_l_2", "firmsize_u_2", "t_hours_others", "t_wage_nocompen_others", "t_wage_others", "t_hours_total", "t_wage_nocompen_total", "t_wage_total", "lstatus_year", "nlfreason_year", "unempldur_l_year", "unempldur_u_year", "empstat_year", "ocusec_year", "industry_orig_year", "industrycat_isic_year", "industrycat10_year", "industrycat4_year", "occup_orig_year", "occup_isco_year", "occup_skill_year", "occup_year", "unitwage_year", "whours_year", "wmonths_year", "wage_total_year", "contract_year", "healthins_year", "socialsec_year", "union_year", "firmsize_l_year", "firmsize_u_year", "empstat_2_year", "ocusec_2_year", "industry_orig_2_year", "industrycat_isic_2_year", "industrycat10_2_year", "industrycat4_2_year", "occup_orig_2_year", "occup_isco_2_year", "occup_skill_2_year", "occup_2_year", "wage_no_compen_2_year", "unitwage_2_year", "whours_2_year", "wmonths_2_year", "wage_total_2_year", "firmsize_l_2_year", "firmsize_u_2_year", "t_hours_others_year", "t_wage_nocompen_others_year", "t_wage_others_year", "t_hours_total_year", "t_wage_nocompen_total_year", "t_wage_total_year", "njobs", "t_hours_annual", "linc_nc", "laborincome")) d[[.name]][.age_mask] <- if (is.character(d[[.name]])) "" else NA_real_
rm(.age_mask, .name)

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
d <- d[!vapply(d,function(x) all((is.na(x) | (is.character(x) & as.character(x) == ""))), logical(1))]
for (nm in names(d)) {
  if (!is.null(value_labels[[nm]])) d[[nm]]<-haven::labelled(d[[nm]], value_labels[[nm]])
  if (!is.null(variable_labels[[nm]])) attr(d[[nm]],"label")<-variable_labels[[nm]]
}
filename <- file.path(path_output, OUT_FILE)
haven::write_dta(d,filename,version=14)
cat("Saved",nrow(d),"records and",ncol(d),"variables:",basename(filename),"\n")
