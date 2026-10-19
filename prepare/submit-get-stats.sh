#!/bin/bash
#SBATCH --job-name=spear_get_stats
#SBATCH --account=gfdlport
#SBATCH --partition=u1-compute
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=256G
#SBATCH --output=logs/spear_get_stats.%A
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=uriel.ramirez@noaa.gov

set -e

module load rdhpcs-conda/25.11.0
conda activate ace-emulator-env-h100

# Configuration variables
################################
source "../config/config.sh"
cd ${STATS_OUT}

# Get statistics on the atmosphere file
################################
cat <<EOF > "spear_atmos_config.yaml"
data_output_directory: "${DATA_DIR}"

runs:
  "${ATM_FILE}": "atmos_3d"

stats:
  output_directory: "${STATS_OUT}"
  data_type: CM4
  start_date: "${TRAIN_START}T00:00:00"
  end_date: "${TRAIN_END}T00:00:00"
EOF
python ${ACE_REPO_DIR}/scripts/data_process/get_stats.py spear_atmos_config.yaml 0

# Get statistics on the ocean file
################################
cat <<EOF > "spear_ocean_config.yaml"
data_output_directory: "${DATA_DIR}"

runs:
  "${OCN_FILE}": "ocean_3d"

stats:
  output_directory: "${STATS_OUT}"
  data_type: CM4
  start_date: "${TRAIN_START}T00:00:00"
  end_date: "${TRAIN_END}T00:00:00"

EOF
python ${ACE_REPO_DIR}/scripts/data_process/get_stats.py spear_ocean_config.yaml 0
