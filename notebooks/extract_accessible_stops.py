import argparse
import json
import pickle

argparser = argparse.ArgumentParser()
argparser.add_argument(
    "--city",
    type=str,
    required=True,
    help="city IDs (lowercase name)",
)
argparser.add_argument(
    "--data-version",
    type=str,
    default="",
    required=False,
    help="data version (subfolder in city)",
)
opts = argparser.parse_args()

with open(
    f"../data/stops/{opts.city}/{opts.data_version}/10min_walbetclus.pkl", "rb"
) as fp:
    subgraphs = pickle.load(fp)

accessible_stops = {k: list(v[1]) for k, v in subgraphs.items()}
if opts.city == "paris":
    accessible_stops = {
        str(k): [str(int(i)) for i in v] for k, v in accessible_stops.items()
    }
with open(
    f"../data/stops/{opts.city}/{opts.data_version}/accessible_stops.json", "w"
) as fp:
    json.dump(accessible_stops, fp)
