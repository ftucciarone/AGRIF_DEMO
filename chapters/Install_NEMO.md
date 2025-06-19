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
