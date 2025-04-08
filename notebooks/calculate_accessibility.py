from pathlib import Path
from typing import Any

import geopandas as gpd
import pandas as pd
from common import load_stops
from shapely.geometry import Polygon
from valhalla import Actor, get_config


def get_isochrone(query: dict, actor: Actor):
    result = {}
    isochrones = actor.isochrone(query)
    for contour_ix, isochrone in enumerate(isochrones["features"]):
        geom = isochrone["geometry"]["coordinates"]
        time = isochrone["properties"]["contour"]
        result[time] = Polygon(geom)
    return result


def build_walk_query(
    location: dict[str, float], times: list[int] = [5, 10, 15, 20]
) -> dict[str, Any]:
    return {
        "locations": [location],
        "costing": "pedestrian",
        "contours": [{"time": i} for i in times],
    }


def build_bicycle_query(
    location: dict[str, float], times: list[int] = [10, 15, 30]
) -> dict[str, Any]:
    return {
        "locations": [location],
        "costing": "bicycle",
        "contours": [{"time": i} for i in times],
    }


def build_car_query(
    location: dict[str, float], times: list[int] = [10, 15, 30]
) -> dict[str, Any]:
    return {
        "locations": [location],
        "costing": "auto",
        "contours": [{"time": i} for i in times],
    }


def determine_isochrones(
    stops: gpd.GeoDataFrame, actor: Actor, times: list[int] = [5, 10, 15]
) -> pd.DataFrame:
    isochones = []
    for row in stops.itertuples():
        w = get_isochrone(
            build_walk_query({"lon": row.stop_lon, "lat": row.stop_lat}, times=times),
            actor,
        )
        b = get_isochrone(
            build_bicycle_query(
                {"lon": row.stop_lon, "lat": row.stop_lat}, times=times
            ),
            actor,
        )
        for t in times:
            isochones.append([row.stop_id, w[t], "walk", t])
            isochones.append([row.stop_id, b[t], "bicycle", t])
    return pd.DataFrame.from_records(
        isochones, columns=["stop_id", "geometry", "costing", "range"]
    )


def initialize_valhalla(city: str) -> Actor:
    config = get_config(
        tile_extract=f"../data/valhalla/{city}/valhalla_tiles.tar",
        verbose=True,
    )

    config["service_limits"]["isochrone"]["max_contours"] = 10
    config["service_limits"]["isochrone"]["max_locations"] = 10_000
    config["service_limits"]["isochrone"]["max_distance"] = 100_000

    return Actor(config)


if __name__ == "__main__":
    import argparse

    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        "--city",
        type=str,
        required=True,
        help="city ID (lowercase name)",
    )
    argparser.add_argument(
        "--data-version",
        type=str,
        default="",
        help="data version (subfolder in city)",
    )
    opts = argparser.parse_args()
    stops = load_stops(opts.city, opts.data_version)
    actor = initialize_valhalla(opts.city)

    path = f"../output/{opts.city}/{opts.data_version}"
    Path(path).mkdir(parents=True, exist_ok=True)

    isochones = determine_isochrones(stops, actor)
    isochones.to_csv(f"{path}/isochrones.csv", index=False)

    isochrones_gdf = gpd.GeoDataFrame(isochones, geometry="geometry", crs=4326)
    isochrones_gdf.to_file(f"{path}/isochrones.geojson")
