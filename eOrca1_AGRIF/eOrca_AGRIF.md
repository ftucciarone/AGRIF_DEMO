# Procedure to build an Agrif Zoom in the eOrca 1 configuration

### First, create the folder for the project
These lines first define the base directory (i.e. where the folder for the project will be created) and the project directory.
```shell
export Base_dir=/home/$USER/
export Proj_dir=eORCA1
export Root_dir=$Base_dir/$Proj_dir
mkdir -p $Root_dir
cd $Root_dir
```
This example creates a folder called `eORCA1` in the home directory of the current user. This folder will be the root folder (`$Root_dir`) for the rest of these instructions.

### Download and (hopefully) compile NEMO
Download the Nemo code from GitLab, this can be done 'checking out' the 5.0.1 release from GitLab as
```shell
cd $Root_dir
git clone --branch 5.0.1 https://forge.nemo-ocean.eu/nemo/nemo.git nemo-5.0.1
cd $Root_dir/nemo-5.0.1
```
The [NEMO Ocean Engine Reference manual](https://zenodo.org/records/14515373) has been updated for version 5.0 and can be downloaded at [https://zenodo.org/records/14515373 (direct download)](https://zenodo.org/records/14515373/files/NEMO_manual.pdf?download=1). 

> [!TIP] 
> If your architecture is not set up you can set it up with the `./build_arch-auto.sh` tool inside the `arch/` directory. Assuming NectCDF-C, NetCDF-F and HDF5 installed, you should have tools called `nc-config`, `nf-config` and `h5pcc`. Locate those tools (e.g. `which nc-config`) or alias them to the correct path and provide the path to `./build_arch-auto.sh` as:
> ```shell
> cd arch
> ./build_arch-auto.sh --NETCDF_C_prefix /path/to/nc-config --NETCDF_F_prefix /path/to/nf-config --HDF5_prefix /path/to/HDF5  --XIOS_prefix /path/to/XIOS
> ```
> where `/path/to/HDF5` can be found with `h5pcc -showconfig`. The path to XIOS is actually the download folder of XIOS. This tool with create the architecture file `arch/arch-auto.fcm`.

> [!WARNING]
> ```
> export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/lib/libhdf5
> ```
##### Test the installation trying to compile a simple configuration, e.g. the Gyre configuration:
```shell
./makenemo -m 'auto' -r GYRE_PISCES -n 'MY_GYRE' -j 8
```
if the compilation is successful you should be able to run Nemo with
```shell
cd cfgs/MY_GYRE/EXP00
./nemo
```
and then remove it if not needed
```shell
./makenemo -m 'auto' -r GYRE_PISCES -n 'MY_GYRE' -j 8 clean_config
```

### Download the data repository (courtesy of Casimir de Lavergne [<img style="position:absolute; top:0px;" width="20px" src="https://orcid.org/assets/vectors/orcid.logo.icon.svg" />](https://orcid.org/0000-0001-9267-7390))
> [!WARNING] 
> The author of this repository, Francesco L. Tucciarone, was not involved in the development of the original configuration, thus he shall not be referenced. When using the configuration from this repository, only cite the original work done by Casimir de Lavergne and the other contributors. Minor adjustements were done to port the original configuration (running with NEMO 4.2.2) to NEMO 5.0.1, but they were almost trivial and not enough to grant F.L.T. authorship.

This work is based on the configuration that has been described in
> de Lavergne C., Rathore S., Madec G., Sallée J.-B., Ethe C., Nasser A., Millet B. and Vancoppenolle M.: _Effects of improved tidal mixing in NEMO one-degree global ocean model_. ESS Open Archive . November 13, 2024. DOI: [10.22541/essoar.173152139.95978362/v1](https://doi.org/10.22541/essoar.173152139.95978362/v1)

whose data can be found in the Zenodo repository:
> de Lavergne C., Rathore S., Madec G., Sallée J.-B., Ethe C., Nasser A., Millet B. and Vancoppenolle M.: _NEMO4.2 eORCA1 configuration files for stable millennial ocean simulations (1.0)_. 2024, [Data set]. Zenodo. https://doi.org/10.5281/zenodo.14041098

As a first step, download the repository with `wget` and unzip it:
```shell
cd $Root_dir
wget https://zenodo.org/records/14041098/files/data_repository.zip
unzip data_repository.zip
```
```
.
└── $Root_dir/
    ├── data_repository/
    │   ├── code/ # Original code for the paper, not of interest for us
    │   ├── initial_conditions/                # Initial conditions for Temperature and Salinity
    │   │   ├── woce_salt_monthly_init_4p2.nc 
    │   │   └── woce_temp_monthly_init_4p2.nc
    │   ├── input_fields/                              # Static files
    │   │   ├── domain_cfg.nc                          # Domain File
    │   │   ├── eddy_viscosity_3D.nc                   # Eddy viscosity (3D)
    │   │   ├── geothermal_heat_flux.nc                # Geothermal Heat Flux
    │   │   ├── merged_ESACCI_BIOMER4V1R1_CHL_REG05.nc # Chlorophill I guess
    │   │   ├── runoff-icb_DaiTrenberth_Depoorter.nc   # River run-off
    │   │   ├── sss_climatology_for_restoring.nc       # Climatology SSS restoring
    │   │   ├── weights_ghflux_bilinear.nc             # On-the-fly interpolation weights 
    │   │   ├── weights_reg05_bilinear.nc              # On-the-fly interpolation weights
    │   │   └── zdfiwm_forcing_*.nc                    # Internal waves mixing (only one needed)
    │   ├── namelists/ # Original namelists for NEMO 4.2.2, not of interest for us
    │   └── restart/ # Restart files 
    │       ├── TRA_10001231_restart_icemod.nc # Ice Model restart
    │       ├── TRA_10001231_restart_trc.nc    # Tracer Model restart
    │       └── TRA_10001231_restart.nc        # Ocean Model restart
    ├── data_repository.zip
    └── nemo-5.0.1/       # Source code for NEMO version X.Y.Z
```



### Compilation of the base cofiguration
0) Define a name for the experiment:
```shell
export Cfg_name=eOrca1_exp01
```
1) The eOrca1 configuration can be built starting from the shipped reference configuration `ORCA2_ICE_PISCES`. First, lets duplicate this configuration with the command
```shell
./makenemo -m 'auto' -r ORCA2_ICE_PISCES -n $Cfg_name -j 0;
```
where `-j 0` sets the number of processors for compilation to 0: with this peculiar choice the command `./makenemo` will only duplicate and rename the necessary files without compiling.

