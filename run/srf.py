import os
import re
import numpy as np
import pandas as pd
import netCDF4 as nc
import xarray as xr
import matplotlib.pyplot as plt


#注意file修改


site = 'IT-SRo'
years = [2003,2004,2005,2006,2007,2008,2009,2010,2011,2012]
#years = [2010]

#years = [2013,2014]


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
















