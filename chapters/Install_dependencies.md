# Install dependencies (or link the dockerfile)

> [!IMPORTANT]
> These instruction are not going to be bulletproof. We built them upon the work of previous wise men. Among them, in alphabetical order, honorable mentions should be addressed to 
> * [Romain Caneill](), (role unknown) wrote a great apptainer with all the dependencies;
> * [Julian Mak](), NEMO System Team member, wrote incredible notes and [made them available]();
> * [Sebastian Masson](), NEMO System Team member;
> * [Yann Meurdesoif](), main developer and maintainer of XIOS.

> [!WARNING]
> *Lasciate ogne speranza, voi ch'intrate*

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
> We will install also libcurl4-openssl-dev, m4, liburi-perl, libxml2-dev, but frankly I don't know what they are or why we are doing this.

 
