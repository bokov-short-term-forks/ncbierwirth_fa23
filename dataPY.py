import pandas as pd
import os
import urllib.request #importing portion of urllib

mimic = {filename.replace('.csv.gz','') : pd.read_csv(xx + "/" + filename) for xx, yy, zz in os.walk('data/mimic-iv-clinical-database-demo-1.0/') 
  for filename in zz if filename.endswith('.gz')}
  
mimic['patients']

mimic.keys()
#all files are read and named by removing '.csv.gz'

"""Input_Data <- 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'; #create value "Input_Data"
  dir.create('data',showWarnings = FALSE); #Creates a folder titled 'data'
  Zipped_Data <- file.path("data",'tempdata.zip'); #creates Zipped_data which is essentially instructions on where to send the downloaded file
  if(!file.exists(Zipped_Data)){download.file(Input_Data,destfile = Zipped_Data)}; #dowloads "Input_Data" and sends file to the data folder, titles it tempdata.zip
  Unzipped_Data <- unzip(Zipped_Data,exdir = 'data') %>% grep('gz$',.,val=T);
"""

Input_Data = 'https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip'


if not os.path.exists('data') : os.mkdir('data')
zipped_data = urllib.request.urlopen(Input_Data).read()
foo = zipped_data.decode()

