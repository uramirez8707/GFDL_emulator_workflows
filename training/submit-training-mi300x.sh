#!/bin/bash
#SBATCH --account=gfdlport
#SBATCH --partition=u1-mi300x
#SBATCH --qos=gpuwf
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --gpus=mi300x:2
#SBATCH --mem=256G
#SBATCH --time=24:00:00
#SBATCH --job-name=SamudrACE_training_SPEAR-01-mi300x
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=uriel.ramirez@noaa.gov
#SBATCH --output=logs/SamudrACE_training_SPEAR-01-mi300x.%j

set -e

JOB_CONFIG_DIR=`pwd`

JOB_LABEL="SamudrACE_training-SPEAR-01-mi300x"

# Directory where all the output is at
BASE_DIR=/scratch4/GFDL/gfdlscr/Uriel.Ramirez/ACE_TRAINING_JOBS
WORKING_DIR="${BASE_DIR}/${JOB_LABEL}"
WANDB_DATA_DIR=$WORKING_DIR/wandb

# Configuration variables
################################
source "../config/config.sh"

################################

export WANDB_MODE=offline

# NOTE: wandb_dir_in_experiment_dir needs to be set to True or it will write it out
# into the tmp/ directory
export WANDB_DIR="${WORKING_DIR}"
#################################

# Load the environment:
module load rdhpcs-conda/25.11.0
conda activate ace-emulator-env-mi300x

mkdir -p "${WORKING_DIR}"
cd "${WORKING_DIR}"

# Create the configuration file to work from
$JOB_CONFIG_DIR/create_yaml_config.sh \
       $BASE_DIR $WORKING_DIR $DATA_DIR $STATS_DIR \
       $TRAIN_START $TRAIN_END $VALIDATION_START $VALIDATION_END \
       $JOB_LABEL $WAND_USERNAME $OCN_FILE $ATM_FILE

echo "Finished creating the yaml_config to ${WORKING_DIR}"

for ((i=1; i<=NEPOCHS; i++)); do
    # Synch WandB if resuming training ...
    if [ -d $WANDB_DATA_DIR ]; then
        sbatch --wait --output=logs/SamudrACE_training_orch.%j \
		--open-mode=append \
		$JOB_CONFIG_DIR/sbatch-wandb-sync.sh \
           $WORKING_DIR
	echo "Finished synching WANB to ${WANDB_DATA_DIR}"
    fi
    # Run the training job ...
    RANDOM_PORT=$(expr 10000 + $RANDOM % 20000)
    torchrun --nproc_per_node=2 --master_port=$RANDOM_PORT -m fme.coupled.train config.yaml

    echo "FINISHED WITH EPOCH ...."
    echo "------------------------------------------------------------------------------------"
done


