#!/bin/bash

#SBATCH --job-name=wandb-sync
#SBATCH --partition=u1-service
#SBATCH --account=gfdlport
#SBATCH --ntasks=1
#SBATCH --time=1:00:00
#SBATCH --output=stdout/%x.%j.out

FME_OUTPUT_DIR="$1"

module load rdhpcs-python/3.12
source /scratch4/GFDL/gfdlscr/Uriel.Ramirez/DEV/ACE_TESTING/my_env_mi300x_py312/bin/activate

cd $FME_OUTPUT_DIR
wandb sync --sync-all --append wandb

