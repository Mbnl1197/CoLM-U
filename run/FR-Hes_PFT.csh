#!/bin/tcsh

#-------------------------------------------------------
# [1] Define the JOB
#-------------------------------------------------------

set RUN_CLM_SRF="NO"     	# "YES" = MAKE CoLM surface characteristic data
                                # "NO"  = NOT make CoLM surface characteristic data

set RUN_CLM_INI="YES"    	# "YES' = MAKE CoLM initial data
                                # "NO"  = Restart run

set RUN_CaMa="NO"       	# "YES" = OPEN CaMa-Flood
                                # "NO"  = CLOSE CaMa-Flood [No river routing]

set RUN_CLM="YES"        	# "YES" = RUN CoLM
                                # "NO'  = NOT RUN CoLM


# case name and simulating time setting
#-------------------------------------------------------
set CASE_NAME   = FR-Hes_PFT
set GREENWICH   = .false.        	# 'true' for greenwich time, 'false' for local time
set LC_YEAR     = 2001
set START_YEAR  = 1993
set START_MONTH = 1             	# model start Month
set START_DAY   = 1             	# model start day
set START_SEC   = 0             	# model start secs of day
set END_YEAR    = 2007
set END_MONTH   = 1             	# model end month
set END_DAY     = 1             	# model end day
set END_SEC     = 0               	# model end secs of day
set SPIN_YEAR   = 1997
set SPIN_MONTH  = $START_MONTH    	# spin-up end month, set default to START_DAY
set SPIN_DAY    = $START_DAY      	# spin-up end day, set default to START_DAY
set SPIN_SEC    = $START_SEC      	# spin-up end sec, set default to START_SEC
set TIMESTEP    = 1800

set WOUT_FREQ   = DAILY         	# write output  file frequency: HOURLY/DAILY/MONTHLY/YEARLY
set WRST_FREQ   = YEARLY     		# write restart file frequency: HOURLY/DAILY/MONTHLY/YEARLY

# model resolution and running scope setting
#-------------------------------------------------------
set LON_POINTS  =  1
set LAT_POINTS  =  1
set EDGE_N      = 48.674
set EDGE_E      = 7.066
set EDGE_S      = 48.674
set EDGE_W      = 7.066

# set forcing observational height (unit: m)
#-------------------------------------------------------
set HEIGHT_V    =  18.0
set HEIGHT_T    =  18.0
set HEIGHT_Q    =  18.0


#-------------------------------------------------------
# [2] Set necessary environment variables
#-------------------------------------------------------

# clm src directory
#-------------------------------------------------------
setenv CLM_ROOT   $HOME/CoLM-U                  # <MARK #3>
setenv CLM_INCDIR $CLM_ROOT/include
setenv CLM_SRFDIR $CLM_ROOT/mksrfdata
setenv CLM_INIDIR $CLM_ROOT/mkinidata
setenv CLM_SRCDIR $CLM_ROOT/main
setenv CLM_POSDIR $CLM_ROOT/postprocess

# inputdata directory
setenv DAT_ROOT   /stu01/shijh21/data_forcing/inputdata                 # <MARK #4>
setenv DAT_RAWDIR /stu01/shijh21/data/CLMrawdata
setenv DAT_ATMDIR $DAT_ROOT/atm/loop4
setenv DAT_SRFDIR $DAT_ROOT/srf/FR-Hes
setenv DAT_RTMDIR $DAT_ROOT/rtm/CaMaMap_glb_15min_CRU

# file name of forcing and surface data
setenv DAT_SRFNAM FR-Hes_PFT.MOD.nc
setenv DAT_URBNAM urban-data-filename                  # only for urban model
setenv DAT_ATMNAM FR-Hes_1997-2006_LaThuile_Met.INT

# case directory
#-------------------------------------------------------
setenv CAS_ROOT   /stu01/shijh21/cases                   # <MARK #5>
setenv CAS_RUNDIR $CAS_ROOT/$CASE_NAME
setenv CAS_OUTDIR $CAS_RUNDIR/output
setenv CAS_RSTDIR $CAS_RUNDIR/restart

