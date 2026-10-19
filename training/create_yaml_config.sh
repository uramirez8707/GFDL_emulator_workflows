#!/bin/bash

set -e

BASE_DIR="$1"
WORKING_DIR="$2"
DATA_DIR="$3"
STATS_DIR="$4"
TRAIN_START="$5"
TRAIN_END="$6"
VALIDATION_START="$7"
VALIDATION_END="$8"
RUN_NAME="$9"

cat <<EOF > "config.yaml"
experiment_dir: ${WORKING_DIR}
save_checkpoint: true
validate_using_ema: true
ema:
  decay: 0.999
max_epochs: 10
segment_epochs: 1
logging:
  log_to_screen: true
  log_to_wandb: true
  log_to_file: true
  project: ${RUN_NAME}
  entity: "uramirez8707-"
  wandb_dir_in_experiment_dir: true
train_loader:
  batch_size: 2
  num_data_workers: 1
  prefetch_factor: 1
  dataset:
    ocean:
      merge:
        - data_path: ${DATA_DIR}
          file_pattern: 1851-2000_merged.ocean.ens_01_fixed.zarr
          engine: zarr
          subset:
            start_time: "${TRAIN_START}"
            stop_time: "${TRAIN_END}"
    atmosphere:
      merge:
        - data_path: ${DATA_DIR}
          file_pattern: 1851-2000_merged.atmos.ens_01.zarr
          engine: zarr
          subset:
            start_time: "${TRAIN_START}"
            stop_time: "${TRAIN_END}"
validation:
  loader:
    batch_size: 2
    num_data_workers: 1
    prefetch_factor: 1
    dataset:
      ocean:
        merge:
          - data_path: ${DATA_DIR}
            file_pattern: 1851-2000_merged.ocean.ens_01_fixed.zarr
            engine: zarr
            subset:
              start_time: "${VALIDATION_START}"
              stop_time: "${VALIDATION_END}"
      atmosphere:
        merge:
          - data_path: ${DATA_DIR}
            file_pattern: 1851-2000_merged.atmos.ens_01.zarr
            engine: zarr
            subset:
              start_time: "${VALIDATION_START}"
              stop_time: "${VALIDATION_END}"

optimization:
  enable_automatic_mixed_precision: false
  lr: 0.0001
  optimizer_type: FusedAdam
  kwargs:
    weight_decay: 0.01
  use_gradient_accumulation: true
stepper_training:
  n_coupled_steps: 4
  ocean:
    parameter_init:
      weights_path: "${BASE_DIR}/CHECKPOINTS/ocean_ckpt.tar"
    loss:
      type: MSE
    n_steps: 4
    loss_weight: 1.0
  atmosphere:
    parameter_init:
      weights_path: "${BASE_DIR}/CHECKPOINTS/atmos_ckpt.tar"
    n_steps: 4
    loss:
      type: MSE
      weights:
        air_temperature_0: 0.5
        air_temperature_1: 0.5
        eastward_wind_0: 0.5
        northward_wind_0: 0.5
        specific_total_water_0: 0.5
        specific_total_water_1: 0.25
        specific_total_water_2: 0.5
        PRATEsfc: 0.5
        h500: 10
        TMP850: 5
        Q2m: 0.5
        DLWRFsfc: 2
        ULWRFsfc: 5
        USWRFsfc: 2
        DSWRFsfc: 2
        USWRFtoa: 2
        tendency_of_total_water_path_due_to_advection: 0.5
