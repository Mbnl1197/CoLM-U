import os
import re
import struct
import interval
import numpy as np
import pandas as pd
import netCDF4 as nc
from multiprocessing import Process
import xarray as xr



sites = ['IT-Cpz', 'DE-Gri', 'FI-Sod',  'ES-LMa',
            'SD-Dem', 'CZ-wet', 'AU-Cpr',
            'AU-Dry', 'DE-Geb',
            'AU-DaP', 'AU-DaS','US-NR1']




for site in sites:
    

    with open(f"./{site}_lctex.csh", "r") as f:
        file = f.readlines()
    file[74] = file[74].replace("tex","tex8",1)
    file[21] = file[21].replace("tex","tex8",1)

    with open(f'./{site}_lctex8.csh', "w") as f:
        for i in range(0,len(file),1):
            f.write(file[i])
    os.system(f"chmod 755 ./{site}_lctex8.csh")


    with open(f"./{site}_pfttex.csh", "r") as f:
        file = f.readlines()
    file[74] = file[74].replace("tex","tex8",1)
    file[21] = file[21].replace("tex","tex8",1)

    with open(f'./{site}_pfttex8.csh', "w") as f:
        for i in range(0,len(file),1):
            f.write(file[i])

    os.system(f"chmod 755 ./{site}_pfttex8.csh")





