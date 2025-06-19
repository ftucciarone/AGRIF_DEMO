#!/bin/bash 
#########################################################################
# Defaults
#########################################################################
install_dir=$(pwd)
c_compiler=gcc
f_compiler=gfortran
cxx_compiler=g++
mpi_home="/usr/lib64/openmpi"
#########################################################################
#  Options 
#########################################################################
while (($# > 0))
   do
   case $1 in
     "-h") cat <<........fin
    $0 [ -prefix path ]       where (path) to install
                              (default: $install_dir)
       [ -
CC compiler ]       C compiler to use
                              (default: $c_compiler)
       [ -FC compiler ]       Fortran compiler to use
                              (default: $f_compiler)
       [ -CXX compiler ]      C++ compiler to use
                              (default: $cxx_compiler)
       [ -MPI path ]          top directory of the MPI library
                              (default: $mpi_home)
........fin
     exit ;;
     "-prefix") install_dir=$2 ; shift ; shift ;;
     "-CC") c_compiler=$2 ; shift ; shift ;;
     "-FC") f_compiler=$2 ; shift ; shift ;;
     "-CXX") cxx_compiler=$2 ; shift ; shift ;;
     "-MPI") mpi_home=$2 ; shift ; shift ;;
     *) echo "Error, bad argument $1" ; $0 -h ; exit
   esac
done

# Install directory (get full path)
mkdir -p $install_dir
install_dir=$(cd $install_dir ; pwd -P )

# Install location for packages
mkdir -p $install_dir/src

allow_arg_mismatch=""
if [[ ${f_compiler} == "gfortran" ]] ; then
  if [ `gfortran -dumpversion | cut -d. -f1` -ge 10 ] ; then 
    allow_arg_mismatch="-fallow-argument-mismatch" 
  fi
  export FFLAGS=" -O2 -fPIC $allow_arg_mismatch"
  export FCFLAGS="-O2 -ffree-form -fPIC $allow_arg_mismatch"
  export CPPFLAGS="-I${install_dir}/include"
  export CFLAGS="-O2 -fPIC"
  export CXXFLAGS="-O2 -fPIC"
elif [[ ${f_compiler} == "ifort" ]] ; then
  export CPP="icc -E"
  export FFLAGS="-O2 -ip -fpic"
  export FCFLAGS="-O2 -ip -fpic"
  export CPPFLAGS="-I${install_dir}/include"
  export CFLAGS="-O2 -ip -fpic"
  export CXXFLAGS="-O2 -ip -fpic"
else
  echo "unknown compiler $f_compiler"
  echo "might as well stop here"
  exit
fi

# CURL
APP=curl-7.26.0
CURL_PATH=$install_dir/$APP
rm -rf $CURL_PATH 
cd $install_dir/src 
rm -rf curl-7.26.0* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/curl-7.26.0.tar.gz
tar xvf curl-7.26.0.tar.gz ; cd curl-7.26.0
export CC=$c_compiler
./configure \
--prefix=$install_dir | tee $APP.config.log
make 2>&1 | tee $APP.make.log
make install 2>&1 | tee $APP.install.log

# ZLIB
APP=zlib-1.2.8
ZLIB_PATH=$install_dir/$APP 
rm -rf $ZLIB_PATH 
cd $install_dir/src 
rm -rf zlib-1.2.8* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/zlib-1.2.8.tar.gz
tar zxf zlib-1.2.8.tar.gz ; cd zlib-1.2.8
export CC=$c_compiler
export FC=$f_compiler
export CXX=$cxx_compiler 
./configure \
--prefix=$install_dir | tee $APP.config.log
make 2>&1 | tee $APP.make.log
make check 2>&1 | tee $APP.make_check.log
make install 2>&1 | tee $APP.install.log

# HDF5
APP=hdf5-1.10.7
HDF5_PATH=$install_dir/$APP 
rm -rf $HDF5_PATH 
cd $install_dir/src 
rm -rf ${APP}* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/$APP.tar.gz
tar xzf $APP.tar.gz ; cd $APP
export PATH=$mpi_home/bin:$PATH
if [[ ${LD_LIBRARY_PATH} == '' ]]
then
  export LD_LIBRARY_PATH=$mpi_home/lib
else
  export LD_LIBRARY_PATH=$mpi_home/lib:${LD_LIBRARY_PATH}
