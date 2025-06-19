#!/bin/bash
#set -u
#set -vx
#
# name of the comilation environment
#
compile_env=default
#compile_env=macport_default
#compile_env=macport_gcc14
#compile_env=macport_clang19
#compile_env=macport_fullclang19
#
# number of procs used to compile
#
nproc=8
#
# Root directories where NEMO and its dependecies will be installed
#
ROOTDIR=$HOME/ALL_NEMO_$compile_env
#
# nemo installation directory and version
#
nemodir=$ROOTDIR/nemo_5.0.1
nemogit=forge.nemo-ocean.eu:nemo/nemo.git
nemobranch=branch_5.0
#
# xios installation directory and version
#
xiosver=2
xiosdir=$ROOTDIR/xios${xiosver}-trunk
#
# util installation directory (hdf, netcdf-c, netcdf-fortran, perl uri)
#
if [ "$compile_env" = "macport_fullclang19" ]
then
    UTILDIR=/opt/local  # use macport libs instead of installing them
else
    UTILDIR=$ROOTDIR/util_nemo
fi
#
# compiler definition and options
#
case "$compile_env" in
    macport_gcc14)
	# macport packages needed for macport_gcc14:
	#    sudo port install gsed
	#    sudo port install gcc14
	#    sudo port install mpich-gcc14
	export CC=mpicc-mpich-gcc14 
	export CXX=mpicxx-mpich-gcc14
	export FC=mpif90-mpich-gcc14
	export CXXCPP=cpp-mp-14
	export LINKER=$FC
	export xiosBASE_CFLAGS="-w -std=gnu++11 -D__XIOS_EXCEPTION"
	export xiosBASE_FFLAGS="-D__NONE__ -ffree-line-length-none"
	export xiosBASE_LD="-l stdc++"
	export nemoBASE_LD=""
	;;
    macport_clang19|macport_fullclang19)
	# macport packages needed for macport_clang19 or macport_fullclang19:
	#    sudo port install gsed
	#    sudo port install llvm-19 +debug
	#    sudo port install clang-19 +debug +libstdcxx
	#    sudo port install mpich-clang19 +gcc14
	# in addition for macport_fullclang19
	#    sudo port install hdf5 +clang19 +mpich
	#    sudo port install netcdf +clang19 +mpich	
	#    sudo port install netcdf-fortran +gcc14 +mpich	
	#    sudo port install p5.34-uri
	export CC=mpicc-mpich-clang19
	export CXX=mpicxx-mpich-clang19
	export FC=mpif90-mpich-clang19
	export CXXCPP=cpp-mp-14
	export LINKER=$CC
	export xiosBASE_CFLAGS="-w -std=gnu++11 -D__XIOS_EXCEPTION"
	export xiosBASE_FFLAGS="-D__NONE__ -ffree-line-length-none"
	export xiosBASE_LD="-l stdc++ -L /opt/local/lib/mpich-clang19 -l mpicxx -L /opt/local/lib/mpich-gcc14 -l mpifort -L /opt/local/lib/gcc14 -l gfortran"
	export nemoBASE_LD="-L /opt/local/lib/mpich-gcc14 -l mpifort -L /opt/local/lib/gcc14 -l gfortran -L /opt/local/lib/gcc14/gcc/aarch64-apple-darwin23/14.2.0 -l gcc"
	;;
    *)
	# macport packages needed for macport_default:
	#    sudo port install gsed
	#    sudo port install gcc14
	#    sudo port install mpich-gcc14
	#    sudo port select --set gcc mp-gcc14              # set gcc14 by default
	#    sudo port select --set mpi mpich-gcc14-fortran   # set mpich-gcc14 by default
	export CC=mpicc
	export CXX=mpicxx
	export FC=mpif90
	export CXXCPP=cpp
	export LINKER=$FC
	export xiosBASE_CFLAGS="-w -std=gnu++11 -D__XIOS_EXCEPTION"
	export xiosBASE_FFLAGS="-D__NONE__ -ffree-line-length-none"
	export xiosBASE_LD="-l stdc++"
	export nemoBASE_LD=""
	;;
