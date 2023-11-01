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

SET @@dataset_id = 'ICU_Admissions_Data';