fi
export CFLAGS="-I$mpi_home/include -m64"
export LDFLAGS="-L$mpi_home/lib -lmpi"
export MPI_BIN=$mpi_home/bin
export MPI_SYSCONFIG=$mpi_home/etc
export MPI_FORTRAN_MOD_DIR=$mpi_home/lib
export MPI_INCLUDE=$mpi_home/include
export MPI_LIB=$mpi_home/lib
export MPI_HOME=$mpi_home
export CC=mpicc
export FC=mpif90
export CXX=mpiCC 
./configure \
--prefix=$install_dir \
--enable-fortran \
--enable-parallel \
--with-zlib=$install_dir  \
--with-pic 2>&1 | tee $APP.config.log
make 2>&1 | tee $APP.make.log
#make check 2>&1 | tee $APP.make_check.log
make install 2>&1 | tee $APP.install.log

# NetCDF4
APP=netcdf-4.3.3.1
NETCDF4_PATH=$install_dir/$APP
rm -rf $NETCDF4_PATH 
cd $install_dir/src 
rm -rf netcdf-4.3.3.1* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/netcdf-4.3.3.1.tar.gz
tar xzf netcdf-4.3.3.1.tar.gz ; cd netcdf-4.3.3.1 
export LDFLAGS="-L${install_dir}/lib -L${mpi_home}/lib -lmpi"
export CFLAGS="-I${install_dir}/include/curl -I${install_dir}/include"
export LD_LIBRARY_PATH="${install_dir}/lib:${LD_LIBRARY_PATH}"
CC=mpicc ./configure \
--prefix=${install_dir} \
--enable-static \
--enable-shared \
--enable-netcdf4 \
--enable-dap \
--with-pic 2>&1 | tee $APP.config.log
make 2>&1 | tee $APP.make.log
make check 2>&1 | tee $APP.make_check.log
make install 2>&1 | tee $APP.install.log

# NetCDF4-Fortran
APP=netcdf-fortran-4.4.2
NETCDF4_FORTRAN_PATH=${install_dir}/$APP
rm -rf $NETCDF4_FORTRAN_PATH
cd ${install_dir}/src 
rm -rf netcdf-fortran-4.4.2* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/netcdf-fortran-4.4.2.tar.gz
tar xzf netcdf-fortran-4.4.2.tar.gz ; cd netcdf-fortran-4.4.2
#export LD_LIBRARY_PATH=${install_dir}/lib:${LD_LIBRARY_PATH}
export LDFLAGS="-L${install_dir}/lib -L${install_dir}/lib -L${mpi_home}/lib -lmpi"
export CPPFLAGS="-I${install_dir}/include/curl -I${install_dir}/include"
export CC=mpicc
export FC=mpif90
export F77=mpif77 
export LDFLAGS=-L${install_dir}/lib 
./configure \
--prefix=${install_dir} 2>&1 | tee $APP.config.log
make 2>&1 | tee $APP.make.log
make check 2>&1 | tee $APP.make_check.log
make install 2>&1 | tee $APP.install.log

# NetCDF4-C++
APP=netcdf-cxx4-4.2.1
NETCDF4_CXX_PATH=${install_dir}/$APP
rm -rf $NETCDF4_CXX_PATH
cd ${install_dir}/src 
rm -rf netcdf-cxx4-4.2.1* 
wget -nv --no-check-certificate http://lmdz.lmd.jussieu.fr/pub/src_archives/netcdf/netcdf-cxx4-4.2.1.tar.gz
tar xzf netcdf-cxx4-4.2.1.tar.gz ; cd netcdf-cxx4-4.2.1
#export LD_LIBRARY_PATH=${install_dir}/lib:${LD_LIBRARY_PATH}
export LDFLAGS="-L${install_dir}/lib -L${mpi_home}/lib -lmpi"
export CPPFLAGS="-I${install_dir}/include/curl -I${install_dir}/include"
export CC=mpicc
export CXX=mpiCC
export LDFLAGS=-L${install_dir}/lib
./configure \
--prefix=${install_dir} 2>&1 | tee $APP.config.log
make 2>&1 | tee $APP.make.log
make check 2>&1 | tee $APP.make_check.log
make install 2>&1 | tee $APP.install.log
