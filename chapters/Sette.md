
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