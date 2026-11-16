#!/bin/bash
#SBATCH --job-name=spear_merge
#SBATCH --account=gfdl_f
#SBATCH --partition=batch
#SBATCH --time=16:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=128G
#SBATCH --output=logs/spear_merge_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=uriel.ramirez@noaa.gov
#SBATCH --array=0-0%30

YEAR=${1:?Usage: sbatch <script> YEAR}

# Load the environment configuration variables
CONFIG_PATH="../config"
source "${CONFIG_PATH}/config_analysis.sh"

CURRENT_YEAR=$((${YEAR} + SLURM_ARRAY_TASK_ID))
TARGET_YEAR="${CURRENT_YEAR}0101"

echo "============================================="
echo "Starting job for year: ${SLURM_ARRAY_TASK_ID}"
echo "Running on node: $(hostname)"
echo "============================================="

# python merge_data.py "$DATA_DIR" "$TARGET_YEAR" "1" "atmos" "$CONFIG_PATH" --debug
python merge_data.py "$DATA_DIR" "$TARGET_YEAR" "1" "ocean" "$CONFIG_PATH" --debug

echo "Job for ${SLURM_ARRAY_TASK_ID} completed."
