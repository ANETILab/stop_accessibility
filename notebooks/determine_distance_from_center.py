import geopandas as gpd
import numpy as np
import osmnx as ox
import pandas as pd
from shapely import Point, Polygon

ox.settings.use_cache = True
ox.settings.log_console = False


def read_boundary(city: str) -> Polygon:
    boundary = gpd.read_file(f"../output/{city}/boundary.geojson").set_crs(4326)
    return boundary.geometry[0]


def determine_city_centroid_by_landuse(
    boundary: Polygon,
    crs: int,
    landuse_types: list[str] = ["residential"],
    # landuse_types: list[str] = ["residential", "retail", "industrial"],
) -> Point:
    landuse = ox.features_from_polygon(
        boundary,
        tags={"landuse": landuse_types},
    )
    landuse = landuse[landuse["geometry"].geom_type == "Polygon"].copy()
    landuse.to_crs(crs, inplace=True)
    return landuse.union_all().centroid


# based on: https://stackoverflow.com/a/38022636/4737417
def distance_matrix(data: pd.DataFrame):
    result = []
    for i in data.itertuples():
        r = []
        for j in data.itertuples():
            d = np.round(i.geometry.distance(j.geometry))
            r.append(d)
        result.append(r)
    result = np.array(result)
    return result


def medoid_index(distamce_matrix: np.array) -> int:
    return int(np.argmin(distamce_matrix.sum(axis=0)))


def calculate_medoid(data: pd.DataFrame, id_column: str = "stop_id") -> int:
    dmx = distance_matrix(data)
    i = int(np.argmin(dmx.sum(axis=0)))
    return data[id_column].tolist()[i]
