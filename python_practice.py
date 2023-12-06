# Setting variables

#how to upload a python library 
import pandas as pd
import os


"""use repl_python() in order to enter python environment"""

foo = 1;
bar = "hello";
baz = 15

mylist = [1, 13, 1.5, -8]

"""in python a list is collection of values of any type (cannot have names)
dictionary is collection of values of various types and can include names
in dictionary, cannot pick an item based on position. In list you can select based on position."""

disposiblelist = [foo, bar, baz]

disposiblelist[1]

mylist[0,2]

#example of a dictionary
dictionary1={'var_a' : 3, 'var_b': 15, 'var_c' : 0}
#var_a, var_b, and var_c are keys to the values they are associated with

dictionary1['var_b']
dictionary1.get('var_b')
dictionary1.get('var_y') #will return a none result as this variable has not been created in the dictionary

mymissing = dictionary1.get('var_y')
type(mymissing) #demonstrating the none type response

dictionary2={'var_d' : 'Happy', 'var_e' : 'Thanksgiving'}
dictionary2
dictionary1.keys()
dictionary1.values()
dictionary1.items()
#dictionary comprehension
{kk:vv for kk,vv in dictionary1.items()};
{kk:vv for kk, vv in dictionary1.items() if kk in ['var_a', 'var_c']}

#list comprehension
[vv for vv in disposiblelist]
[vv for vv in disposiblelist if isinstance(vv, int)]
#Commonly used data types: str, int, float

#Pandas
df00 = pd.read_csv('data/mimic-iv-clinical-database-demo-1.0/hosp/d_hcpcs.csv.gz')
df00
os.listdir('data/mimic-iv-clinical-database-demo-1.0/')
[xx for xx,yy,zz in os.walk('data')]
file_list = [pd.read_csv(xx + "/" + filename) for xx, yy, zz in os.walk('data/mimic-iv-clinical-database-demo-1.0/') 
  for filename in zz if filename.endswith('.gz')]
