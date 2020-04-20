#!/bin/bash -e

# Batch system directives
#SBATCH  --job-name=run.compy_FSCREAM-LR_ne30_SCREAM-forked-github_constAero
#SBATCH  --nodes=20
#SBATCH  --output=run.compy_FSCREAM-LR_ne30_SCREAM-forked-github_constAero.%j 
#SBATCH  --exclusive 

# template to create a case run shell script. This should only ever be called
# by case.submit when on batch. Use case.submit from the command line to run your case.

# cd to case
cd /compyfs/shpu881/SCREAM-forked-github/cases/compy_FSCREAM-LR_ne30_SCREAM-forked-github_constAero

# Set PYTHONPATH so we can make cime calls if needed
LIBDIR=/compyfs/shpu881/SCREAM-forked-github/cime/scripts/lib
export PYTHONPATH=$LIBDIR:$PYTHONPATH

# get new lid
lid=$(python -c 'import CIME.utils; print CIME.utils.new_lid()')
export LID=$lid

# setup environment
source .env_mach_specific.sh

# Clean/make timing dirs
RUNDIR=$(./xmlquery RUNDIR --value)
if [ -e $RUNDIR/timing ]; then
    /bin/rm $RUNDIR/timing
fi
mkdir -p $RUNDIR/timing/checkpoints

# minimum namelist action
./preview_namelists --component cpl
#./preview_namelists # uncomment for full namelist generation

# uncomment for lockfile checking
# ./check_lockedfiles

# setup OMP_NUM_THREADS
export OMP_NUM_THREADS=$(./xmlquery THREAD_COUNT --value)

# save prerun provenance?

# MPIRUN!
cd $(./xmlquery RUNDIR --value)
srun --mpi=pmi2 --ntasks=800 --nodes=20 --kill-on-bad-exit -l --cpu_bind=cores -c 1 -m plane=40 /compyfs/shpu881/e3sm_scratch/compy_FSCREAM-LR_ne30_SCREAM-forked-github_constAero/bld/e3sm.exe   >> e3sm.log.$LID 2>&1 

# save logs?

# save postrun provenance?

# resubmit ?