mkdir -p $DAT_SRFDIR
mkdir -p $CAS_RUNDIR
mkdir -p $CAS_OUTDIR
mkdir -p $CAS_RSTDIR

set use_mpi    = "NO"
set nproc      = 30
set use_openmp = "YES"
set nthread    = 92


#------------------------------------------------------
# [3] build define.h in ./include directory
#------------------------------------------------------

\cat >! .tmp << EOF
#define	USE_POINT_DATA            ! QIAN/PRINCETON/CRUNCEP/POINT
#define	PFT_CLASSIFICATION 4    ! IGBP/USGS
#undef	LAICHANGE                 ! change LAI for each year
#undef	LULCC                     ! Land use and land cover change
#undef	URBAN_MODEL               ! run urban community model
#undef	URBAN_TREE                ! run urban model with trees
#undef	URBAN_WATER               ! run urban model with water
#undef	URBAN_BEM                 ! run urban model with building energy model
#undef	URBAN_ONLY                ! only for urban patch output
#undef	RDGRID                    ! read user defined grid
#undef	RAWdata_update            ! update raw data
#undef	DYN_PHENOLOGY             ! empirical LAI f(soil T, root frac)
#undef	SOILINI                   ! soil initial stat from files
#define	LANDONLY                  ! land only. o/w. include sea
#define	SOIL_REFL_READ            ! soil color mapping file. o/w. guessed
#define	WO_${WOUT_FREQ}           ! output file frequency
#define	WR_${WRST_FREQ}           ! restart file frequency
#undef	CLMDEBUG                  ! model debug information
#define	HEIGHT_V $HEIGHT_V        ! reference height of wind speed
#define	HEIGHT_T $HEIGHT_T        ! reference height of temperature
#define	HEIGHT_Q $HEIGHT_Q        ! reference height of humidity
#define	lon_points $LON_POINTS    ! longitude points
#define	lat_points $LAT_POINTS    ! latitude points
EOF

#---------------------------------------

#----------------------------------------------

#-------------------------------------------------------#
#              --- USER SETTING END ---                 #
# DO NOT EDIT THE BELOW SCRIPTS UNLESS YOU KNOW EXACTLY #
# WHAT YOU ARE DOING                                    #
#-------------------------------------------------------#

if ( $use_mpi == "YES" ) then
    echo "#define usempi" >> .tmp
endif

if ( $use_openmp == "YES" ) then
    echo "#define OPENMP $nthread" >> .tmp
endif

if ( $RUN_CaMa == "YES" ) then
  echo "#define CaMa_Flood" >> .tmp
else
  echo "#undef  CaMa_Flood" >> .tmp
endif

sed -i 's/\!.*//g' .tmp
sed -i '/^ *$/d' .tmp

cmp --silent .tmp $CLM_INCDIR/define.h && rm -f .tmp || mv -f .tmp $CLM_INCDIR/define.h
cp -f $CLM_INCDIR/define.h $CAS_RUNDIR/define.h

set BRed   = '\033[1;31m'    # Bold Red
set BGreen = '\033[1;32m'    # Bold Green
set BWhite = '\033[1;37m'    # Bold White
set BOff   = '\033[0m'       # Text Reset

#-------------------------------------------------------
# [4] compling and executing CoLM surface data making
#-------------------------------------------------------
if ( $RUN_CLM_SRF == "YES" ) then

# Compile
echo "\n${BWhite}>>> Start Making the CoLM surface data...${BOff}"
cd $CLM_SRFDIR
make >& $CAS_RUNDIR/compile.mksrf.log || tail -n 10 $CAS_RUNDIR/compile.mksrf.log && \
echo "\n    ${BRed}Compiling Error! ${BOff}Please see $CAS_RUNDIR/compile.mksrf.log for details.\n" && exit 5

# Create an input parameter namelist file
\cat >! $CAS_RUNDIR/mksrf.stdin << EOF
&mksrfexp
casename = '$CASE_NAME'
dir_rawdata        = '$DAT_RAWDIR/'
dir_srfdata        = '$DAT_SRFDIR/'
lc_year            = $LC_YEAR
edgen              = $EDGE_N
edgee              = $EDGE_E
edges              = $EDGE_S
edgew              = $EDGE_W
/
EOF