esac
#
hdf_version=1.14.6
ncc_version=4.9.3
ncf_version=4.6.1
perl_version=5.40.1
#
[ ! -d $ROOTDIR ] && mkdir -p $ROOTDIR
cd $ROOTDIR
#
# printing functions
#
#
printheader(){
echo
echo "#----------------------------------------------"
echo "#----------------------------------------------"
echo "# $1"
echo "#----------------------------------------------"
echo "#----------------------------------------------"
echo
}
#
printerror(){
    echo
    echo $1
    echo "=== WE STOP ==="
    echo
    exit $2
}
#
printok(){
    echo
    echo "#----------------------------------------------"
    echo "# $1 OK"
    echo "#----------------------------------------------"
    echo
}
#
#----------------------------------------------
#----------------------------------------------
# tests
#----------------------------------------------
#----------------------------------------------
#
for ee in wget $CC $CXX $FC $CXXCPP
do
    founderr=$( which $ee >/dev/null 2>&1 ; echo $? )
    [ $founderr -ne 0 ]  && printerror "$ee not found but is required" 1
    founderr=$( $ee --version >/dev/null 2>&1 ; echo $? )
    [ $founderr -ne 0 ] && printerror "$ee working properly" 1
done
# gnu sed
isok=$( sed --version 2>/dev/null | grep -ic gnu )
[ $isok -eq 0 ] && printerror "sed is not the GNU sed, please install gsed" 1
#
#----------------------------------------------
#----------------------------------------------
# install
#----------------------------------------------
#----------------------------------------------
#
#
[ ! -d $UTILDIR ] && mkdir -p $UTILDIR
[ ! -d $UTILDIR/src ] && mkdir -p $UTILDIR/src
#
export PATH=$UTILDIR/bin:$PATH
export LD_LIBRARY_PATH=$UTILDIR/lib:$LD_LIBRARY_PATH
#
export CFLAGS='-O3'
export PPFLAGS='-O3'
export XXFLAGS='-O3'
#
#----------------------------------------------
#
printheader "HDF5"

founderr=$( $UTILDIR/bin/h5pcc --version >/dev/null 2>&1 ; echo $? )
if [ $founderr -ne 0 ]
then
    cd $UTILDIR/src
    rm -rf hdf5-${hdf_version} hdf5-${hdf_version}.tar.gz
    if [[ "$hdf_version" < "1.14.6" ]]
    then
	wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${hdf_version%.*}/hdf5-${hdf_version}/src/hdf5-${hdf_version}.tar.gz
    else
	wget https://support.hdfgroup.org/releases/hdf5/v$( echo ${hdf_version%.*} | sed -e "s/\./_/")/v${hdf_version//\./_}/downloads/hdf5-${hdf_version}.tar.gz
    fi
    [ $? -ne 0 ] && printerror "error with the wget of hdf5-${hdf_version} source files" 1
    tar xvfz hdf5-${hdf_version}.tar.gz
    cd hdf5-${hdf_version}
    #
    export H5_CFLAGS='-std=c99 -O3'
    
    ./configure --enable-build-mode=production --enable-parallel --prefix=$UTILDIR  2>&1 | tee log.compile.hdf5  # /hdf5-${hdf_version}
    [ $? -ne 0 ] && printerror "error with the configure of hdf5-${hdf_version} source files" 1
    #
    make -j $nproc         2>&1 | tee -a log.compile.hdf5 
    [ $? -ne 0 ] && printerror "error with the make of hdf5-${hdf_version} source files" 1
    #make check # very very long...
    make -j $nproc install 2>&1 | tee -a log.compile.hdf5 
    [ $? -ne 0 ] && printerror "error with the make install of hdf5-${hdf_version} source files" 1
    cd ..
fi

founderr=$( $UTILDIR/bin/h5pcc --version >/dev/null 2>&1 ; echo $? )
[ $founderr -ne 0 ] && printerror "ERROR with HDF5 compilation, see $UTILDIR/src/hdf5-${hdf_version}/log.compile.hdf5" 1
rm -rf hdf5-${hdf_version}
printok "HDF5"
#
#----------------------------------------------
#
printheader "NETCDF-C"

founderr=$( $UTILDIR/bin/nc-config --version >/dev/null 2>&1 ; echo $? )
if [ $founderr -ne 0 ]
then
    cd $UTILDIR/src
    rm -rf netcdf-c-${ncc_version} v${ncc_version}.tar.gz
    wget https://github.com/Unidata/netcdf-c/archive/v${ncc_version}.tar.gz
    [ $? -ne 0 ] && printerror "error with the wget of netcdf-c-${ncc_version} source files" 1
    tar xvfz v${ncc_version}.tar.gz
    cd netcdf-c-${ncc_version}
    #
    export CPPFLAGS="-I$UTILDIR/include"
    export LIBS="-L$UTILDIR/lib -lhdf5_hl -lhdf5 -lz -lmpi" 
    ./configure --prefix=$UTILDIR 2>&1 | tee log.compile.netcdf-c   # /netcdf-c-${ncc_version} 
    [ $? -ne 0 ] && printerror "error with the configure of netcdf-c-${ncc_version} source files" 1
    #
    make -j $nproc         2>&1 | tee -a log.compile.netcdf-c
    [ $? -ne 0 ] && printerror "error with the make of netcdf-c-${ncc_version} source files" 1
    #make -j $nproc check
    make -j $nproc install 2>&1 | tee -a log.compile.netcdf-c
    [ $? -ne 0 ] && printerror "error with the make install of netcdf-c-${ncc_version} source files" 1
    cd ..
