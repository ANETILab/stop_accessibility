import geopandas as gpd
import pandas as pd
import yaml
from shapely import Point


def load_stops(city: str) -> gpd.GeoDataFrame:
    stops = pd.read_csv(
        f"../data/stops/{city}/stops_with_centrality.csv",
        engine="pyarrow",
        dtype={"stop_id": str},
    )
    stops["geometry"] = stops.apply(
        lambda x: Point(x["stop_lon"], x["stop_lat"]), axis=1
    )
    stops = gpd.GeoDataFrame(stops, geometry="geometry", crs=4326)
    return stops


def load_crs():
    with open("../data/crs.yaml", "r") as fp:
        crs = yaml.safe_load(fp)
    return crs
