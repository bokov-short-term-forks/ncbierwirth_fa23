#'---
#' title: "Data Extraction"
#' author: 'Author One ^1^, Author Two ^1^'
#' abstract: |
#'  | Import data from an online source for use by the remaining scripts in this
#'  | project.
#' documentclass: article
#' description: 'Manuscript'
#' clean: false
#' self_contained: true
#' number_sections: false
#' keep_md: true
#' fig_caption: true
#' output:
#'  html_document:
#'    toc: true
#'    toc_float: true
#'    code_folding: show
#' ---
#'
#+ init, echo=FALSE, message=FALSE, warning=FALSE
# init ----
# This part does not show up in your rendered report, only in the script,
# because we are using regular comments instead of #' comments
debug <- 0;
knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0);

library(ggplot2); # visualisation
library(GGally);
library(rio);# simple command for importing and exporting data
library(pander); # format tables
library(printr); # automatically invoke pander when tables are detected
library(broom); # standardized, enhanced views of various objects
library(dplyr); # table manipulation
library(fs);    # file system operations
library(purrr)
library(tidyr)
library(stringr)

#options
options(datatable.na.strings=c('NA','NULL',''));

democolumns <- c('subject_id','insurance','marital_status','ethnicity')

length_unique<-function(xx){
  unique(xx) %>% length()
}
#creating a function in order to identify and count unique variables within our dataframe

unique_vals<-function(xx){
  unique(xx) %>% sort() %>% paste(collapse =";")
}

count_by_freq = . %>% summarise(n=n(),patients=length_unique(subject_id)) %>% arrange(desc(n))


options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);

#' # Import the data
#' #If data.R.rdata does not exist, code will create "Input_data"

if(!file.exists('data.R.rdata')){
  Input_Data <- 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'; #create value "Input_Data"
  dir.create('data',showWarnings = FALSE); #Creates a folder titled 'data'
  Zipped_Data <- file.path("data",'tempdata.zip'); #creates Zipped_data which is essentially instructions on where to send the downloaded file
  download.file(Input_Data,destfile = Zipped_Data); #dowloads "Input_Data" and sends file to the data folder, titles it tempdata.zip
  Unzipped_Data <- unzip(Zipped_Data,exdir = 'data') %>% grep('gz$',.,val=T);
  #unzips the zipped file, selects only for files containing gz which filters out directory data
  Table_Names <- path_ext_remove(Unzipped_Data) %>% path_ext_remove() %>% basename;
  #extracts name of each table
  for(ii in seq_along(Unzipped_Data)) assign(Table_Names[ii],import(Unzipped_Data[ii],format='csv'));
  #mapply(function(aa,bb) assign(aa,import(bb,format='csv'),inherits = T),Table_Names,Unzipped_Data)
  save(list=Table_Names,file='data.R.rdata');
  message('data downloaded')
} else{
    message('data already present')
  load("data.R.rdata")
  }

#subject IDs are unique within patients table
unique(patients$subject_id) %>% length()

nrow(patients) #100 total patients in dataset

is.na(patients$dod) %>% sum() #ensured that patients are not deceased

admissions[,democolumns] %>% unique() %>% nrow()
#even after controlling for what should be unique variables, we have 116 unique lines in our dataset

sapply(admissions[,democolumns],length_unique)
sapply(admissions[,democolumns],function(xx)unique(xx) %>% length())
#just showing that our function does the same thing

summarise(admissions[,democolumns]
          ,subject_id=length_unique(subject_id)
          ,insurance=length_unique(subject_id)
          )

summarise(admissions[,democolumns]
          ,across(any_of(democolumns), length_unique))

group_by(admissions,subject_id) %>% summarise(across(any_of(democolumns), length_unique)) %>% head()
#marital status, insurance, and ethnicity have duplicates

unique(admissions$insurance)

table(admissions$language)
#only contains english or ? so probably not a useful demographic tab to include

table(admissions$marital_status)
table(admissions$ethnicity)
#marital status and ethnicity contain relevant differences.

#' # Demographic Table
#'

demographics<-group_by(admissions,subject_id) %>%
  summarise(across(any_of(democolumns), unique_vals),
            deceased=any(!is.na(deathtime)),
            deathtime=max(deathtime, na.rm = TRUE)) %>%
  mutate(ethnicity=gsub("UNKNOWN;","",ethnicity)) %>%
  mutate(ethnicity=gsub("UNABLE TO OBTAIN","UNKNOWN",ethnicity)) %>%
  left_join(patients[,1:3])

# Creating named event tables

named_outputevents<-left_join(outputevents,d_items)

named_labevents<-left_join(labevents,d_labitems)

named_chartevents<-left_join(chartevents,d_items)

named_inputevents<-left_join(inputevents,d_items)

named_icd<-left_join(diagnoses_icd,d_icd_diagnoses)

#Assess most frequent diagnoses

