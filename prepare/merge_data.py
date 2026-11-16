from pathlib import Path
import click
import logging
import yaml
import xarray as xr

logger = logging.getLogger(__name__)
nlevels = 8

@click.command()
@click.option(
    "--debug",
    is_flag=True,
    help="Enable debug logging."
)
@click.argument('data_path', type=click.Path(dir_okay=True, file_okay=False))
@click.argument("time_string", type=str)
@click.argument("nensemble", type=int)
@click.argument("data_type", type=str)
@click.argument('config_path', type=click.Path(dir_okay=True, file_okay=False))
def merge_data(data_path, time_string, nensemble, data_type, config_path, debug):

    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    if debug:
        logger.setLevel(logging.DEBUG)

    yaml_config = open_yaml_file(f"{config_path}/variables.{data_type}.yaml")

    logger.debug(f"Start merging data for {time_string} - {data_type}")

    for i in range(1, nensemble+1):
        ensemble = f"ens_{i:02d}"

        logger.debug(f"---> Working on {ensemble}")
        merge_yearly_data(time_string, yaml_config, ensemble, data_path, data_type)

    logger.debug("All done")

def seperate_3d_variable(var_data, variable, new_varname):
    vars_out = {}
    if len(var_data.dims) == 4:
        vdim = var_data.dims[1]
    else:
        vdim = var_data.dims[0]

    for i, level_val in enumerate(var_data[vdim].values):
        var_name = f"{new_varname}_{i}"
        level_data = var_data.isel({vdim: i})
        level_data = level_data.drop_vars(vdim)
        level_data = level_data.rename(var_name)
        level_data.attrs = var_data.attrs.copy()

        level_data.attrs['long_name'] = var_name
        level_data.encoding.clear()

        vars_out[var_name] = level_data

    return vars_out


def open_wrap(file_path):
    ds = xr.open_dataset(file_path)

    rename_dict = {}
    if 'grid_xt' in ds.dims: rename_dict['grid_xt'] = 'lon'
    if 'grid_yt' in ds.dims: rename_dict['grid_yt'] = 'lat'
    if 'xT' in ds.dims: rename_dict['xT'] = 'lon'
    if 'yT' in ds.dims: rename_dict['yT'] = 'lat'
    if 'xh' in ds.dims: rename_dict['xh'] = 'lon'
    if 'yh' in ds.dims: rename_dict['yh'] = 'lat'

    if rename_dict:
        ds = ds.rename(rename_dict)

    return ds


def clean_up_2d_var(var_data, new_name, subsample):
    var_data = var_data.rename(new_name)

    if subsample:
        var_data = var_data.resample(time='5D').mean(dim='time', keep_attrs=True)
        print(var_data.dims[0])

    var_data.encoding.clear()
    return var_data


def align_coords(var_da, ds_out):
    """
    Forces incoming DataArrays to use the existing coordinates of ds_out
    if the dimensions exist and the sizes match, preventing outer-join NaNs.
    """
    for dim in var_da.dims:
        if dim in ds_out.coords and ds_out.sizes[dim] == var_da.sizes[dim]:
            var_da = var_da.assign_coords({dim: ds_out.coords[dim]})
    return var_da


