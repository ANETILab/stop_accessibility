import json
from typing import Optional

import geopandas as gpd
import networkx as nx
import numpy as np
import pandas as pd
import shapely
from common import load_crs, load_isochrones, load_stops
from shapely import Point, Polygon


def compute_ellipticity(points: np.ndarray) -> float:
    """
    Compute ellipticity of a set of points.

    Parameters:
    - points (numpy array): Array of shape (n, 2) representing (x, y) coordinates of points.

    Returns:
    - ellipticity (float): Ellipticity value.
    """

    # Calculate the covariance matrix of the points
    cov_matrix = np.cov(points, rowvar=False)

    # Calculate eigenvalues and eigenvectors of the covariance matrix
    eigenvalues, eigenvectors = np.linalg.eigh(cov_matrix)

    # Sort eigenvalues in descending order
    sorted_indices = np.argsort(eigenvalues)[::-1]
    eigenvalues = eigenvalues[sorted_indices]
    eigenvectors = eigenvectors[:, sorted_indices]

    # Major and minor axis lengths are square roots of eigenvalues
    major_axis_length = np.sqrt(eigenvalues[0])
    minor_axis_length = np.sqrt(eigenvalues[1])

    # Compute ellipticity
    ellipticity = 1.0 - (minor_axis_length / major_axis_length)

    return ellipticity


def ellipticity(
    points: list[Point], threshold: int = 10, decimals: int = 4
) -> Optional[float]:
    points = [(i.x, i.y) for i in points]
    if len(points) < threshold:
        return None

    return np.round(compute_ellipticity(np.ndarray(points)), decimals)


def determine_stop_geometries(
    stops: gpd.GeoDataFrame,
    subgraphs: dict,
    time_marker: int = 39,
    suffix: str = "",
    concaveness_ratio: float = 0.2,
    include_empty: bool = False,
) -> pd.DataFrame:
    """
    Calculates convex and concave hulls of the accessible network, and also the ellipticity of the stops.

    While the convex hull is unambiguous, multiple concave hulls can be constructed.
    """
    records = []
    for row in stops.itertuples():
        accessible_stop_list = list(
            subgraphs.get(f"{row.stop_id}_network_{time_marker}", nx.Graph())
        )
        accessible_stops = stops[stops["stop_id"].isin(accessible_stop_list)].copy()
        if len(accessible_stops) == 0:
            if include_empty:
                records.append([row.stop_id, Polygon(), 0, Polygon(), 0, 0])
            continue
        points = accessible_stops.union_all()
        cv = shapely.convex_hull(points)
        cc = shapely.concave_hull(points, ratio=concaveness_ratio)
        el = ellipticity(accessible_stops.geometry.tolist())

        records.append(
            [
                row.stop_id,
                cv,
                round(cv.area / 1e6, 3),
                cc,
                round(cc.area / 1e6, 3),
                el,
            ]
        )
    columns = ["stop_id"] + [
        i + suffix
        for i in [
            "convex",
            "convex_area",
            "concave",
            "concave_area",
            "ellipticity",
        ]
    ]

    return pd.DataFrame.from_records(records, columns=columns)


def determine_stop_geometries_from_walk(
    stops: gpd.GeoDataFrame,
    isochrones: gpd.GeoDataFrame,
    accessible_stops,
    crs: int = 23700,
    ellipticity_threshold: int = 2,
) -> gpd.GeoDataFrame:
    records = []
    for row in stops.itertuples():
        if row.stop_id not in accessible_stops:
            continue
        accessible = stops[stops["stop_id"].isin(accessible_stops[row.stop_id])].copy()

        el = ellipticity(accessible.geometry.tolist(), threshold=ellipticity_threshold)
        accessible_area = isochrones[
            (isochrones["stop_id"].isin(accessible_stops[row.stop_id]))
            & (isochrones["costing"] == "walk")
            & (isochrones["range"] == 5)
        ].copy()
        accessible_area_crs = accessible_area.to_crs(crs).union_all()
        records.append(
            [
                row.stop_id,
                accessible_area.union_all(),
                round(accessible_area_crs.area / 1e6, 3),
                el,
                len(accessible),
            ]
        )
    df = pd.DataFrame.from_records(
        records,
        columns=[
            "stop_id",
            "geometry",
            "area",
            "ellipticity",
            "number_of_accessible_stops",
        ],
    )
    return gpd.GeoDataFrame(df, crs=4326)


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
        "--ellipticity-threshold",
        type=int,
        default=5,
        required=False,
        help="number of stops requires to calculate ellipticity",
    )
    argparser.add_argument(
        "--data-version",
        type=str,
        default="",
        help="data version (subfolder in city)",
    )
    opts = argparser.parse_args()

    crs = load_crs()

    with open(
        f"../data/stops/{opts.city}/{opts.data_version}/accessible_stops.json", "r"
    ) as fp:
        accessible_stops = json.load(fp)

    isochrones = load_isochrones(opts.city, opts.data_version)

    stops = load_stops(opts.city, opts.data_version)

    sgfw = determine_stop_geometries_from_walk(
        stops,
        isochrones.query("costing == 'walk' & range == 5"),
        accessible_stops,
        crs=crs[opts.city],
        ellipticity_threshold=opts.ellipticity_threshold,
    )
    path = f"../output/{opts.city}/{opts.data_version}"
    sgfw.to_csv(f"{path}/stop_geometries_from_walk.csv", index=False)
    sgfw.to_file(f"{path}/stop_geometries_from_walk.geojson")