stepper:
  ocean_fraction_prediction:
    land_fraction_name: land_fraction
    sea_ice_fraction_name: ocean_sea_ice_fraction
    sea_ice_fraction_name_in_atmosphere: sea_ice_fraction
  sst_name: sst
  ocean:
    timedelta: 5D
    # stepper added by train.sh from uncoupled-ocean/train-config.yaml

    stepper:
      input_masking:
        mask_value: 0
        fill_value: 0.0
        exclude_names_and_prefixes:
          - land_fraction
      step:
        type: single_module
        config:
          builder:
            type: Samudra
            config:
              ch_width:
                - 200
                - 250
                - 300
                - 400
              dilation:
                - 1
                - 2
                - 4
                - 8
              n_layers:
                - 1
                - 1
                - 1
                - 1
              norm: instance
          normalization:
            network:
              fill_nans_on_normalize: true
              global_means_path: ${STATS_DIR}/ocean/1851-2000_merged.ocean.ens_01/centering_patched.nc
              global_stds_path: ${STATS_DIR}/ocean/1851-2000_merged.ocean.ens_01/scaling-full-field_patched.nc
          corrector:
            type: ocean_corrector
            config:
              force_positive_names:
                - so_0
                - so_1
                - so_2
                - so_3
                - so_4
                - so_5
                - so_6
                - so_7
                - so_8
                - so_9
                - so_10
                - so_11
                - so_12
                - so_13
                - so_14
                - so_15
                - so_16
                - so_17
                - so_18
                - HI
              sea_ice_fraction_correction:
                sea_ice_fraction_name: ocean_sea_ice_fraction
                land_fraction_name: land_fraction
                remove_negative_ocean_fraction: false
          next_step_forcing_names:
            - DLWRFsfc
            - DSWRFsfc
            - ULWRFsfc
            - USWRFsfc
            - LHTFLsfc
            - SHTFLsfc
            - PRATEsfc
            - eastward_surface_wind_stress
            - northward_surface_wind_stress
          in_names:
            - DLWRFsfc
            - DSWRFsfc
            - ULWRFsfc
            - USWRFsfc
            - LHTFLsfc
            - SHTFLsfc
            - PRATEsfc
            - eastward_surface_wind_stress
            - northward_surface_wind_stress
            - land_fraction
            - sst
            - zos
            - so_0
            - so_1
            - so_2
            - so_3
            - so_4
            - so_5
            - so_6
            - so_7
            - so_8
            - so_9
            - so_10
            - so_11
            - so_12
            - so_13
            - so_14
            - so_15
            - so_16
            - so_17
            - so_18
            - thetao_0
            - thetao_1
            - thetao_2
            - thetao_3
            - thetao_4
            - thetao_5
            - thetao_6
            - thetao_7
            - thetao_8
            - thetao_9
            - thetao_10
            - thetao_11
            - thetao_12
            - thetao_13
            - thetao_14
            - thetao_15
            - thetao_16
            - thetao_17
            - thetao_18
            - uo_0
            - uo_1
            - uo_2
            - uo_3
            - uo_4
            - uo_5
            - uo_6
            - uo_7
            - uo_8
            - uo_9
            - uo_10
            - uo_11
            - uo_12
            - uo_13
            - uo_14
            - uo_15
            - uo_16
            - uo_17
            - uo_18
            - vo_0
            - vo_1
            - vo_2
            - vo_3
            - vo_4
            - vo_5
            - vo_6
            - vo_7
            - vo_8
            - vo_9
            - vo_10
            - vo_11
            - vo_12
            - vo_13
            - vo_14
            - vo_15
            - vo_16
            - vo_17
            - vo_18
            - ocean_sea_ice_fraction
            - HI
          out_names:
            - sst
            - zos
            - so_0
            - so_1
            - so_2
            - so_3
            - so_4
            - so_5
            - so_6
            - so_7
            - so_8
            - so_9
            - so_10
            - so_11
            - so_12
            - so_13
            - so_14
            - so_15
            - so_16
            - so_17
            - so_18
            - thetao_0
            - thetao_1
            - thetao_2
            - thetao_3
            - thetao_4
            - thetao_5
            - thetao_6
            - thetao_7
            - thetao_8
            - thetao_9
            - thetao_10
            - thetao_11
            - thetao_12
            - thetao_13
            - thetao_14
            - thetao_15
            - thetao_16
            - thetao_17
            - thetao_18
            - uo_0
            - uo_1
            - uo_2
            - uo_3
            - uo_4
            - uo_5
            - uo_6
            - uo_7
            - uo_8
            - uo_9
            - uo_10
            - uo_11
            - uo_12
            - uo_13
            - uo_14
            - uo_15
            - uo_16
            - uo_17
            - uo_18
            - vo_0
            - vo_1
            - vo_2
            - vo_3
            - vo_4
            - vo_5
            - vo_6
            - vo_7
            - vo_8
            - vo_9
            - vo_10
            - vo_11
            - vo_12
            - vo_13
            - vo_14
            - vo_15
            - vo_16
            - vo_17
            - vo_18
            - ocean_sea_ice_fraction
            - HI
  atmosphere:
    timedelta: 6h
    # stepper added by train.sh from uncoupled-atmos/train-config.yaml

    stepper:
      step:
        type: single_module
        config:
          builder:
            type: SphericalFourierNeuralOperatorNet
            config:
              embed_dim: 384
              filter_type: linear
              hard_thresholding_fraction: 1.0
              use_mlp: true
              normalization_layer: instance_norm
              num_layers: 8
              operator_type: dhconv
              scale_factor: 1
              separable: false
              spectral_layers: 3
              spectral_transform: sht
          normalization:
            network:
              fill_nans_on_normalize: true
              global_means_path: ${STATS_DIR}/atmos/1851-2000_merged.atmos.ens_01/centering_patched.nc
              global_stds_path: ${STATS_DIR}/atmos/1851-2000_merged.atmos.ens_01/scaling-full-field_patched.nc
            residual:
              global_means_path: ${STATS_DIR}/atmos/1851-2000_merged.atmos.ens_01/centering_patched.nc
              global_stds_path: ${STATS_DIR}/atmos/1851-2000_merged.atmos.ens_01/scaling-residual_patched.nc
          ocean:
            surface_temperature_name: surface_temperature
            ocean_fraction_name: ocean_fraction
          corrector:
            conserve_dry_air: true
            moisture_budget_correction: advection_and_precipitation
            force_positive_names:
              - specific_total_water_0
              - specific_total_water_1
              - specific_total_water_2
              - specific_total_water_3
              - specific_total_water_4
              - specific_total_water_5
              - specific_total_water_6
              - specific_total_water_7
              - Q2m
              - PRATEsfc
              - ULWRFsfc
              - ULWRFtoa
              - DLWRFsfc
              - DSWRFsfc
              - USWRFsfc
              - USWRFtoa
          next_step_forcing_names:
            - DSWRFtoa
          in_names:
            - land_fraction
            - lake_fraction
            - ocean_fraction
            - sea_ice_fraction
            - DSWRFtoa
            - HGTsfc
            - PRESsfc
            - surface_temperature
            - TMP2m
            - Q2m
            - UGRD10m
            - VGRD10m
            - air_temperature_0
            - air_temperature_1
            - air_temperature_2
            - air_temperature_3
            - air_temperature_4
            - air_temperature_5
            - air_temperature_6
            - air_temperature_7
            - specific_total_water_0
            - specific_total_water_1
            - specific_total_water_2
            - specific_total_water_3
            - specific_total_water_4
            - specific_total_water_5
            - specific_total_water_6
            - specific_total_water_7
            - eastward_wind_0
            - eastward_wind_1
            - eastward_wind_2
            - eastward_wind_3
            - eastward_wind_4
            - eastward_wind_5
            - eastward_wind_6
            - eastward_wind_7
            - northward_wind_0
            - northward_wind_1
            - northward_wind_2
            - northward_wind_3
            - northward_wind_4
            - northward_wind_5
            - northward_wind_6
            - northward_wind_7
          out_names:
            - PRESsfc
            - surface_temperature
            - TMP2m
            - Q2m
            - UGRD10m
            - VGRD10m
            - air_temperature_0
            - air_temperature_1
            - air_temperature_2
            - air_temperature_3
            - air_temperature_4
            - air_temperature_5
            - air_temperature_6
            - air_temperature_7
            - specific_total_water_0
            - specific_total_water_1
            - specific_total_water_2
            - specific_total_water_3
            - specific_total_water_4
            - specific_total_water_5
            - specific_total_water_6
            - specific_total_water_7
            - eastward_wind_0
            - eastward_wind_1
            - eastward_wind_2
            - eastward_wind_3
            - eastward_wind_4
            - eastward_wind_5
            - eastward_wind_6
            - eastward_wind_7
            - northward_wind_0
            - northward_wind_1
            - northward_wind_2
            - northward_wind_3
            - northward_wind_4
            - northward_wind_5
            - northward_wind_6
            - northward_wind_7
            - LHTFLsfc
            - SHTFLsfc
            - PRATEsfc
            - ULWRFsfc
            - ULWRFtoa
            - DLWRFsfc
            - DSWRFsfc
            - USWRFsfc
            - USWRFtoa
            - tendency_of_total_water_path_due_to_advection
            - TMP850
            - h500
            - northward_surface_wind_stress
            - eastward_surface_wind_stress
EOF