2) Modify the `cpp_*.fcm`: the file `$Root_dir/nemo-5.0.1/cfgs/$Cfg_name/cpp_$(Cfg_name).fcm` should contain the following line
```
bld::tool::fppkeys   key_si3 key_xios key_qco key_isf key_vco_1d3d key_RK3
```

3) Compile the code
```shell
./makenemo -m 'auto' -r ORCA2_ICE_PISCES -n $Cfg_name -j 8;
```

### Linking the static files
First, change the directory to the configuration experiment directory
```shell
cd $Root_dir/nemo-5.0.1/cfgs/$Cfg_name/EXP00/
```
then create a shell executable named `make_links.sh` with the following content:
```shell
#!/bin/bash
static_dir=/home/ftucciarone/ithaca/nemo-ensembleruns/input-eOrca1

#
# Input domain file
#
ln -sf $static_dir/input_fields/domain_cfg.nc .

#
# Input restart files
#
ln -sf $static_dir/restart/*.nc .

# Rivers run-off
ln -sf $static_dir/input_fields/runoff-icb_DaiTrenberth_Depoorter.nc .
# Internal waves mixing
ln -sf $static_dir/input_fields/zdfiwm_forcing_TRA.nc .
# Geothermal heat flux
ln -sf $static_dir/input_fields/geothermal_heat_flux.nc .
# Eddy viscosity (3D)
ln -sf $static_dir/input_fields/eddy_viscosity_3D.nc .
# Climatology SSS restoring
ln -sf $static_dir/input_fields/sss_climatology_for_restoring.nc .
# Chlorophill I guess
ln -sf $static_dir/input_fields/merged_ESACCI_BIOMER4V1R1_CHL_REG05.nc .
#
# On-the-fly interpolation weights
#
ln -sf $static_dir/input_fields/weights_ghflux_bilinear.nc .
ln -sf $static_dir/input_fields/weights_reg05_bilinear.nc .
#
# Initial conditions
#
ln -sf $static_dir/initial_conditions/woce_temp_monthly_init_4p2.nc .
ln -sf $static_dir/initial_conditions/woce_salt_monthly_init_4p2.nc .
#
# Forcings
#
ln -sf $static_dir/forcing_ORCA1/* .
```
make it executable as 
```shell
chmod +x make_links.sh
```
and finally execute it as `./make_links.sh`. This will create links to the static files inside the experiment folder, so that the namelist will find all the necessary data.