# Executing CoLM initialization'
cp -vf $CLM_SRFDIR/srf.x $CAS_RUNDIR/
$CLM_SRFDIR/srf.x < $CAS_RUNDIR/mksrf.stdin |& tee $CAS_RUNDIR/exe.mksrf.log || \
echo "\n    ${BRed}Making surface data Error! ${BOff}Please see $CAS_RUNDIR/exe.mksrf.log for details.\n" && exit 4

echo "${BGreen}Making the CoLM surface data completed${BOff}"

endif



#-------------------------------------------------------
# [5] compling and executing CoLM initialization
#-------------------------------------------------------

cd $CLM_INIDIR

if ( $RUN_CLM_INI == "YES" ) then

# CoLM initialization for startup run
#-------------------------------------------------------
echo "\n${BWhite}>>> Start Making the CoLM initialization...${BOff}"
make >& $CAS_RUNDIR/compile.mkini.log || tail -n 10 $CAS_RUNDIR/compile.mkini.log && \
echo "\n    ${BRed}Compiling Error! ${BOff}Please see $CAS_RUNDIR/compile.mkini.log for details.\n" && exit 5

# Create an input parameter namelist file
\cat >! $CAS_RUNDIR/mkini.stdin << EOF
&clminiexp
casename = '$CASE_NAME'
dir_srfdata        = '$DAT_SRFDIR/'
dir_restart        = '$CAS_RSTDIR/'
nam_srfdata        = '$DAT_SRFNAM'
nam_urbdata        = '$DAT_URBNAM'
greenwich          = $GREENWICH
lc_year            = $LC_YEAR
s_year             = $START_YEAR
s_month            = $START_MONTH
s_day              = $START_DAY
s_seconds          = $START_SEC
/
EOF

cp -vf $CLM_INIDIR/initial.x $CAS_RUNDIR/
$CLM_INIDIR/initial.x < $CAS_RUNDIR/mkini.stdin |& tee $CAS_RUNDIR/exe.mkini.log || \
echo "\n    ${BRed}Making initialization Error! ${BOff}Please see $CAS_RUNDIR/exe.mkini.log for details.\n" && exit 4

echo "${BGreen}CoLM initialization completed${BOff}"

else if ( $RUN_CLM == "YES" ) then

# for restart run
#-------------------------------------------------------
echo $CAS_RUNDIR
if (! -e $CAS_RSTDIR/clmini.infolist.lc$LC_YEAR ) then
  echo "${BRed}ERROR: ${BOff}no initial run detected, please run clm initialization first!\n"; exit
endif

sed -e    "s/s_year *=.*/s_year    = ${START_YEAR}/"  \
    -e   "s/s_month *=.*/s_month   = ${START_MONTH}/" \
    -e     "s/s_day *=.*/s_day     = ${START_DAY}/"   \
    -e "s/s_seconds *=.*/s_seconds = ${START_SEC}/"   \
< $CAS_RSTDIR/clmini.infolist.lc$LC_YEAR > .tmp

mv -f .tmp $CAS_RSTDIR/clmini.infolist.lc$LC_YEAR

echo "${BGreen}CoLM initialization for restart run completed${BOff}"

endif



#-------------------------------------------------------
# [6] compliling CaMa Flood Model and make namelist file
#-------------------------------------------------------
if ( $RUN_CaMa == "YES" ) then

echo 'Compiling and initilizing CaMa'

setenv CaMa_DIR $CLM_ROOT/CaMa

set RESTART = 1
set SPINUP  = 2

set RESTART_FREQ = 2
if ( $WRST_FREQ == "YEARLY"  ) then
  set RESTART_FREQ = 0
endif
if ( $WRST_FREQ == "DAILY"   ) then
  set RESTART_FREQ = 1
endif
if ( $WRST_FREQ == "MONTHLY" ) then
  set RESTART_FREQ = 2
endif

