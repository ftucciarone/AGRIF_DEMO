# Nemo Hackaton 2025, an AGRIF journey

[AGRIF](https://agrif.imag.fr) (Adaptive Grid Refinement In Fortran) is a library that allows the seamless space and time refinement over rectangular regions in NEMO. Refinement factors can be odd or even (usually lower than 5 to maintain stability). Interaction between grids is “two-way” in the sense that the parent grid feeds the child grid open boundaries and the child grid provides volume/area weighted averages of prognostic variables once a given number of time steps are completed. This page provide guidelines for how to use AGRIF in NEMO. For a more technical description of the library itself, please refer to the [User's guide](https://agrif.imag.fr/agrifusersguide.html) [(pdf)](https://agrif.imag.fr/_downloads/agrifdoc_usersguide.pdf) or the [Reference manual](https://agrif.imag.fr/DoxygenGeneratedDoc/html/index.html) [(pdf)](https://agrif.imag.fr/_downloads/refman.pdf).


 
 
 Tutorial - draft
 
# Install dependencies (or link the dockerfile)

# Downloading and compiling NEMO 5.0.1

Downloading NEMO 5.0.1.
https://forge.nemo-ocean.eu/nemo/nemo/-/releases/5.0.1
 
#### 1.0) Download the Nemo code from GitLab, this can be done 'checking out' the 5.0 or 5.0.1 release from GitLab as

```shell
git clone --branch 5.0   https://forge.nemo-ocean.eu/nemo/nemo.git nemo-5.0
```
```shell
git clone --branch 5.0.1 https://forge.nemo-ocean.eu/nemo/nemo.git nemo-5.0.1
```
The NEMO Ocean Engine Reference manual has been updated for version 5.0 and can be downloaded at https://zenodo.org/records/14515373. 

> [!TIP] 
> If your architecture is not set up you can set it up with the `./build_arch-auto.sh` tool inside the `arch/` directory. Assuming NectCDF-C, NetCDF-F and HDF5 installed, you should have tools called `nc-config`, `nf-config` and `h5pcc`. Locate those tools (e.g. `which nc-config`) or alias them to the correct path and provide the path to `./build_arch-auto.sh` as:
> ```shell
> cd arch
> ./build_arch-auto.sh --NETCDF_C_prefix /path/to/nc-config --NETCDF_F_prefix /path/to/nf-config --HDF5_prefix /path/to/HDF5  --XIOS_prefix /path/to/XIOS
> ```
> where `/path/to/HDF5` can be found with `h5pcc -showconfig`. The path to XIOS is actually the download folder of XIOS. This tool with create the architecture file `arch/arch-auto.fcm`.

#### 1.1) Test the installation trying to compile a simple configuration, e.g. the Gyre configuration:
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
 
 
 
 
# Compiling and preparing a test case with SETTE
NEMO allows you to compile and run reference and test cases with a [SETTE](https://sites.nemo-ocean.io/user-guide/sette.html) environment and validate them. A complete guide to use SETTE is provided [here](https://sites.nemo-ocean.io/user-guide/sette.html#installation).

In this tutorial we will go through the AGRIF_DEMO case.

1) Create a param.cfg file
Inside the sette directory (nemo_5.0.1/sette/) you will need to create a param.cfg file using the template from param.defaul, with your job submission specifications and respective directories.
```shell
cp param.default param.cfg
```
The important things to modify are:
- `NEMO_VALIDATION_REF` path to the (input) validation dataset
- `NEMO_REV_REF` ID of the reference case that we want to test compatibility against
- `COMPILER` name of the `.fcm` file in the `/arch` directory that we use to compile nemo (e.g. `auto`)
- `BATCH_CMD` command you use to submit a job in your hpc (`sbatch`, `slurm`, `oarsub`, `bsub` and so on)
- `BATCH_STAT` command to check the queue (`oarstat`, `queues` and so on)
- `FORCING_DIR` path to the forcing 
- `NEMO_VALIDATION_DIR` path to the output of the validation 
- `JOB_PREFIX_NOMPMD` scriptfile language (bash, ksh ...) 
- `JOB_PREFIX_MPMD` 

> [!WARNING]  
> If you are installing Nemo and Sette on a machine that does not have a scheduler, worry not. Sette is going to create scripts (usually called `run_jobs`) inside each test folder. These scripts can be (slightly modified and) launched without the scheduler. 


2) Make sure you have the correct batch template for your job submission under `sette/BATCH_TEMPLATE/`, which contains the specifications required for your npc system.
 
