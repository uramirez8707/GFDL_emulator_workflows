#!/bin/bash
#PBS -A S2S-AI
#PBS -q debug
#PBS -l select=1
#PBS -l walltime=00:10:00
#PBS -l filesystems=home:flare
#PBS -N SamudrACE_training_SPEAR-01-intel
#PBS -m bea
#PBS -M uriel.ramirez@noaa.gov
#PBS -o logs/
#PBS -j oe

set -e

cd "$PBS_O_WORKDIR"
JOB_CONFIG_DIR=`pwd`
echo $JOB_CONFIG_DIR

JOB_LABEL="SamudrACE_training-SPEAR-01-intel"

# Directory where all the output is at
BASE_DIR=/flare/S2S-AI/Uriel.Ramirez/ACE_TRAINING_JOBS/Output
WORKING_DIR="${BASE_DIR}/${JOB_LABEL}"

# Configuration variables + load the environment
################################
source "../config/config_Aurora.sh"

mkdir -p "${WORKING_DIR}"
cd "${WORKING_DIR}"

# Create the configuration file to work from
$JOB_CONFIG_DIR/create_yaml_config.sh \
       $BASE_DIR $WORKING_DIR $DATA_DIR $STATS_DIR \
       $TRAIN_START $TRAIN_END $VALIDATION_START $VALIDATION_END \
       $JOB_LABEL $WAND_USERNAME $OCN_FILE $ATM_FILE

echo "Finished creating the yaml_config to ${WORKING_DIR}"

for ((i=1; i<=NEPOCHS; i++)); do
    RANDOM_PORT=$(expr 10000 + $RANDOM % 20000)

    echo "=== Starting Epoch $i on $NUM_TILES tiles ==="
    python3 -m torch.distributed.run \
            --nproc_per_node=$NUM_TILES \
            --master_port=$RANDOM_PORT \
            -m fme.coupled.train config.yaml

    if [ -d "$WANDB_DATA_DIR" ]; then
        echo "Syncing WandB logs..."
        wandb sync "$WANDB_DATA_DIR"
    fi

    echo "=== Finished Epoch $i ==="
done