def merge_yearly_data(year, yaml_config, ensemble, data_path, data_type):

    output_zar = Path(data_path) / f"merged/{year}.{data_type}.{ensemble}.zarr"
    if output_zar.exists():
        logger.debug("File already created ... skipping ...")
        return

    ds_out = xr.Dataset()

    # Ocean's 3D variables are in the regrid/ directory since they were coarsed
    # in the model runs
    coarsed_dir = "coarsed"
    if data_type == "ocean": coarsed_dir = "regrid"

    for file in yaml_config:
        file_config = yaml_config[file]
        coarsed_variables = file_config.get('coarsed')
        if coarsed_variables:
            file_path = Path(data_path) / f"{coarsed_dir}/{year}/{year}.{file}.{ensemble}.nc"
            logger.debug(f"Getting variables from {file_path}")

            ds = open_wrap(file_path)
            for variable in coarsed_variables:
                logger.debug(f"Working on {variable} in {file}")

                var_data = ds[variable]
                new_name = variable
                if isinstance(coarsed_variables[variable], dict):
                    new_name = coarsed_variables[variable].get('rename', variable)
                vars_out = seperate_3d_variable(var_data, variable, new_name)

                if variable == "thetao":
                    # Use the thetao variables to generate a mask
                    logger.debug(f"---> Generating a mask based on {variable}")
                    var_data = ds[variable].isel(time=0).drop_vars('time', errors='ignore')
                    valid_mask = var_data.notnull().astype("uint8")
                    valid_mask.name = "mask"
                    valid_mask.attrs = {
                        "long_name": "Valid data mask for sea water potential temperature",
                        "units": "0 if land, 1 if ocean"
                    }
                    mask_out = seperate_3d_variable(valid_mask, "mask", "mask")
                    vars_out = vars_out | mask_out

                if variable == "uo" or variable == "vo":
                    # Get SSU and SSV for uo and vo, these are the values at the surface
                    logger.debug(f"---> Getting SSU or SSV based on {variable}")
                    sea_surfarce_vel = get_sea_surface_velocties(var_data, variable)
                    vars_out = vars_out | sea_surfarce_vel

                for var_name, var_da in vars_out.items():
                    # This is needed to align the coordinates since the velocties and the rest
                    # of the variables are regridded differently
                    var_da = align_coords(var_da, ds_out)
                    ds_out[var_name] = var_da

            ds.close()
            logger.debug("....................................")

        surface_variables = file_config.get('2d')
        if surface_variables:
            file_path = Path(data_path) / f"regrid/{year}/{year}.{file}.{ensemble}.nc"
            logger.debug(f"Getting variables from {file_path}")

            ds = open_wrap(file_path)
            for variable in surface_variables:
                logger.debug(f"Working on {variable} in {file}")

                new_name = variable
                duplicate_name = None
                subsample = False
                var_data = ds[variable]
                if isinstance(surface_variables[variable], dict):
                    if "derive" in surface_variables[variable]:
                        # These variables are derivded by multiply it by a constant
                        info = surface_variables[variable]['derive']
                        scale_factor = info.get('scale_factor', 1.0)
                        units = info['units']
                        new_name = info['rename']
                        long_name = info['long_name']
                        subsample = info.get('subsample', False)

                        var_data = ds[variable] * float(scale_factor)
                        var_data = var_data.rename(new_name)
                        var_data.attrs = ds[variable].attrs.copy()
                        var_data.attrs['long_name'] = long_name
                        var_data.attrs['units'] = units
                    else:
                        new_name = surface_variables.get(variable, {}).get("rename", variable)
                        duplicate_name = surface_variables.get(variable, {}).get("duplicate_name", None)
                        subsample = surface_variables.get(variable, {}).get("subsample", False)

                var_to_add = clean_up_2d_var(var_data, new_name, subsample)
                var_to_add = align_coords(var_to_add, ds_out)
                ds_out[new_name] = var_to_add
                if duplicate_name:
                    dup_to_add = clean_up_2d_var(ds[variable], duplicate_name, subsample)
                    dup_to_add = align_coords(dup_to_add, ds_out)
                    ds_out[duplicate_name] = dup_to_add

            ds.close()
            logger.debug("....................................")

    if "scalar_axis" in ds_out.dims:
        # Classic GFDL -- remove the "scalar_axis" for the carbon dioxide diagnostic
        if ds_out.sizes["scalar_axis"] != 1:
            raise RuntimeError(
                f"scalar_axis has size {ds_out.sizes['scalar_axis']}, expected 1."
            )
        ds_out = ds_out.squeeze(dim="scalar_axis", drop=True)

    for var in ds_out.variables.values():
        var.encoding.clear()

    variables = list(ds_out.variables)

    logger.debug(f"Writing dataset to {output_zar}")

    ds_out.to_zarr(output_zar, mode='w', consolidated=True)


def get_sea_surface_velocties(var_data, variable):
    vars_out = {}
    surf_data = var_data.isel(z_l=0).drop_vars('z_l', errors='ignore')
    if variable == "uo":
        surf_data.name = "ssu"
        surf_data.attrs = {
            'long_name': 'Sea Surface Eastward Velocity',
            'standard_name': 'surface_eastward_sea_water_velocity',
            'units': var_data.attrs.get('units', 'm s-1'),
            'description': 'Ocean surface eastward velocity extracted from the top model layer (2.5m).'
        }
        vars_out['ssu'] = surf_data
    elif variable == "vo":
        surf_data.name = "ssv"
        surf_data.attrs = {
            'long_name': 'Sea Surface Northward Velocity',
            'standard_name': 'surface_northward_sea_water_velocity',
            'units': var_data.attrs.get('units', 'm s-1'),
            'description': 'Ocean surface northward velocity extracted from the top model layer (2.5m).'
        }
        vars_out['ssv'] = surf_data

    return vars_out

def open_yaml_file(yaml_file):
    config_file = Path(yaml_file)
    with config_file.open("r") as f:
        config = yaml.safe_load(f)
    return config


if __name__ == '__main__':
    merge_data()


