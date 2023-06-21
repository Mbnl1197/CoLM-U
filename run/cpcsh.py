import os
import re
import numpy as np
import pandas as pd
import netCDF4 as nc



sites = ['IT-Cpz', 'DE-Gri', 'FI-Sod', 'US-NR1', 'ES-LMa',
            'SD-Dem', 'AU-DaP', 'AU-DaS', 'CZ-wet', 'AU-Cpr']


for site in sites:

 
    with open(f"./{site}_lc.csh", "r") as f:
        file = f.readlines()
    
    file[21] = f"set CASE_NAME   = {site}_pft \n"
    file[106] =  file[106].replace("IGBP","PFT",1)


    with open(f'./{site}_pft.csh', "w") as f:
        for i in range(0,len(file),1):
            f.write(file[i])






    with open(f"./{site}_lctex.csh", "r") as f:
        file = f.readlines()
    
    file[21] = f"set CASE_NAME   = {site}_pfttex \n"
    file[106] =  file[106].replace("IGBP","PFT",1)

    with open(f'./{site}_pfttex.csh', "w") as f:
        for i in range(0,len(file),1):
            f.write(file[i])






