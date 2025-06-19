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
mkdir -p $NEMODIR

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