named_icd$long_title %>% table() %>% sort(decreasing = TRUE)

#potential variables (Lab/glucose, lab/A1c, diagnosis/hypoglycemia, diagnosis/hyperglycemia death, ICU stay, length of ICU stay)

admissions_scaffold<-transmute(admissions,hadm_id=hadm_id,subject_id=subject_id,
                               los = ceiling(as.numeric(dischtime - admittime) / 24),
                               date=map2(admittime,dischtime,
                                         function(xx,yy) {seq(trunc(xx,units="day"),yy,by="day")})) %>%
  unnest()

#scaffold of ICU dates

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


hist(icustays$los, breaks = 100)

sapply(.GlobalEnv,is.data.frame) %>% .[.] %>% names() %>%
  sapply(., function(xx) get(xx) %>% colnames() %>% grepl('stay_id',.) %>% any()
         %>% .[.] %>% names() %>% sapply(.,function(xx) get(xx) %>% colnames()))

group_by(icu_scaffold,subject_id,ICU_date) %>%
     summarise(number = n(),number_stays = length(unique(stay_id))) %>% subset(number>1) %>%
     pull(subject_id) %>% {subset(icustays,subject_id %in% .)} %>% arrange(subject_id, intime)

#each ICU stay is fully unique

#combine ICU and admission days into main data set
main_data <- left_join(admissions_scaffold, icu_scaffold,
                           by=c("hadm_id"="hadm_id",
                                "subject_id"="subject_id",
                                "date"="ICU_date"))

hypoglycemia_data <- c('E11649', "E162", "E161", "E160", "E13141", "E15") %>% paste(.,collapse = '|') %>%
  {subset(named_icd, grepl(.,icd_code))}

named_icd[grep('hypoglycemia', named_icd$long_title, ignore.case = TRUE),]

#homework, left join our selected ICD-10 codes to be "yes or no hypoglycemia" to main_data

hypoglycemia_demo<-left_join(main_data, hypoglycemia_data, by = "subject_id")
hypoglycemia_demo$hypoglycemia<-ifelse(hypoglycemia_demo$long_title==NA,0,1)

#Group ICD-10 codes by decending frequencies
forcats::fct_count(named_icd$icd_code, sort = TRUE) %>% View()

#Gives the highest frequncy of ICD-10 diagnosis
dplyr::group_by(named_icd,icd_code,long_title) %>% summarize(n=n(), patients = length_unique(subject_id)) %>%
  arrange(desc(n))

#Looking at hypertension instead, this code gives all our "hypertension" ICD-10s
subset(named_icd,str_detect(long_title,"hypertension")) %>% select(icd_code) %>% unique()

#create hypertensin list
htn_adm = named_icd %>%  subset(str_detect(tolower(long_title),'hypertension')) %>%
  pull(hadm_id) %>% unique()

#create row for patients with or without hypertension
main_data <- left_join(admissions_scaffold, icu_scaffold,
                       by=c("hadm_id"="hadm_id",
                            "subject_id"="subject_id",
                            "date"="ICU_date")) %>%
  mutate(hypertension=hadm_id %in% htn_adm)

group_by(named_labevents,category,fluid,loinc_code,label) %>%
  summarize(n=n(),patients=length_unique(subject_id)) %>%
  arrange(desc(n)) #%>% View()

named_labevents %>% mutate(charttime=as.Date(charttime)) %>%
  filter(itemid ==50820) %>% select(subject_id, hadm_id, charttime, valuenum) %>%
  group_by(subject_id, charttime) %>% summarise(pH = min(valuenum)) %>% arrange(desc(pH))

named_labevents %>% mutate( charttime = as.Date(charttime)) %>%
  filter(itemid == 50820) %>%
  group_by(subject_id, charttime) %>%
  summarise(pH = min(valuenum)) %>%  arrange(desc(pH))

pH_table = named_labevents %>% mutate( charttime = as.Date(charttime)) %>%
  filter(itemid == 50820) %>%
  group_by(subject_id, charttime) %>%
  summarise(pH = min(valuenum), pH_flag = any(flag=='abnormal')) %>%
  arrange(desc(pH))

#named variables
vital_abrev<-c(HR="Heart Rate",aSBP="Arterial Blood Pressure systolic",
  mSBP="Manual Blood Pressure Systolic Left")

analytic_events <- named_chartevents %>%  group_by(label, subject_id, date= as.Date(charttime)) %>%
  # count_by_freq() %>%
  filter(label %in% vital_abrev) %>%
  summarize(median_value = median(valuenum, na.rm=TRUE)) %>%
  pivot_wider(values_from = median_value, names_from = label) %>%
  rename(any_of(vital_abrev))

main_data <- main_data %>%
  left_join(pH_table,by = c('subject_id', 'date' = 'charttime')) %>%
  left_join(analytic_events) %>%
  left_join(demographics)

explore::explore_shiny(main_data)

table(main_data$hypertension)
