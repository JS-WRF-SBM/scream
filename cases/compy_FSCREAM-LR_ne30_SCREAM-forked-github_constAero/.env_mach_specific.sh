# This file is for user convenience only and is not used by the model
# Changes to this file will be ignored and overwritten
# Changes to the environment should be made in env_mach_specific.xml
# Run ./case.setup --reset to regenerate this file
source /etc/profile.d/modules.sh
module purge 
module load cmake/3.11.4 intel/19.0.5 intelmpi/2019u4 netcdf/4.6.3 pnetcdf/1.9.0 mkl/2019u5
export NETCDF_HOME=/share/apps/netcdf/4.6.3/intel/19.0.5/
export MKL_PATH=/share/apps/intel/2019u5/compilers_and_libraries_2019.5.281/linux/mkl
export I_MPI_ADJUST_ALLREDUCE=1