import json
from pathlib import Path

import geopandas as gpd
import numpy as np
from calculate_accessibility import determine_isochrones, initialize_valhalla
from common import load_crs, load_isochrones, load_stops
from count_amenities_in_accessibility_polygons import (
    count_amenities_in_public_transport_accessibility,
    count_amenities_in_walk_accessibility,
    prepare_amenities,
)
from determine_distance_from_center import (
    calculate_medoid,
    determine_city_centroid_by_landuse,
    read_boundary,
)
from determine_stop_polygons import determine_stop_geometries_from_walk

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
        "--centrality",
        type=str,
        default="Betweenness Centrality",
        required=False,
        help="centrality measure to use, possible values: Eigenvector Centrality, Degree Centrality, Closeness Centrality, Betweenness Centrality",
    )
    opts = argparser.parse_args()
    crs = load_crs()
    stops = load_stops(opts.city)
    actor = initialize_valhalla(opts.city)

    Path(f"../output/{opts.city}").mkdir(parents=True, exist_ok=True)

    isochones = determine_isochrones(stops, actor)
    isochones.to_csv(f"../output/{opts.city}/isochrones.csv", index=False)

    isochrones = gpd.GeoDataFrame(isochones, geometry="geometry", crs=4326)
    isochrones.to_file(f"../output/{opts.city}/isochrones.geojson")

    isochrones["stop_id"] = isochrones["stop_id"].apply(str)

    with open(f"../data/stops/{opts.city}/accessible_stops.json", "r") as fp:
        accessible_stops = json.load(fp)

    sgfw = determine_stop_geometries_from_walk(
        stops,
        isochrones.query("costing == 'walk' & range == 5"),
        accessible_stops,
        crs=crs[opts.city],
        ellipticity_threshold=opts.ellipticity_threshold,
    )
    sgfw.to_csv(f"../output/{opts.city}/stop_geometries_from_walk.csv", index=False)
    sgfw.to_file(f"../output/{opts.city}/stop_geometries_from_walk.geojson")

    isochrones = load_isochrones(opts.city)
    amenities = prepare_amenities(opts.city)

    aciwa = count_amenities_in_walk_accessibility(isochrones, amenities)
    aciwa.to_csv(
        f"../output/{opts.city}/amenity_counts_in_accessibility.csv",
        index=False,
    )

    sgfw["stop_id"] = sgfw["stop_id"].apply(str)

    acipta = count_amenities_in_public_transport_accessibility(sgfw, amenities)
    acipta.to_csv(
        f"../output/{opts.city}/amenity_counts_in_public_transport_accessibility.csv",
        index=False,
    )

    stops_crs = stops.to_crs(crs[opts.city])
    landuse_centroid = determine_city_centroid_by_landuse(
        read_boundary(opts.city), crs[opts.city]
    )
    maxc = stops[opts.centrality].max()
    medoid_id = calculate_medoid(stops_crs[stops_crs["Betweenness Centrality"] == maxc])
    medoid = stops_crs[stops_crs["stop_id"] == medoid_id]["geometry"].tolist()[0]
    centroid = (
        stops_crs[stops_crs["Betweenness Centrality"] == maxc].union_all().centroid
    )

    stops_crs["distance_from_largest_betweenness_medoid"] = stops_crs["geometry"].apply(
        lambda x: np.round(x.distance(medoid) / 1000, 3)
    )
    stops_crs["distance_from_largest_betweenness_centroid"] = stops_crs[
        "geometry"
    ].apply(lambda x: np.round(x.distance(centroid) / 1000, 3))
    stops_crs["distance_from_landuse_centroid"] = stops_crs["geometry"].apply(
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
