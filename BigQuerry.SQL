SET @@dataset_id = 'ICU_Admissions_Data';

SELECT STRING_AGG(column_name, ',') FROM ICU_Admissions_Data.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'd_items';

SET @@dataset_id = 'ICU_Admissions_Data';

/*
democolumns = c('subject_id','insurance', 'marital_status', 'ethnicity')

demographics = admissions %>% group_by(subject_id) %>%
  summarise(across(any_of(democolumns), unique_values)
            ,decease = any(!is.na(deathtime))
            ,deathtime = max(deathtime, na.rm = T)
              ) %>%
  mutate(ethnicity_revised = str_replace(ethnicity, 'UNKNOWN;', ''),
         ethnicity_revised_gsub = gsub('UNKNOWN;', '', ethnicity),
         )
demographics[is.infinite(demographics$deathtime), "deathtime"] = NA
demographics = demographics %>% left_join(patients[,c("subject_id", "gender","anchor_age")])

*/

--SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS demographics;
CREATE TABLE demographics as
With demo as
(SELECT subject_id,
  string_agg(DISTINCT insurance, "|") as insurance,
  string_agg(DISTINCT marital_status, "|") as marital_status,
  replace(replace(replace(string_agg(DISTINCT ethnicity, '|'), '|UNKNOWN', ''), 'UNKNOWN|', ''), '|OTHER','') as ethnicity,
  max(deathtime) as deathtime,
  max(CASE
    WHEN deathtime is not NULL THEN 1
    ELSE 0
  END) as decease
FROM admissions
GROUP BY subject_id)
SELECT demo.*, gender, anchor_age FROM demo
LEFT JOIN patients on demo.subject_id = patients.subject_id;

/*
named_labevents = labevents %>% left_join(d_labitems, by = c('itemid' = 'itemid'))
named_chartevents = chartevents %>% left_join(d_items, by = c('itemid' = 'itemid'))
named_inputevents = inputevents %>% left_join(d_items, by = c('itemid' = 'itemid'))
named_icd = diagnoses_icd %>% left_join(d_icd_diagnoses)
*/

--SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS named_labevents;
CREATE TABLE named_labevents as
SELECT labevents.*, label, fluid, category, loinc_code
FROM labevents
LEFT JOIN d_labitems on labevents.itemid = d_labitems.itemid;
--Go through to recrecate the named files from our R code

--SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS named_icd;
CREATE TABLE named_icd as
SELECT diagnoses_icd.*, long_title
FROM diagnoses_icd
LEFT JOIN  d_icd_diagnoses ON diagnoses_icd.icd_code = d_icd_diagnoses.icd_code;

--SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS named_input;
CREATE TABLE named_input AS
SELECT inputevents.*, label
FROM inputevents
LEFT JOIN d_items ON inputevents.itemid = d_items.itemid;

--SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS named_output;
CREATE TABLE named_output AS
SELECT outputevents.*, label
FROM outputevents
LEFT JOIN d_items ON outputevents.itemid = d_items.itemid;


/*WITH Recursive xx as(
  SELECT 1 MyNumber
  UNION ALL
  SELECT MyNumber + 1
  FROM xx
  WHERE xx.MyNumber <10
  )
SELECT * FROM xx
ORDER BY MyNumber;*/

/*admissions_scaffold<-transmute(admissions,hadm_id=hadm_id,subject_id=subject_id,
                               los = ceiling(as.numeric(dischtime - admittime) / 24),
                               date=map2(admittime,dischtime,
                                         function(xx,yy) {seq(trunc(xx,units="day"),yy,by="day")})) %>%
  unnest()*/


DROP TABLE IF EXISTS adm_scaffold;
CREATE TABLE adm_scaffold as
WITH RECURSIVE scaffold as(
  SELECT hadm_id, subject_id, Date(admittime) as hsp_date, Date(dischtime) as dischtime,
    date_diff(dischtime, admittime, day) as los
  FROM admissions
  UNION ALL
  SELECT hadm_id, subject_id, date_add (hsp_date, INTERVAL 1 day) hsp_date, dischtime, los
  FROM scaffold
  WHERE hsp_date < dischtime
)

SELECT *
From scaffold
ORDER BY hadm_id,hsp_date;

/*
icu_scaffold = icustays %>% transmute( hadm_id, subject_id , stay_id ,
                                       ICU_los = ceiling(as.numeric(outtime - intime) / 1440),
                                       ICU_date = purrr::map2(intime,outtime, function(xx,yy)
                                         seq(trunc(xx,units = 'days'),yy, by = 'day'))
                                       ) %>% tidyr::unnest(ICU_date) %>%
  group_by(hadm_id, subject_id, ICU_date) %>%
  #summarise(ICU_los=paste(ICU_los, collapse = ";"), stay_id=paste(stay_id, collapse = ";"))
  summarise(
    ICU_los = list(ICU_los),  # Convert ICU_los to a list
    stay_id = list(stay_id)   # Convert stay_id to a list
  )
*/

SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS ICU_scaffold;
CREATE TABLE ICU_scaffold as
  WITH RECURSIVE scaffold as(
      SELECT hadm_id,subject_id,stay_id,  ceiling(los) as ICU_revised_los, Date(intime) as ICU_date, intime, Date(outtime) as outtime,los as ICU_los
      FROM icustays
      UNION ALL
      SELECT hadm_id,subject_id,stay_id, ICU_revised_los, date_add(ICU_date, INTERVAL 1 day) as ICU_date, intime, outtime, ICU_los
      FROM scaffold
      WHERE ICU_date < outtime
    )
    SELECT hadm_id,subject_id, stay_id, ICU_date, intime, ICU_revised_los as ICU_los
    FROM scaffold
    ORDER BY hadm_id, ICU_date;

/* main_data <- left_join(admissions_scaffold, icu_scaffold,
                           by=c("hadm_id"="hadm_id",
                                "subject_id"="subject_id",
                                "date"="ICU_date"))
*/

SET @@dataset_id = 'ICU_Admissions_Data';
DROP TABLE IF EXISTS main_data;
CREATE TABLE main_data as
  WITH q0 AS(
    SELECT adm_scaffold.*, stay_ID, ICU_LOS,
      ROW_NUMBER() OVER (PARTITION BY adm_scaffold.hadm_id, hsp_date ORDER BY intime) AS rn
    FROM adm_scaffold
    LEFT JOIN ICU_scaffold ON adm_scaffold.hadm_id = ICU_scaffold.hadm_id AND adm_scaffold.hsp_date = ICU_scaffold.ICU_date
    )
SELECT *
FROM q0 WHERE rn = 1
ORDER BY hadm_id, hsp_date;



    --END



SET @@dataset_id = 'ICU_Admissions_Data';

CREATE OR REPLACE PROCEDURE count_dups(
  tablename STRING, columnname STRING, selectname STRING, dataset STRING
)
BEGIN
  DECLARE mydataset STRING; DECLARE sqlquery STRING;
  SET mydataset = (SELECT COALESCE(dataset, 'ICU_Admissions_Data'));
  SET sqlquery = concat('SELECT ',columnname , 'FROM ', mydataset, '.', tablename);
  SELECT sqlquery;
  EXECUTE IMMEDIATE sqlquery
;
END;

CALL ICU_Admissions_Data.count_dups('ICU_scaffold', 'hadm_id, stay_id ', NULL, NULL )