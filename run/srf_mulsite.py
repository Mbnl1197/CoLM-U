import os
import re
import numpy as np
import pandas as pd
import netCDF4 as nc
import xarray as xr
import matplotlib.pyplot as plt


#注意file修改


selyear_data = pd.read_csv('./select_year.csv',index_col=0)



sites = ['IT-Cpz', 'DE-Gri', 'FI-Sod',  'ES-LMa',
            'SD-Dem', 'CZ-wet', 'AU-Cpr',
            'AU-DaP', 'AU-DaS',
            'IT-SRo', 'IT-SR2']

sites = ['IT-Cpz','FI-Sod']


for site in sites:


    siteyear = []
    siteyears = selyear_data.loc[site].values[0]
    siteyears = siteyears.split(',')
    for year in siteyears:
        siteyear.append(int(year))
    siteyear = sorted(siteyear)
    years = np.arange(siteyear[0], siteyear[-1]+1)

    print(site,years)

    for year in years:


        with open(f"./{site}_PFT_fortex.csh", "r") as f:
            file = f.readlines()
        
        file[23] = f"set LC_YEAR     = {year} \n"
        file[74] = f"setenv DAT_SRFDIR $DAT_ROOT/srf/{site}_tex \n"
        # file[505] = f"print *, ppft(1,1,:)"

        with open(f'./{site}_srf.csh', "w") as f:
            for i in range(0,len(file),1):
                f.write(file[i])
        
        os.system(f'chmod 755 {site}_srf.csh')
        os.system(f'./{site}_srf.csh')
















