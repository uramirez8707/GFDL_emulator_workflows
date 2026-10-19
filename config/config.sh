WORKFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_REPO_DIR="${WORKFLOW_ROOT}/../ace"

# Number of epochs to run at a time
NEPOCHS=1

# Directory where the zarr datasets are created
DATA_DIR=/scratch4/GFDL/gfdlscr/Uriel.Ramirez/archive_090926
ATM_FILE="1851-2000_merged.atmos.ens_01"
OCN_FILE="1851-2000_merged.ocean.ens_01_fixed"

# Directory where the stats directory were created
STATS_DIR=/scratch4/GFDL/gfdlscr/Uriel.Ramirez/DEV/ACE_TESTING/working_dir/test3
STATS_OUT=/scratch4/GFDL/gfdlscr/Uriel.Ramirez/archive_090926/stats

# Set up the validation/training starts/ends
TRAIN_START=1851-01-06
TRAIN_END=1990-01-01
VALIDATION_START=1990-01-06
VALIDATION_END=2000-01-01

WAND_USERNAME="uramirez8707-"
