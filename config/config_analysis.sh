module load conda
conda activate ace-emulator-env-h100

WORKFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_REPO_DIR="${WORKFLOW_ROOT}/../ace"

# Number of epochs to run at a time
NEPOCHS=1

# Directory where the zarr datasets are created
DATA_DIR=/ptmp/unr/testing_junk
ATM_FILE="19410101.atmos.ens_01"
OCN_FILE="19410101.ocean.ens_01"

# Directory where the stats directory were created
STATS_OUT="${DATA_DIR}/stats"

# Set up the validation/training starts/ends
TRAIN_START=1941-01-01
TRAIN_END=1941-10-31
VALIDATION_START=1941-11-01
VALIDATION_END=1941-12-31

WAND_USERNAME="uramirez8707-"
