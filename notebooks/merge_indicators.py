import argparse

import pandas as pd

argparser = argparse.ArgumentParser()
argparser.add_argument(
    "--city",
    type=str,
    required=True,
    help="city ID (lowercase name)",
)
opts = argparser.parse_args()


distance = pd.read_csv(
    f"../output/{opts.city}/distance.csv",
    dtype={
        "stop_id": str,
    },
)
ac = pd.read_csv(
    f"../output/{opts.city}/amenity_counts_in_accessibility.csv",
    dtype={
        "stop_id": str,
    },
)
pt_ac = pd.read_csv(
    f"../output/{opts.city}/amenity_counts_in_public_transport_accessibility.csv",
    dtype={
        "stop_id": str,
    },
)
stop_geometries = pd.read_csv(
    f"../output/{opts.city}/stop_geometries_from_walk.csv",
    dtype={
        "stop_id": str,
    },
)

stop_centralities = pd.read_csv(
    f"../data/stops/{opts.city}/stops_with_centrality.csv",
    dtype={
        "stop_id": str,
    },
)
stop_centralities.drop(["Node"], axis=1, inplace=True)
# stop_centralities.columns = [
#     "eigenvector_centrality",
#     "degree_centrality",
#     "closeness_centrality",
#     "betweenness_centrality",
#     "stop_id",
#     "cluster",
#     "stop_lat",
#     "stop_lon",
#     "stop_name",
# ]
stop_centralities = stop_centralities.set_axis(
    [
        "eigenvector_centrality",
        "degree_centrality",
        "closeness_centrality",
        "betweenness_centrality",
        "stop_id",
        "cluster",
        "stop_lat",
        "stop_lon",
        "stop_name",
    ],
    axis="columns",
)
stop_centralities.dropna(subset=["stop_id"], inplace=True)


wk_amenity = ac.query("costing == 'walk' & range == 15").copy()
wk_amenity.drop(["costing", "range"], axis=1, inplace=True)
wk_amenity.columns = ["stop_id"] + [f"{i}_walk15" for i in wk_amenity.columns[1:]]
mm_amenity = pt_ac.copy()
mm_amenity.drop(["costing", "range"], axis=1, inplace=True)
mm_amenity.columns = ["stop_id"] + [f"{i}_multimodal" for i in mm_amenity.columns[1:]]


m = (
    stop_geometries.drop("geometry", axis=1)
    .merge(distance, on="stop_id")
    .merge(mm_amenity, on="stop_id")
    .merge(wk_amenity, on="stop_id")
    .merge(stop_centralities, on="stop_id")
)
m.to_csv(f"../output/{opts.city}/merged.csv", index=False)