## Create the AGRIF zoom
Here we follow the [official guide](https://sites.nemo-ocean.io/user-guide/zooms.html)

In particular, to avoid compilation issues, we run `./makenemo clean` on the configuration before activating `key_agrif` the first time.
```shell
./makenemo -m 'auto' -r ORCA2_ICE_PISCES -n $Cfg_name -j 8 clean;
```
and then we add the options for AGRIF as
```shell
./makenemo -m 'auto' -r ORCA2_ICE_PISCES -n $Cfg_name -j 8 -d 'OCE ... NST' add_key 'key_agrif';
```

### Create the `AGRIF_FixedGrids.in` file
Mediterranean 1/12 (double refinement)
```shell
1
250 350 205 285 3 3 3
1
 80 230  80 160 4 4 4
0
```
Southern Pacific Zoom
```
1
108 208  65 165 3 3 3
0
```
Both
```
2
108 208  65 165 3 3 3
250 350 205 285 3 3 3
0
1
 80 230  80 160 4 4 4
0
```

# Creating the `domain_cfg.nc` file with `DOMAINcfg` tool
First of all, it is safer to create a bash script to copy the important files to the DOMAINcfg folder. This is critical as the tool will overwrite the input `domain_cfg.nc` file, hence at every time one has to re-run the procedure one has to copy the input files again.
```shell
#!/bin/bash
root_dir=/path/to/work/dir
eOrca_input_dir=$root_dir/input-eOrca1
AGRIF_input_dir=$root_dir/input-AGRIF

#
# Input domain file
#
cp $eOrca_input_dir/input_fields/domain_cfg.nc .
cp $AGRIF_input_dir/DOMAINcfg/namelist_cfg .
# The bathymetry is not modified, hence one can actually just link it
ln -s $AGRIF_input_dir/GEBCO_2020.nc .
```
The `namelist_cfg` file should be edited with the dimensions of the input `domain_cfg.nc` file. The dimension can be checked with 
```shell
ncdump -h domain_cfg.nc
```
and then included in the namelist file as shown below:
### In namelist_cfg 
```
!-----------------------------------------------------------------------
&namcfg        !   parameters of the configuration
!-----------------------------------------------------------------------
   !
   ln_e3_dep   = .true.    ! =T : e3=dk[depth] in discret sens.
   !                       !      ===>>> will become the only possibility in v4.0
   !                       ! =F : e3 analytical derivative of depth function
   !                       !      only there for backward compatibility test with v3.6
      !                      ! if ln_e3_dep = T
      ln_dept_mid = .true.   ! =T : set T points in the middle of cells
   !                       !
   cp_cfg      =  "orca"   !  name of the configuration
   jp_cfg      =       2   !  resolution of the configuration
   jpidta      =     360   !  1st lateral dimension ( >= jpi )
   jpjdta      =     331   !  2nd    "         "    ( >= jpj )
   jpkdta      =      75   !  number of levels      ( >= jpk )
   Ni0glo      =     360   !  1st dimension of global domain --> i =jpidta
   Nj0glo      =     331   !  2nd    -                  -    --> j  =jpjdta
   jpkglo      =      75
   jperio      =       4   !  lateral cond. type (between 0 and 6)
   ln_domclo = .false.     ! computation of closed sea masks (see namclo)
/
```
one has to manually insert the dimensions of the parent grid here!!!

## Creating the Weights for Interpolation on the fly


