import argparse
import json
import pickle

argparser = argparse.ArgumentParser()
argparser.add_argument(
    "--cities",
    nargs="+",
    default=["budapest", "helsinki", "madrid", "paris", "rotterdam"],
    help="city IDs (lowercase name)",
)
opts = argparser.parse_args()

for city in opts.cities:
    with open(f"../data/stops/{city}/10min_walbetclus.pkl", "rb") as fp:
        subgraphs = pickle.load(fp)

    accessible_stops = {k: list(v[1]) for k, v in subgraphs.items()}
    if city == "paris":
        accessible_stops = {
            str(k): [str(int(i)) for i in v] for k, v in accessible_stops.items()
        }
    with open(f"../data/stops/{city}/accessible_stops.json", "w") as fp:
        json.dump(accessible_stops, fp)
