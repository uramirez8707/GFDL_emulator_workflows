# GFDL Emulator Workflows

## Installing
This repository uses Conda to manage Python dependencies, including the Ai2 Climate Emulator (`fme`) and data processing tools for netcdf output (xarray, dask, zarr). 

Because PyTorch requires different builds depending on the GPU architecture, we maintain separate environment files for NVIDIA and AMD hardware.
### For NVIDIA H100 (CUDA)
This uses the default environment.yaml which pulls the standard PyPI build of PyTorch

```bash
conda env create -f environment.yaml
conda activate ace-emulator-env-h100
```

### For AMD MI-300X (ROCm)
This uses environment-mi300x.yaml to pull the hardware-specific ROCm PyTorch wheels before installing the emulator.
```bash
conda env create -f environment-mi300x.yaml
conda activate ace-emulator-env-mi300x
```