To check how my submission will be:
grep -i bsub BATCH_TEMPLATE/*
if none of them suits your system you can create your own 
```shell
cp sette_batch_template batch-auto
```
> [!IMPORTANT]  
> The filename follows a strict syntax, and it has to be the same name as your architecture file (e.g. `arch-auto`) but prefixed by `batch` instead of `arch`.
The header of the newly created file reads:
```shell
#!/bin/bash
#!
# @ job_name = MPI_config
# standard output file
# @ output = $(job_name).$(jobid)
# standard error file
# @ error =  $(job_name).$(jobid)
# job type
# @ job_type = parallel
# Number of procs
# @ total_tasks = NPROCS
# time
# @ wall_clock_limit = 0:30:00
# @ queue
#
# Test specific settings. Do not hand edit these lines; the fcm_job.sh script will set these
# (via sed operating on this template job file).
#
  OCEANCORES=NPROCS
  export SETTE_DIR=DEF_SETTE_DIR
###############################################################
```
This part is the only part that has to be modified by the user. In particular, it should be changed accordingly to your job scheduler (or leave it as is if you don't plan to use a scheduler). It widely varies among scheduler, but an example with [OAR](oar.imag.fr) is
```shell
#!/bin/bash
#OAR -p cluster='cluster-name'
#OAR -l /host=1,walltime=24:00:00
#OAR -O /path/to/output/make.%jobid%.output
#OAR -E /path/to/output/make.%jobid%.error
```
Finally, set the Sette directory as
```
SETTE_DIR=/path/to/nemo-5.0/sette
```
  
3) Download input files by running `sette_fetch_inputs.sh`
> [!TIP] 
> In case you have problems with certificate, you can edit the `sette_fetch_inputs.sh`, look for the wget function and add the condition to ‘no certificate needed’:
> ```
> wget --no-check-certificate 
> https://gws-access.jasmin.ac.uk/public/nemo/sette_inputs/r${suff}/$full_file")
> ```

4) Compiling and running:
You can either just compile the NEMO code through the SETTE environment by running:
```shell
./sette.sh -n AGRIF_DEMO -x COMPILE
```
This will compile the `AGRIF_DEMO` creating the new configuration named `AGRIF_DEMO_ST` (it will add the suffix 'ST'). If you don't add the COMPILE condition, it will automatically compile NEMO and submit the jobs for running the different experiments available:
```shell
./sette.sh -n AGRIF_DEMO
```
 
If you want to create a new configuration different from a previous one you have already created, or with an additional suffix, you can compile using `-g X`:
```shell
./sette.sh -n AGRIF_DEMO -g 2
```
Please note that it has to be a single alphanumeric character (e.g. 2).
 
# Running a test case for `AGRIF_DEMO`
 
AGRIF_DEMO contains a set of different test cases:

1) AGRIF_DEMO_NOAGRIF_ST/ORCA2 (no key_agrif)
2) AGRIF_DEMO_ST/ORCA2 (no zooms but key agrif)
  check they are the same (sanity check)
3) AGRIF_DEMO_ST/LONG (This runs XX days and in the middle and the end creates a restart)
4) AGRIF_DEMO_ST/SHORT (This is to test restartability, it basically starts from the middle of LONG)
5) AGRIF_DEMO_ST/REPRO_2_8 (This check one MPI decomposition)
6) AGRIF_DEMO_ST/REPRO_4_4 (This check another MPI decomposition)

Both 1) and 2) contain only the global model simulation, while the following 3) to 6) cases contain all AGRIF subdomains for the multiple nesting strategy illustrated in Figure XX.

We can look at experiments 1), 2) and 3) to check the following conditions:
* Compile and run without agrif
* Compile and run with agrif, but no zooms
* Compile and run with agrif, one zoom but same resolution
* Compile and run with agrif plus zooms

When using AGRIF, the files correspondent to each nested model will be named with a prefix according to the hierarchy of the nesting. For this test case there is the global model with no prefix, and the subsequence of nested experiments are:
1= Agrif domain nested in the global model with the same horizontal and vertical resolution as the parent (1:1 ratio).
2= Agrif domain nested in the global model with a refinement of 4 (1:4)
3= Agrif subdomain nestes in model 2 with a refinement of 3.

The nomenclature of each model namelists, configuration file and forcing fields need to follow this rule (e.g. `1_namelist_cfg`, `1_namelist_ref`, `1_domain_cfg.nc`, `1_data_1m_salinity_nomask.nc`). The same is expected for the ouptut files (e.g. `1_ocean.output`, `1_AGRIF_DEMO_LONG_5d_00010101_00010331_grid_T.nc`).


The nested subdomain 3 has also a vertical refinement, which has to be activated in the 3_namelist_cfg:
ln_vert_remap   = .true. !  vertical remapping
 
Running the LONG test case for longer period:
To run agrif you need a configuration file that will define the hierarchy of all the agrif subdomains: AGRIF_FixedGrids.in
For the LONG test case we have a set of experiments
 
The example test case as it is set to run for a few time steps (nn_itend=16). In order to get more robust results for comparison between strategies, we can set the running period for longer.
If you wish to change the frequency of the output files you can also do so by editing the file_def_nemo-oce.xml. The default is 5d.
 
To enlarge the period of the simulation we need to update the nn_itend in the namelist. The current value is 16 for parent and child 1, 64 for child 2, and 192 for child 3.
For the parent model (namelist_cfg) and the first child model (1_namelist_cfg), the parameters are the same because there is no grid refinement and the time step is the same.
In the example in LONG, where we are running multiple nestings, you define the 2 in the top indicating that there will be 2 child subdomains in the ORCA2 parent model.
In the ORCA2 experiment, where we run just the global model separately without any nesting, the first parameter in the fixed grids is 0, which means no nesting.