fi
founderr=$( $UTILDIR/bin/nc-config --version >/dev/null 2>&1 ; echo $? )
[ $founderr -ne 0 ] && printerror "ERROR with NETCDF-C compilation, see $UTILDIR/src/netcdf-c-${ncc_version}/log.compile.netcdf-c" 1
rm -rf netcdf-c-${ncc_version}
printok "NETCDF-C"
#
#----------------------------------------------
#
printheader "NETCDF-Fortran"
#
founderr=$( $UTILDIR/bin/nf-config --version >/dev/null 2>&1 ; echo $? )
if [ $founderr -ne 0 ]
then
    cd $UTILDIR/src
    rm -rf netcdf-fortran-${ncf_version} v${ncf_version}.tar.gz
    wget https://github.com/Unidata/netcdf-fortran/archive/v${ncf_version}.tar.gz
    [ $? -ne 0 ] && printerror "error with the wget of netcdf-fortran-${ncf_version} source files" 1
    tar xvfz v${ncf_version}.tar.gz
    cd netcdf-fortran-${ncf_version}
    #
    export CPPFLAGS="-I$UTILDIR/include"
    export LIBS="-L$UTILDIR/lib -lnetcdf -lhdf5_hl -lhdf5 -lcurl -lz -lmpi"
    ./configure --prefix=$UTILDIR 2>&1 | tee log.compile.netcdf-fortran   # /netcdf-fortran-${ncf_version} # --enable-parallel-tests
    [ $? -ne 0 ] && printerror "error with the configure of netcdf-fortran-${ncf_version} source files" 1
    #
    make -j $nproc          2>&1 | tee -a log.compile.netcdf-fortran
    [ $? -ne 0 ] && printerror "error with the make of netcdf-fortran-${ncf_version} source files" 1
    #make check
    make  -j $nproc install 2>&1 | tee -a log.compile.netcdf-fortran
    [ $? -ne 0 ] && printerror "error with the make install of netcdf-fortran-${ncf_version} source files" 1
    cd ..
fi
founderr=$( $UTILDIR/bin/nf-config --version 2>& 1 > /dev/null ; echo $? )
[ $founderr -ne 0 ] && printerror "ERROR with NETCDF-Fortran compilation, see $UTILDIR/src/netcdf-fortran-${ncf_version}/log.compile.netcdf-fortran" 1
rm -rf netcdf-fortran-${ncf_version}
printok "NETCDF-Fortran"
#
#----------------------------------------------
#
printheader "Perl"

founderr=$( which perl  >/dev/null 2>&1 ; echo $? )
if [ $founderr -eq 0 ]
then
    founderr=$( perl -e "use URI" >/dev/null 2>&1 ; echo $? )    
fi
if [ $founderr -ne 0 ]
then
    cd $UTILDIR/src
    rm -rf perl-${perl_version} perl-${perl_version}.tar.gz
    wget https://www.cpan.org/src/5.0/perl-${perl_version}.tar.gz
    [ $? -ne 0 ] && printerror "error with the wget of perl-${perl_version} source files" 1
    tar -xzf perl-${perl_version}.tar.gz
    cd perl-${perl_version}
    ./Configure -des -Dprefix=$UTILDIR
    [ $? -ne 0 ] && printerror "error with the Configure of perl-${perl_version} source files" 1
    make -j $nproc
    [ $? -ne 0 ] && printerror "error with the make of perl-${perl_version} source files" 1
    #make test
    make  -j $nproc install
    [ $? -ne 0 ] && printerror "error with the make install of perl-${perl_version} source files" 1
    cd ..

    ../bin/cpan App::cpanminus
    [ $? -ne 0 ] && printerror "error with cpan App::cpanminus" 1
    ../bin/cpanm URI
    [ $? -ne 0 ] && printerror "error with cpanm URI" 1

fi
founderr=$( perl -e "use URI" >/dev/null 2>&1 ; echo $? )    
[ $founderr -ne 0 ] && printerror "ERROR with Perl, URI not found, we stop" 1
rm -rf perl-${perl_version}
printok "Perl"
#
#----------------------------------------------
#
printheader "XIOS"

