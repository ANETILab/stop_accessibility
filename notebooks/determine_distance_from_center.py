import geopandas as gpd
import numpy as np
import osmnx as ox
import pandas as pd
from shapely import Point, Polygon, distance

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
def distance_matrix(data: pd.DataFrame) -> np.ndarray:
    result = []
    for i in data.itertuples():
        r = []
        for j in data.itertuples():
            d = np.round(distance(i.geometry, j.geometry))
            r.append(d)
        result.append(r)
    return np.asarray(result)


def medoid_index(distamce_matrix: np.ndarray) -> int:
    return int(np.argmin(distamce_matrix.sum(axis=0)))


def calculate_medoid(data: pd.DataFrame, id_column: str = "stop_id") -> int:
    dmx = distance_matrix(data)
    i = int(np.argmin(dmx.sum(axis=0)))
    return data[id_column].tolist()[i]


if __name__ == "__main__":
    import argparse

    from common import load_crs, load_stops

    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        "--city",
        type=str,
        required=True,
        help="city ID (lowercase name)",
    )
    argparser.add_argument(
        "--centrality",
        type=str,
        default="Betweenness Centrality",
        required=False,
        help="centrality measure to use, possible values: Eigenvector Centrality, Degree Centrality, Closeness Centrality, Betweenness Centrality",
    )
    opts = argparser.parse_args()

    crs = load_crs()
    stops = load_stops(opts.city)
    stops.to_crs(crs[opts.city], inplace=True)

    landuse_centroid = determine_city_centroid_by_landuse(
        read_boundary(opts.city), crs[opts.city]
    )

    maxc = stops[opts.centrality].max()
    medoid_id = calculate_medoid(stops[stops["Betweenness Centrality"] == maxc])
    medoid = stops[stops["stop_id"] == medoid_id]["geometry"].tolist()[0]
    centroid = stops[stops["Betweenness Centrality"] == maxc].union_all().centroid

    stops["distance_from_largest_betweenness_medoid"] = stops["geometry"].apply(
        lambda x: np.round(x.distance(medoid) / 1000, 3)
    )
    stops["distance_from_largest_betweenness_centroid"] = stops["geometry"].apply(
        lambda x: np.round(x.distance(centroid) / 1000, 3)
    )
    stops["distance_from_landuse_centroid"] = stops["geometry"].apply(
        lambda x: np.round(x.distance(landuse_centroid) / 1000, 3)
    )

    distance = stops[
        [
            "stop_id",
            "distance_from_largest_betweenness_centroid",
            "distance_from_largest_betweenness_medoid",
            "distance_from_landuse_centroid",
        ]
    ].copy()
    distance.dropna(subset=["stop_id"]).to_csv(
        f"../output/{opts.city}/distance.csv", index=False
    )
