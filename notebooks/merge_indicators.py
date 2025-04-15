import geopandas as gpd
import numpy as np
import pandas as pd
from common import load_stops
from shapely import from_wkt


def determine_walk_area(city: str, version: str) -> pd.DataFrame:
    walk_area = pd.read_csv(
        f"../output/{city}/{version}/isochrones.csv", dtype={"stop_id": str}
    )
    walk_area = walk_area.query("costing == 'walk' & range == 15").copy()
    walk_area["geometry"] = walk_area["geometry"].apply(from_wkt)
    walk_area = gpd.GeoDataFrame(walk_area, geometry="geometry", crs=4326).to_crs(23700)
    walk_area["walk_area"] = np.round(walk_area.area / 1e6, 3)
    return walk_area[["stop_id", "walk_area"]]


def calculate_accessibility_area_difference(
    walk_area: pd.DataFrame, stop_geometries: gpd.GeoDataFrame
) -> pd.DataFrame:
    result = walk_area.merge(stop_geometries[["stop_id", "area"]], on="stop_id")
    result["area_difference"] = result["area"] - result["walk_area"]
    return result.drop(["area"], axis=1)


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
        required=False,
        help="data version (subfolder in city)",
    )
    opts = argparser.parse_args()

    path = f"../output/{opts.city}/{opts.data_version}"

    distance = pd.read_csv(f"{path}/distance.csv", dtype={"stop_id": str})
    distance.drop(["distance_from_largest_betweenness_medoid"], axis=1, inplace=True)
    distance.rename(
        {"distance_from_largest_betweenness_centroid": "distance_betweenness"},
        axis=1,
        inplace=True,
    )

    ac = pd.read_csv(
        f"{path}/amenity_counts_in_accessibility.csv", dtype={"stop_id": str}
    )
    pt_ac = pd.read_csv(
        f"{path}/amenity_counts_in_public_transport_accessibility.csv",
        dtype={"stop_id": str},
    )
    stop_geometries = pd.read_csv(
        f"{path}/stop_geometries_from_walk.csv", dtype={"stop_id": str}
    )

    stop_centralities = load_stops(opts.city, opts.data_version)
    stop_centralities.drop(["Node", "geometry"], axis=1, inplace=True)
    stop_centralities = stop_centralities.rename(
        {
            "Eigenvector Centrality": "eigenvector_centrality",
            "Degree Centrality": "degree_centrality",
            "Closeness Centrality": "closeness_centrality",
            "Betweenness Centrality": "betweenness_centrality",
            "clust": "cluster",
        },
        axis="columns",
    )
    stop_centralities.dropna(subset=["stop_id"], inplace=True)

    wk_amenity = ac.query("costing == 'walk' & range == 15").copy()
    wk_amenity.drop(["costing", "range"], axis=1, inplace=True)
    wk_amenity.columns = ["stop_id"] + [
        f"{i}_walk15" for i in wk_amenity.columns.tolist()[1:]
    ]
    mm_amenity = pt_ac.copy()
    mm_amenity.drop(["costing", "range"], axis=1, inplace=True)
    mm_amenity.columns = ["stop_id"] + [
        f"{i}_multimodal" for i in mm_amenity.columns.tolist()[1:]
    ]

    walk_area = determine_walk_area(opts.city, opts.data_version)
    walk_area = calculate_accessibility_area_difference(walk_area, stop_geometries)

    m = (
        stop_geometries.drop("geometry", axis=1)
        .merge(distance, on="stop_id")
        .merge(mm_amenity, on="stop_id")
        .merge(wk_amenity, on="stop_id")
        .merge(walk_area, on="stop_id")
        .merge(stop_centralities, on="stop_id")
    )
    m.to_csv(f"{path}/merged.csv", index=False)
