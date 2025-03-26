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


def load_isochrones(city: str) -> gpd.GeoDataFrame:
    isochrones = gpd.read_file(f"../output/{city}/isochrones.geojson", engine="pyogrio")
    isochrones["stop_id"] = isochrones["stop_id"].apply(str)
    return isochrones


def load_amenity_categories():
    with open("../data/essential_amenities.yaml", "r") as fp:
        essential_amenities = yaml.safe_load(fp)
    return essential_amenities


def create_lookup(essential_amenities: dict[str, list[str]]) -> dict[str, str]:
    result = {}
    for cat, osm_list in essential_amenities.items():
        for i in osm_list:
            result[i] = cat
    return result


def load_category_lookup():
    essential_amenities = load_amenity_categories()
    return create_lookup(essential_amenities)
