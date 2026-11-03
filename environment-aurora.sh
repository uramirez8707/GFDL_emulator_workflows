#!/bin/bash
set -e

ENV_PATH="$HOME/.venvs/ace_aurora"

echo "Loading ALCF Intel AI Frameworks..."
module load frameworks

echo "Creating virtual environment at $ENV_PATH..."
python3 -m venv "$ENV_PATH" --system-site-packages
source "$ENV_PATH/bin/activate"

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing ACE runtime and GFDL emulator dependencies..."
pip install \
    xarray \
    netCDF4 \
    h5py \
    pyyaml \
    einops \
    wandb \
    dask \
    dataclasses-json \
    dacite \
    omegaconf \
    tensorly \
    tensorly-torch \
    "torch-harmonics==0.8.0" \
    cartopy \
    zarr \
    "zarrs>=0.2.3" \
    imageio \
    moviepy \
    plotly \
    gcsfs \
    s3fs

echo "Installing ACE in editable mode..."
# Using --no-deps prevents pip from pulling a generic PyPI PyTorch over Intel's build
if [ -d "./ace" ]; then
    pip install --no-deps -e ./ace
fi

echo "=================================================="
echo "Environment setup complete."
echo "Activate it anytime using:"
echo "module load frameworks && source $ENV_PATH/bin/activate"
echo "=================================================="