# compile
cd $CaMa_DIR/gosh
chmod u+x compile.sh
./compile.sh >& $CAS_RUNDIR/compile.CaMa.log || exit 5
echo 'Compiling CaMa Flood Model completed'

# Create an input parameter namelist file for CaMa Flood Model
chmod u+x CaMa_CLM_grid.sh

if ($RUN_CLM_INI == "YES") then
./CaMa_CLM_grid.sh $CAS_RUNDIR $CAS_OUTDIR $CAS_RSTDIR $DAT_RTMDIR $TIMESTEP $SPINUP  $RESTART_FREQ
else
./CaMa_CLM_grid.sh $CAS_RUNDIR $CAS_OUTDIR $CAS_RSTDIR $DAT_RTMDIR $TIMESTEP $RESTART $RESTART_FREQ
endif

echo 'CaMa compiling and initialization completed'

endif



#-------------------------------------------------------
# [7] compiling and executing CoLM model
#-------------------------------------------------------
if ( $RUN_CLM == "YES" ) then

# Compile
cd $CLM_SRCDIR
rm -f $CAS_RUNDIR/compile.main.log

echo "\n${BWhite}>>> Start Making the CoLM...${BOff}"
make >& $CAS_RUNDIR/compile.main.log || tail -n 10 $CAS_RUNDIR/compile.main.log && \
echo "\n    ${BRed}Compiling Error! ${BOff}Please see $CAS_RUNDIR/compile.main.log for details.\n" && exit 5
cp -vf $CLM_SRCDIR/clmu.x $CAS_RUNDIR/

cd $CLM_POSDIR
make >& $CAS_RUNDIR/compile.post.log || tail -n 10 $CAS_RUNDIR/compile.post.log && \
echo "\n    ${BRed}Compiling Error! ${BOff}Please see $CAS_RUNDIR/compile.post.log for details.\n" && exit 5
cp -vf $CLM_POSDIR/bin2netcdf $CAS_RUNDIR/output/

echo "${BGreen}CoLM Compiling completed${BOff}"

# Create an input parameter namelist file
\cat >! $CAS_RUNDIR/timeloop.stdin << EOF
&clmexp
casename = '$CASE_NAME'
dir_srfdata        = '$DAT_SRFDIR/'
dir_atmdata        = '$DAT_ATMDIR/'
dir_output         = '$CAS_OUTDIR/'
dir_restart        = '$CAS_RSTDIR/'
nam_atmdata        = '$DAT_ATMNAM'
nam_srfdata        = '$DAT_SRFNAM'
nam_urbdata        = '$DAT_URBNAM'
deltim             = $TIMESTEP
solarin_all_band   = .true.
lc_year            = $LC_YEAR
e_year             = $END_YEAR
e_month            = $END_MONTH
e_day              = $END_DAY
e_seconds          = $END_SEC
p_year             = $SPIN_YEAR
p_month            = $SPIN_MONTH
p_day              = $SPIN_DAY
p_seconds          = $SPIN_SEC
EOF

\cat $CAS_RSTDIR/clmini.infolist.lc$LC_YEAR >> $CAS_RUNDIR/timeloop.stdin

#----------------------------------------------------------------------
# Executing the CoLM

echo "\n${BWhite}>>> Start Executing CoLM...${BOff}"
$CAS_RUNDIR/clmu.x < $CAS_RUNDIR/timeloop.stdin |& tee $CAS_RUNDIR/exe.timeloop.log || \
echo "\n    ${BRed}Executing Error! ${BOff}Please see $CAS_RUNDIR/exe.timeloop.log for details.\n" && exit 4

#if ( $use_mpi == "YES" ) then
#    /usr/bin/time -p /usr/bin/mpirun -np $nproc ./clm.x < $CAS_RUNDIR/timeloop.stdin
#else
#    ./clm.x < $CAS_RUNDIR/timeloop.stdin
#endif

echo "${BGreen}CoLM Execution Completed${BOff}"

endif

echo ''
echo '-----------------------------------------------------------------'
echo ' End of CoLM job c-shell script                                  '
echo '-----------------------------------------------------------------'