if [[ ( ! -f $xiosdir/bin/xios_server.exe ) || ( ! -f $xiosdir/lib/libxios.a ) ]]
then
    cd $UTILDIR
    rm -rf $xiosdir
    svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS${xiosver}/trunk $xiosdir
    [ $? -ne 0 ] && printerror "error with the svn co of XIOS${xiosver} source files" 1
    cd $xiosdir

    #  arch files: use arch/arch-GCC_LINUX as default base
    sed -e "s@export HDF5_INC_DIR=.*@export HDF5_INC_DIR=$UTILDIR/include@" \
	-e "s@export HDF5_LIB_DIR=.*@export HDF5_LIB_DIR=$UTILDIR/lib@" \
	-e "s@export NETCDF_INC_DIR=.*@export NETCDF_INC_DIR=$UTILDIR/include@" \
	-e "s@export NETCDF_LIB_DIR=.*@export NETCDF_LIB_DIR=$UTILDIR/lib@" \
	arch/arch-GCC_LINUX.env > archtmp
    [ $? -ne 0 ] && printerror "error with the sed command on arch/arch-GCC_LINUX.env" 1
    mv archtmp arch/arch-GCC_LINUX.env

    sed -e "s@\(.*BASE_CFLAGS *\).*@\1$xiosBASE_CFLAGS@" \
	-e "s@\(.*BASE_FFLAGS *\).*@\1$xiosBASE_FFLAGS@" \
	-e "s@\(.*BASE_LD *\).*@\1$xiosBASE_LD@" \
	-e "s@\(^%CCOMPILER *\).*@\1$CC@" \
	-e "s@\(^%FCOMPILER *\).*@\1$FC@" \
	-e "s@\(^%CPP *\).*@\1$CXXCPP@" \
	-e "s@\(^%FPP *\).*@\1$CXXCPP -P@" \
	-e "s@\(^%LINKER *\).*@\1$LINKER@" \
	-e "s@\(^%MAKE *\).*@\1make@" \
	arch/arch-GCC_LINUX.fcm > archtmp
    [ $? -ne 0 ] && printerror "error with the sed command on arch/arch-GCC_LINUX.fcm" 1
    mv archtmp arch/arch-GCC_LINUX.fcm

    ./make_xios --prod --arch GCC_LINUX --full --job $nproc 2>&1 | tee log.compile.xios
    [ $? -ne 0 ] && printerror "error with make_xios" 1
fi
[ ! -f $xiosdir/bin/xios_server.exe ] && printerror "ERROR with XIOS compilation" 1
printok "XIOS"
#
#----------------------------------------------
#
printheader "NEMO"
#
if [ ! -f $nemodir/arch/arch-auto.fcm ]
then
    cd $ROOTDIR
    rm -rf $nemodir
    
    # do we have ssh or https access ?
    tst=$( git ls-remote -h git@$nemogit >/dev/null 2>&1 ; echo $? ) 
    if [ $tst -eq 0 ]
    then
	git clone git@$nemogit $nemodir
    else
	git clone https://${nemogit/://} $nemodir
    fi
    [ $? -ne 0 ] && printerror "error with the git clone of NEMO source files" 1    
    cd $nemodir
    git switch $nemobranch
    
    cd $nemodir/arch
    ./build_arch-auto.sh --NETCDF_C_prefix $UTILDIR --NETCDF_F_prefix $UTILDIR --HDF5_prefix $UTILDIR --XIOS_prefix $xiosdir --FCnemo $FC --CPPnemo $CXXCPP
    [ $? -ne 0 ] && printerror "error with build_arch-auto.sh" 1    

    cd $nemodir
    [ $xiosver -eq 3 ] && nemoADD_KEY="-Dkey_xios3" || nemoADD_KEY=""
    # hand made update of arch-auto.fcm --> should be added as future features of build_arch-auto.sh
    sed -e "s/\(%CPP.*\)/\1 $nemoADD_KEY/" \
	-e "s/ %OASIS_INC//" \
	-e "s/ %OASIS_LIB//" \
	-e "s@\(%LD  *\).*@\1 $LINKER@" \
	-e "s@\(%LDFLAGS  *.*\)@\1 $nemoBASE_LD@" \
	arch/arch-auto.fcm > archtmp
    [ $? -ne 0 ] && printerror "error with the sed command on arch/arch-auto.env" 1
    mv archtmp arch/arch-auto.fcm

    # set defaults of  -m and -j options in makenemo
    sed -e "s/x_m=''/x_m='auto'/" \
	-e "s/x_j='1'/x_j='$nproc'/" \
	makenemo > maketmp
    [ $? -ne 0 ] && printerror "error with the sed command on makenemo" 1
    mv maketmp makenemo
    chmod 755 makenemo
fi
printok "NEMO"
#

exit 0
