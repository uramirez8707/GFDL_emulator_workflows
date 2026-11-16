# Load the modules and source the environment
module load frameworks
source /home/urielramirez/.venvs/ace_aurora/bin/activate

WORKFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_REPO_DIR="${WORKFLOW_ROOT}/../ace"

# Number of epochs to run at a time
NEPOCHS=1

# Aurora nodes have 6 GPUs x 2 tiles = 12 devices per node.
NUM_TILES=12

# Directory where the zarr datasets are created
DATA_DIR=/flare/S2S-AI/Uriel.Ramirez/ACE_TRAINING_JOBS/Datasets/SPEAR_LO
ATM_FILE="1851-2000_merged.atmos.ens_01"
OCN_FILE="1851-2000_merged.ocean.ens_01"

# Directory where the stats directory were created
STATS_DIR=/flare/S2S-AI/Uriel.Ramirez/ACE_TRAINING_JOBS/Stats/SPEAR_LO

# Set up the validation/training starts/ends
TRAIN_START=1851-01-06
TRAIN_END=1989-12-31
VALIDATION_START=1990-01-01
VALIDATION_END=1999-12-31

# WAND Configuration
# TODO Aurora's compute nodes have access to the internet so this can probably
# be done online
WANDB_DATA_DIR=$WORKING_DIR/wandb
export WANDB_MODE=offline
# NOTE: wandb_dir_in_experiment_dir needs to be set to True or it will write it out
# into the tmp/ directory
export WANDB_DIR="${WORKING_DIR}"
WAND_USERNAME="uramirez8707-"

# Ensure venv Python and packages are prioritized across all child processes
export VENV_DIR="/home/urielramirez/.venvs/ace_aurora"
export ACE_REPO_DIR="/home/urielramirez/GFDL_emulator_workflows/ace"
export PATH="$VENV_DIR/bin:$PATH"
export PYTHONPATH="$ACE_REPO_DIR:$VENV_DIR/lib/python3.12/site-packages:$PYTHONPATH"

# ALCF Network Proxies (for WandB and git)
export http_proxy="http://proxy.alcf.anl.gov:3128"
export https_proxy="http://proxy.alcf.anl.gov:3128"
export ftp_proxy="http://proxy.alcf.anl.gov:3128"

# Intel oneAPI & oneCCL Settings for torchrun
export CCL_PROCESS_LAUNCHER=none
export CCL_ATL_TRANSPORT=ofi
export CCL_ALLREDUCE_ALGO=ring

export RAYON_NUM_THREADS=1
export OMP_NUM_THREADS=1
