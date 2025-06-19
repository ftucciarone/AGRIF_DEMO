# Alternative route: set up a Docker container



```Docker
FROM ubuntu:latest AS base
LABEL maintainer="spam.ftcc@gmail.com" 

# Give nemo version of choice and associated xios version (4.2.2 works only with xios-trunk)
ARG nemo_VERSION="3.6 4.0 4.2.2 5.0"

ARG WORKDIR="/home/nemo-bins"
ARG INSTDIR="/home/nemo-libs"

# compilers
ARG CC=/usr/bin/mpicc
ARG CXX=/usr/bin/mpicxx
ARG FC=/usr/bin/mpif90
ARG F77=/usr/bin/mpif77

# compiler flags (except for libraries)
ARG CFLAGS="-O3 -fPIC"
ARG CXXFLAGS="-O3 -fPIC"
ARG F90FLAGS="-O3 -fPIC"
ARG FCFLAGS="-O3 -fPIC"
ARG FFLAGS="-O3 -fPIC"
ARG LDFLAGS="-O3 -fPIC "
# FLAGS FOR F90  TEST-EXAMPLES
ARG FCFLAGS_f90="-O3 -fPIC "

# Version 
ARG zlib_VERSION="1.3.1"
ARG hdf5_VERSION="1.10.5"
ARG netCDF_c_VERSION="4.9.2"
ARG netCDF_f_VERSION="4.6.2"


# Build the image as root 
USER root
# create directory where to move necessary files
RUN mkdir -p $WORKDIR
RUN mkdir -p $INSTDIR
RUN mkdir -p /home/files
RUN mkdir -p /home/nemo-src
# Install dependencies
RUN apt -y update
RUN apt -y install vim \
openmpi-bin \
libmpich-dev \
libopenmpi-dev \
gcc \
g++ \
gfortran \
subversion \
libcurl4-openssl-dev \
wget \
make \
m4 \
git \
liburi-perl \
libxml2-dev

# Create user
RUN useradd -ms /bin/bash nemoruns

# Install zlib. Check latest version at https://www.zlib.net and add it to the setvars.sh file
ARG WORKDIR
ARG INSTDIR
ARG zlib_VERSION
RUN echo $zlib_VERSION
RUN wget --directory-prefix=$WORKDIR https://www.zlib.net/zlib-$zlib_VERSION.tar.gz
RUN tar xvfz $WORKDIR/zlib-$zlib_VERSION.tar.gz --directory=$WORKDIR
RUN cd $WORKDIR/zlib-$zlib_VERSION; ./configure --prefix=$INSTDIR
RUN cd $WORKDIR/zlib-$zlib_VERSION; make -j1
RUN cd $WORKDIR/zlib-$zlib_VERSION; make install

# Install hdf5
ARG WORKDIR
ARG INSTDIR
ARG hdf5_VERSION
RUN wget --directory-prefix=$WORKDIR https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-$hdf5_VERSION/src/hdf5-$hdf5_VERSION.tar.gz \
	-O $WORKDIR/hdf5-$hdf5_VERSION.tar.gz
RUN tar xvfz $WORKDIR/hdf5-$hdf5_VERSION.tar.gz --directory=$WORKDIR
RUN cd $WORKDIR/hdf5-$hdf5_VERSION; export HDF5_Make_Ignore=yes; \
	./configure --prefix=$INSTDIR \
	--enable-fortran --enable-parallel --enable-hl --enable-shared  \
	--with-zlib=$INSTDIR
RUN cd $WORKDIR/hdf5-$hdf5_VERSION; make -j1
RUN cd $WORKDIR/hdf5-$hdf5_VERSION; make install

# Install netcdf-c
ARG WORKDIR
ARG INSTDIR
ARG netCDF_c_VERSION
RUN wget --directory-prefix=$WORKDIR https://github.com/Unidata/netcdf-c/archive/refs/tags/v${netCDF_c_VERSION}.tar.gz
RUN tar xvfz $WORKDIR/v${netCDF_c_VERSION}.tar.gz --directory=$WORKDIR
RUN export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"; \
	export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lhdf5_hl -lhdf5"; \
	export LIBS="-lmpi"; \
	cd $WORKDIR/netcdf-c-${netCDF_c_VERSION}; \
	./configure --prefix=$INSTDIR --enable-netcdf-4 --enable-shared --enable-parallel-tests
RUN cd $WORKDIR/netcdf-c-${netCDF_c_VERSION}; make -j1
RUN cd $WORKDIR/netcdf-c-${netCDF_c_VERSION}; make install

# Install netcdf-fortran
ARG WORKDIR
ARG INSTDIR
#ARG netCDF_f_VERSION
RUN wget --directory-prefix=$WORKDIR https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${netCDF_f_VERSION}.tar.gz
RUN tar xvfz $WORKDIR/v${netCDF_f_VERSION}.tar.gz --directory=$WORKDIR
RUN export LD_LIBRARY_PATH=${NCDIR}/lib:${LD_LIBRARY_PATH}; \
	export CPPFLAGS="-I$INSTDIR/include -DpgiFortran"; \
	export LDFLAGS="-Wl,-rpath,$INSTDIR/lib -L$INSTDIR/lib -lnetcdf -lhdf5_hl -lhdf5 -lz -lcurl"; \
	export LIBS="-lmpi"; \
	cd $WORKDIR/netcdf-fortran-${netCDF_f_VERSION}; \
	./configure --prefix=$INSTDIR \
		--enable-shared --enable-parallel-tests \
                --enable-parallel
RUN cd $WORKDIR/netcdf-fortran-${netCDF_f_VERSION}; make -j1
RUN cd $WORKDIR/netcdf-fortran-${netCDF_f_VERSION}; make install

# Clean 
RUN rm $WORKDIR/zlib-$zlib_VERSION.tar.gz 
RUN rm $WORKDIR/hdf5-$hdf5_VERSION.tar.gz 
RUN rm $WORKDIR/v${netCDF_c_VERSION}.tar.gz 
RUN rm $WORKDIR/v${netCDF_f_VERSION}.tar.gz 

# Download xios
ARG WORKDIR
ARG INSTDIR
RUN git clone -b xios-2.5 https://github.com/ftucciarone/XIOS.git $WORKDIR/xios-2.5
RUN git clone -b XIOS-trunk https://github.com/ftucciarone/XIOS.git $WORKDIR/xios-trunk

# Before installing xios import config files
RUN mkdir -p /home/files/xios-arch
COPY arch-xios/arch-xios_container.* /home/files/xios-arch
RUN sed -i "s|\$INSTDIR|$INSTDIR|" /home/files/xios-arch/arch-xios_container.env
RUN cat /home/files/xios-arch/arch-xios_container.env
RUN cp /home/files/xios-arch/arch-xios_container.* $WORKDIR/xios-2.5/arch/
RUN cp /home/files/xios-arch/arch-xios_container.* $WORKDIR/xios-trunk/arch/
RUN cp /home/files/xios-arch/arch-xios_container_2.5* $WORKDIR/xios-2.5/arch/
RUN cp /home/files/xios-arch/arch-xios_container_trunk.* $WORKDIR/xios-trunk/arch/

RUN cd $WORKDIR/xios-2.5/; ./make_xios --arch xios_container --job 1
#RUN cd $WORKDIR/xios-trunk/; ./make_xios --arch xios_container --job 1

# Install nemo
RUN mkdir -p /home/files/nemo-arch
COPY arch-nemo/arch-container* /home/files/nemo-arch
RUN sed -i "s|\$INSTDIR|$INSTDIR|" /home/files/nemo-arch/arch-container*

RUN for nemo_version in $nemo_VERSION; do \
    cat /home/files/nemo-arch/arch-container$nemo_version.fcm; \
    git clone -b nemo-$nemo_version https://github.com/ftucciarone/NEMO.git /home/nemo-$nemo_version; \
    /home/files/nemo-arch/arch-container$nemo_version.fcm $WORKDIR/nemo-$nemo_version/arch/; \
    echo "$nemo_version"; \
    done;
```
