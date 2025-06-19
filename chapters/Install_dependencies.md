# Nemo dependencies
> [!WARNING]
> *Lasciate ogne speranza, voi ch'intrate*

> [!IMPORTANT]
> These instruction are not going to be bulletproof. We built them upon the work of previous wise men. Among them, in alphabetical order, honorable mentions should be addressed to 
> * [Romain Caneill](https://romaincaneill.fr), (role unknown) wrote a great [apptainer](https://github.com/rcaneill/xnemogcm_test_data) with all the dependencies;
> * [Julian Mak](https://julianmak.github.io), NEMO System Team member, wrote incredible notes and [made them available](https://nemo-related.readthedocs.io/en/latest/index.html);
> * [Sebastian Masson](https://forge.nemo-ocean.eu/users/smasson/snippets), NEMO System Team member;
> * [Yann Meurdesoif](chapters/Install_dependencies.md), main developer and maintainer of XIOS.


Nemo requires a set of fairly complicated dependencies. Among these we have 
* C/C++ compiler (we will install gcc and g++);
* Fortran compiler (we will install gfortran);
* MPI, Message Passing Interface (we will install both mpich and openmpi);
* NetCDF-C;
* NetCDF-Fortran;
* HDF5;
* XIOS (Optional but highly recommended).
Other important libraries and tools to be installed are svn, wget, git, make 

> [!WARNING]
> We will install also libcurl4-openssl-dev, m4, liburi-perl, libxml2-dev, but frankly I don't know what they are or why we are doing this. The original tutorial 

### Step 1: Define the installation parameters
This procedure will create directories, download tarballs and sources, install libraries. In particular, it will create folders to manage easily the installation points. The final structure will be as the following tree:
```
.
└── $ROOT/
    ├── nemo-deps/
    │   ├── sources/      # Here you will the original tarballs
    │   ├── installs/     # Here you will have the installation points
    │   │   ├── bin/
    │   │   ├── include/
    │   │   ├── lib/
    │   │   └── share/
    │   └── XIOS/         # Source code for XIOS
    │       └── XIOS-X.Y/ # Specific XIOS version  
    └── nemo-X.Y.Z/       # Source code for NEMO version X.Y.Z
```
The basic idea is that `nemo-deps` will contains all the dependencies and it is separated from `nemo-X.Y.Z` which contians the source code of the nemo code. In this way you can have multiple versions of NEMO based on the same dependencies. `XIOS` lives in its own directory because different versions of it are available (and not all of them are compatible with some specific version of NEMO) and thus it's safer to have it this way. 

The only thing that should be modified by the user is the `ROOT` variable, that specifies the root folder where everything will be done. 

The following snippet contains the parameters to set up the directories tree and the compilers to use. This section can be copy-pasted in a file called `install_params.sh` and then sourced. 
```shell
# Let's base ourselves in the base directory
ROOT=$HOME
# Echo where we work
echo $ROOT

# Installation directories
export WORKDIR=$ROOT/nemo-deps/sources
export INSTDIR=$ROOT/nemo-deps/installs
export XIOSDIR=$ROOT/nemo-deps/XIOS
export NEMODIR=$ROOT
mkdir -p $WORKDIR
mkdir -p $INSTDIR
mkdir -p $XIOSDIR

# compilers
export CC=/usr/bin/mpicc
export CXX=/usr/bin/mpicxx
export FC=/usr/bin/mpif90
export F77=/usr/bin/mpif77

# compiler flags (except for libraries)
export CFLAGS="-O3 -fPIC"
export CXXFLAGS="-O3 -fPIC"
export F90FLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
export FFLAGS="-O3 -fPIC"
export LDFLAGS="-O3 -fPIC "

# FLAGS FOR F90  TEST-EXAMPLES
export FCFLAGS_f90="-O3 -fPIC "
```

### Step 2: Install the packages
This part should be adapted, depending on the machine you are using. In this example, an Ubuntu machine is used and thus the package manager is `apt`. 
```shell
# Install the packages
sudo apt-get -y update
sudo apt-get install -y openmpi-bin libmpich-dev libopenmpi-dev gcc g++ gfortran subversion libcurl4-openssl-dev wget make m4 git liburi-perl libxml2-dev
```

### Step 3: Install Zlib
According to [zlib](https://www.zlib.net)'s documentation, **zlib** is designed to be a free, general-purpose, legally unencumbered -- that is, not covered by any patents -- lossless data-compression library for use on virtually any computer hardware and operating system. The zlib data format is itself portable across platforms. It is a prerequisite for NetCDF (if I understood correctly). Check the website for the latest version and manually set this variable. Then, the installation procedure is the following.
```shell
cd $WORKDIR
LIB_VERSION="zlib-1.3.1"
wget https://www.zlib.net/${LIB_VERSION}.tar.gz
tar xvfz ${LIB_VERSION}.tar.gz
cd $LIB_VERSION
./configure --prefix=$INSTDIR
make -j1
##make check
make install
echo " " 
```
> [!NOTE]
> We have just started populating the `$ROOT/nemo-deps/installs` directory. This will be indicated by the variable `$INSTDIR`. You can check with `echo $INSTDIR` that this is the correct folder if you do this in different moments and not right after step 1.

### Step 4: Install HDF5
Hierarchical Data Format (HDF) is a set of file formats (HDF4, HDF5) designed to store and organize large amounts of data. It is supported by The [HDF Group](https://www.hdfgroup.org), a non-profit corporation whose mission is to ensure continued development of HDF5 technologies and the continued accessibility of data stored in HDF.

You should check at the [download](https://support.hdfgroup.org/downloads/hdf5/hdf5_1_14_6.html) page which is the version you want to install, but download it from their [GitHb Releases](https://github.com/HDFGroup/hdf5/releases) page.

Once the version has been chosen, manually change the version (and check the link) and run the following:
```shell
cd $WORKDIR
LIB_VERSION="hdf5_1.14.6"
wget https://github.com/HDFGroup/hdf5/archive/refs/tags/${LIB_VERSION}.tar.gz
tar xvfz ${LIB_VERSION}.tar.gz
cd hdf5-$LIB_VERSION
export HDF5_Make_Ignore=yes
# Configure
./configure --prefix=$INSTDIR --enable-fortran  --enable-parallel --enable-hl --enable-shared --with-zlib=$INSTDIR
# Make and install
make -j1
##make check
make install
echo " " 
```

### Step 5: Install NetCDF-C and NetCDF-F
As for the HDF5, you can control the version of NetCDF on the github page, update the variable `LIB_VERSION` and run the following.
> [!IMPORTANT]
> Order matters: NetCDF-C before, NetCDF-Fortran later. 

```shell
# install netcdf-c
cd $WORKDIR
LIB_VERSION="4.9.3"
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v${LIB_VERSION}.tar.gz
tar xvfz v${LIB_VERSION}.tar.gz
cd netcdf-c-${LIB_VERSION}
export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"
export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lhdf5_hl -lhdf5"
export LIBS="-lmpi"
./configure --prefix=$INSTDIR --enable-netcdf-4 --enable-shared --enable-parallel-tests
make -j1
##make check
make install
echo " " 

# Install netcdf-fortran
cd $WORKDIR
LIB_VERSION="4.6.2"
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${LIB_VERSION}.tar.gz
tar xvfz v${LIB_VERSION}.tar.gz
cd netcdf-fortran-${LIB_VERSION}
export LD_LIBRARY_PATH=${NCDIR}/lib:${LD_LIBRARY_PATH}
export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"
export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lnetcdf -lhdf5_hl -lhdf5 -lz -lcurl"
export LIBS="-lmpi"
./configure --prefix=$INSTDIR --enable-shared --enable-parallel-tests --enable-parallel
make -j1
##make check
make install
echo " " 
```

## Install XIOS