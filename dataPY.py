import pandas as pd
import numpy as np
import os
from io import BytesIO
import requests, zipfile

#importing portion of urllib as well as libraries needed for my script
  
#all files are read and named by removing '.csv.gz'

Input_Data = 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'

data_file='data_py'

if not os.path.exists(data_file) : os.mkdir(data_file)
#zipped_data = urllib.request.urlopen(Input_Data).read()
 
if not os.path.exists(os.path.join(data_file,'mimic-iv-clinical-database-demo-1.0')):
  Zipped_Data =BytesIO(requests.get(Input_Data,stream=True).content)
  zipfile.ZipFile(Zipped_Data).extractall(data_file)
 
mimic = {filename.replace ('.csv.gz',''): pd.read_csv(dirpath + "/" + filename) 
    for dirpath, dirnames, filenames in os.walk(data_file) 
    for filename in filenames if filename.endswith('.gz')}

"""
A breif summary of dictionaries
mimic
#returns a dictionary

mimic.keys()
#returns list of table names within dataset

mimic.values()
#will return a series of dataframes without names.

mimic.items()
#returns dataframes and names
"""

democolumns = ['subject_id','insurance','marital_status','ethnicity']

def unique_concat(xx): 
  return ';'.join(xx.dropna().unique())
  
unique_concat(mimic['admissions'][democolumns])

demographics = mimic['admissions'][democolumns + ['deathtime']].assign(
  ethnicity = mimic['admissions']['ethnicity'].replace('UNABLE TO OBTAIN', 'UNKNOWN'),
  deathtime = lambda df : pd.to_datetime(df['deathtime'])
  ).drop_duplicates().groupby('subject_id').aggregate(
  {'insurance': unique_concat, 'marital_status': unique_concat, 'ethnicity':
    unique_concat, 'deathtime' : max }
    ).assign(ethnicity = lambda df : df['ethnicity'].replace(['WHITE;UNKNOWN', 'UNKNOWN;WHITE'], 'WHITE'))

demographics['ethnicity'].value_counts()

named_outputevents = mimic['outputevents'].merge(mimic['d_items'],how = 'left')

named_labevents = mimic['labevents'].merge(mimic['d_labitems'],how = 'left')

named_chartevents = mimic['chartevents'].merge(mimic['d_items'],how = 'left')

named_inputevents = mimic['inputevents'].merge(mimic['d_items'],how = 'left')

named_icd = mimic['diagnoses_icd'].merge(mimic['d_icd_diagnoses'],how = 'left')

admission_scaffold = mimic['admissions']

'''mimic['admissions'][['hadm_id','subject_id','admittime','dischtime']].assign(

    admittime=lambda df: pd.to_datetime(df['admittime'], errors='coerce'),

    dischtime=lambda df: pd.to_datetime(df['dischtime'], errors='coerce'),

    los=lambda df: np.ceil((df['dischtime'] - df['admittime']).dt.total_seconds() / 86400),

    date=lambda df: [pd.date_range(start, end, freq='D') for start, end in zip(df['admittime'], df['dischtime'])]

).explode('date');'''


'''admissions_scaffold<-transmute(admissions,hadm_id=hadm_id,subject_id=subject_id,
                               los = ceiling(as.numeric(dischtime - admittime) / 24),
                               date=map2(admittime,dischtime,
                                         function(xx,yy) {seq(trunc(xx,units="day"),yy,by="day")})) %>%
  unnest()'''
